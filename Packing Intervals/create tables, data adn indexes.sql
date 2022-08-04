DROP TABLE IF EXISTS dbo.Sessions, dbo.Users;
GO
CREATE TABLE dbo.Users
(
  username  VARCHAR(14)  NOT NULL,
  CONSTRAINT PK_Users PRIMARY KEY(username)
);

INSERT INTO dbo.Users(username) VALUES('User1'), ('User2'), ('User3');

CREATE TABLE dbo.Sessions
(
  id        INT          NOT NULL IDENTITY(1, 1),
  username  VARCHAR(14)  NOT NULL,
  starttime DATETIME2(3) NOT NULL,
  endtime   DATETIME2(3) NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(id),
  CONSTRAINT CHK_endtime_gteq_starttime
    CHECK (endtime >= starttime)
);

INSERT INTO dbo.Sessions(username, starttime, endtime) VALUES
  ('User1', '20191201 08:00:00.000', '20191201 08:30:00.000'),
  ('User1', '20191201 08:30:00.000', '20191201 09:00:00.000'),
  ('User1', '20191201 09:00:00.000', '20191201 09:30:00.000'),
  ('User1', '20191201 10:00:00.000', '20191201 11:00:00.000'),
  ('User1', '20191201 10:30:00.000', '20191201 12:00:00.000'),
  ('User1', '20191201 11:30:00.000', '20191201 12:30:00.000'),
  ('User2', '20191201 08:00:00.000', '20191201 10:30:00.000'),
  ('User2', '20191201 08:30:00.000', '20191201 10:00:00.000'),
  ('User2', '20191201 09:00:00.000', '20191201 09:30:00.000'),
  ('User2', '20191201 11:00:00.000', '20191201 11:30:00.000'),
  ('User2', '20191201 11:32:00.000', '20191201 12:00:00.000'),
  ('User2', '20191201 12:04:00.000', '20191201 12:30:00.000'),
  ('User3', '20191201 08:00:00.000', '20191201 09:00:00.000'),
  ('User3', '20191201 08:00:00.000', '20191201 08:30:00.000'),
  ('User3', '20191201 08:30:00.000', '20191201 09:00:00.000'),
  ('User3', '20191201 09:30:00.000', '20191201 09:30:00.000');
GO

-- desired results
/*
username  starttime               endtime
--------- ----------------------- -----------------------
User1     2019-12-01 08:00:00.000 2019-12-01 09:30:00.000
User1     2019-12-01 10:00:00.000 2019-12-01 12:30:00.000
User2     2019-12-01 08:00:00.000 2019-12-01 10:30:00.000
User2     2019-12-01 11:00:00.000 2019-12-01 11:30:00.000
User2     2019-12-01 11:32:00.000 2019-12-01 12:00:00.000
User2     2019-12-01 12:04:00.000 2019-12-01 12:30:00.000
User3     2019-12-01 08:00:00.000 2019-12-01 09:00:00.000
User3     2019-12-01 09:30:00.000 2019-12-01 09:30:00.000
*/

-- Listing 6-11: Code to Populate Sessions with a Large Set of Sample Data
-- 2,000 users, 5,000,000 intervals
DECLARE 
  @num_users          AS INT          = 500,
  @intervals_per_user AS INT          = 2000,
  @start_period       AS DATETIME2(3) = '20190101',
  @end_period         AS DATETIME2(3) = '20190107',
  @max_duration_in_ms AS INT  = 3600000; -- 60 minutes
  
TRUNCATE TABLE dbo.Sessions;
TRUNCATE TABLE dbo.Users;

INSERT INTO dbo.Users(username)
  SELECT 'User' + RIGHT('000000000' + CAST(U.n AS VARCHAR(10)), 10) AS username
  FROM dbo.GetNums(1, @num_users) AS U;

WITH C AS
(
  SELECT 'User' + RIGHT('000000000' + CAST(U.n AS VARCHAR(10)), 10) AS username,
      DATEADD(ms, ABS(CHECKSUM(NEWID())) % 86400000,
        DATEADD(day, ABS(CHECKSUM(NEWID())) % DATEDIFF(day, @start_period, 
          @end_period), @start_period)) AS starttime
  FROM dbo.GetNums(1, @num_users) AS U
    CROSS JOIN dbo.GetNums(1, @intervals_per_user) AS I
)
INSERT INTO dbo.Sessions WITH (TABLOCK) (username, starttime, endtime)
  SELECT username, starttime,
    DATEADD(ms, ABS(CHECKSUM(NEWID())) % (@max_duration_in_ms + 1), starttime)
      AS endtime
  FROM C;
GO

-- indexes for traditional solution
CREATE INDEX idx_user_start_end ON dbo.Sessions(username, starttime, endtime);
CREATE INDEX idx_user_end_start ON dbo.Sessions(username, endtime, starttime);

go

-- cleanup indexes for traditional solution
DROP INDEX IF EXISTS idx_user_start_end ON dbo.Sessions;
DROP INDEX IF EXISTS idx_user_end_start ON dbo.Sessions;
go

-- fake filtered columnstore index to support Solution 1 and Solution 2 based on window functions
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.Sessions(id)
  WHERE id = -1 AND id = -2;
go

drop index if exists idx_cs ON dbo.Sessions
go

-- indexes for Solution 1 based on window functions
CREATE UNIQUE INDEX idx_user_start_id ON dbo.Sessions(username, starttime, id);
CREATE UNIQUE INDEX idx_user_end_id ON dbo.Sessions(username, endtime, id);
go

-- cleanup indexes
DROP INDEX IF EXISTS idx_user_start_id ON dbo.Sessions;
DROP INDEX IF EXISTS idx_user_end_id ON dbo.Sessions;
go

-- index for Solution 2 based on window functions
CREATE UNIQUE INDEX idx_user_start__end_id
  ON dbo.Sessions(username, starttime, endtime, id);
  go

drop index if exists idx_user_start__end_id ON dbo.Sessions
go