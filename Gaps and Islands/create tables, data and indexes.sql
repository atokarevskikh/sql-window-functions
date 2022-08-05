DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
  col1 INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY
);
GO

INSERT INTO dbo.T1(col1)
  VALUES(2),(3),(7),(8),(9),(11),(15),(16),(17),(28);

-- dbo.T2 (temporal sequence with unique values, interval: 1 day)
DROP TABLE IF EXISTS dbo.T2;

CREATE TABLE dbo.T2
(
  col1 DATE NOT NULL
    CONSTRAINT PK_T2 PRIMARY KEY
);
GO

INSERT INTO dbo.T2(col1) VALUES
  ('20190202'),
  ('20190203'),
  ('20190207'),
  ('20190208'),
  ('20190209'),
  ('20190211'),
  ('20190215'),
  ('20190216'),
  ('20190217'),
  ('20190228');

-- fake filtered columnsotre indexes to enable batch processing
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.T1(col1)
  WHERE col1 = -1 AND col1 = -2;

CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.T2(col1)
  WHERE col1 = '00010101' AND col1 = '00010102';
go