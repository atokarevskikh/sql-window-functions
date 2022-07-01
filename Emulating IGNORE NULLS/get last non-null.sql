TRUNCATE TABLE dbo.T1;

INSERT INTO dbo.T1 WITH(TABLOCK)
  SELECT n AS id, CHECKSUM(NEWID()) AS col1
  FROM dbo.GetNums(1, 10000000) AS Nums
OPTION(MAXDOP 1);

-- Solution 1, row mode
WITH C AS
(
  SELECT id, col1,
    MAX(CASE WHEN col1 IS NOT NULL THEN id END)
      OVER(ORDER BY id
           ROWS UNBOUNDED PRECEDING) AS grp
  FROM dbo.T1
)
SELECT id, col1,
  MAX(col1) OVER(PARTITION BY grp
                 ORDER BY id
                 ROWS UNBOUNDED PRECEDING) AS lastval
FROM C
OPTION(USE HINT('DISALLOW_BATCH_MODE'));

-- Solution 1, batch mode
WITH C AS
(
  SELECT id, col1,
    MAX(CASE WHEN col1 IS NOT NULL THEN id END)
      OVER(ORDER BY id
           ROWS UNBOUNDED PRECEDING) AS grp
  FROM dbo.T1
)
SELECT id, col1,
  MAX(col1) OVER(PARTITION BY grp
                 ORDER BY id
                 ROWS UNBOUNDED PRECEDING) AS lastval
FROM C;