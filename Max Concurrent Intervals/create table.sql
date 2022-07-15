DROP TABLE IF EXISTS dbo.Sessions;

CREATE TABLE dbo.Sessions
(
  keycol    INT          NOT NULL,
  app       VARCHAR(10)  NOT NULL,
  usr       VARCHAR(10)  NOT NULL,
  host      VARCHAR(10)  NOT NULL,
  starttime DATETIME2(0) NOT NULL,
  endtime   DATETIME2(0) NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(keycol),
  CHECK(endtime > starttime)
);
GO

-- small set of sample data
TRUNCATE TABLE dbo.Sessions;

INSERT INTO dbo.Sessions(keycol, app, usr, host, starttime, endtime) VALUES
  (2,  'app1', 'user1', 'host1', '20190212 08:30', '20190212 10:30'),
  (3,  'app1', 'user2', 'host1', '20190212 08:30', '20190212 08:45'),
  (5,  'app1', 'user3', 'host2', '20190212 09:00', '20190212 09:30'),
  (7,  'app1', 'user4', 'host2', '20190212 09:15', '20190212 10:30'),
  (11, 'app1', 'user5', 'host3', '20190212 09:15', '20190212 09:30'),
  (13, 'app1', 'user6', 'host3', '20190212 10:30', '20190212 14:30'),
  (17, 'app1', 'user7', 'host4', '20190212 10:45', '20190212 11:30'),
  (19, 'app1', 'user8', 'host4', '20190212 11:00', '20190212 12:30'),
  (23, 'app2', 'user8', 'host1', '20190212 08:30', '20190212 08:45'),
  (29, 'app2', 'user7', 'host1', '20190212 09:00', '20190212 09:30'),
  (31, 'app2', 'user6', 'host2', '20190212 11:45', '20190212 12:00'),
  (37, 'app2', 'user5', 'host2', '20190212 12:30', '20190212 14:00'),
  (41, 'app2', 'user4', 'host3', '20190212 12:45', '20190212 13:30'),
  (43, 'app2', 'user3', 'host3', '20190212 13:00', '20190212 14:00'),
  (47, 'app2', 'user2', 'host4', '20190212 14:00', '20190212 16:30'),
  (53, 'app2', 'user1', 'host4', '20190212 15:30', '20190212 17:00');
GO

TRUNCATE TABLE dbo.Sessions;

DECLARE 
  @numrows AS INT = 1000000, -- total number of rows 
  @numapps AS INT = 10;      -- number of applications

INSERT INTO dbo.Sessions WITH(TABLOCK)
    (keycol, app, usr, host, starttime, endtime)
  SELECT
    ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS keycol, 
    D.*,
    DATEADD(
      second,
      1 + ABS(CHECKSUM(NEWID())) % (20*60),
      starttime) AS endtime
  FROM
  (
    SELECT 
      'app' + CAST(1 + ABS(CHECKSUM(NEWID())) % @numapps AS VARCHAR(10)) AS app,
      'user1' AS usr,
      'host1' AS host,
      DATEADD(
        second,
        1 + ABS(CHECKSUM(NEWID())) % (30*24*60*60),
        '20190101') AS starttime
    FROM dbo.GetNums(1, @numrows) AS Nums
  ) AS D;
GO

CREATE INDEX idx_start_end ON dbo.Sessions(app, starttime, endtime);
go

DROP INDEX IF EXISTS idx_start_end ON dbo.Sessions;
go

CREATE UNIQUE INDEX idx_start ON dbo.Sessions(app, starttime, keycol);
CREATE UNIQUE INDEX idx_end ON dbo.Sessions(app, endtime, keycol);
go