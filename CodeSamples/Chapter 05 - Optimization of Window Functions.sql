----------------------------------------------------------------------
-- T-SQL Window Functions Second Edition
-- Chapter 05 - Optimization of Window Functions
-- © Itzik Ben-Gan
----------------------------------------------------------------------

-- set compatibility to 140 (SQL Server 2017)
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

-- Listing 5-1: Code to Create the Accounts and Transactions Tables
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Transactions;
DROP TABLE IF EXISTS dbo.Accounts;

CREATE TABLE dbo.Accounts
(
  actid   INT         NOT NULL,
  actname VARCHAR(50) NOT NULL,
  CONSTRAINT PK_Accounts PRIMARY KEY(actid)
);

CREATE TABLE dbo.Transactions
(
  actid  INT   NOT NULL,
  tranid INT   NOT NULL,
  val    MONEY NOT NULL,
  CONSTRAINT PK_Transactions PRIMARY KEY(actid, tranid),
  CONSTRAINT FK_Transactions_Accounts
    FOREIGN KEY(actid)
    REFERENCES dbo.Accounts(actid)
);
GO

-- Listing 5-2: Small Set of Sample Data
INSERT INTO dbo.Accounts(actid, actname) VALUES
  (1,  'account 1'),
  (2,  'account 2'),
  (3,  'account 3');

INSERT INTO dbo.Transactions(actid, tranid, val) VALUES
  (1,  1,  4.00),
  (1,  2, -2.00),
  (1,  3,  5.00),
  (1,  4,  2.00),
  (1,  5,  1.00),
  (1,  6,  3.00),
  (1,  7, -4.00),
  (1,  8, -1.00),
  (1,  9, -2.00),
  (1, 10, -3.00),
  (2,  1,  2.00),
  (2,  2,  1.00),
  (2,  3,  5.00),
  (2,  4,  1.00),
  (2,  5, -5.00),
  (2,  6,  4.00),
  (2,  7,  2.00),
  (2,  8, -4.00),
  (2,  9, -5.00),
  (2, 10,  4.00),
  (3,  1, -3.00),
  (3,  2,  3.00),
  (3,  3, -2.00),
  (3,  4,  1.00),
  (3,  5,  4.00),
  (3,  6, -1.00),
  (3,  7,  5.00),
  (3,  8,  3.00),
  (3,  9,  5.00),
  (3, 10, -3.00);
GO

-- definition of GetNums helper function
DROP FUNCTION IF EXISTS dbo.GetNums;
GO
CREATE OR ALTER FUNCTION dbo.GetNums(@low AS BIGINT, @high AS BIGINT) RETURNS TABLE
AS
RETURN
  WITH
    L0   AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
             FROM L5)
  SELECT TOP (@high - @low + 1) @low + rownum - 1 AS n
  FROM Nums
  ORDER BY rownum;
GO

-- large set of sample data (change inputs as needed)
DECLARE
  @num_partitions     AS INT = 100,
  @rows_per_partition AS INT = 20000;

TRUNCATE TABLE dbo.Transactions;
DELETE FROM dbo.Accounts;

INSERT INTO dbo.Accounts WITH (TABLOCK) (actid, actname)
  SELECT n AS actid, 'account ' + CAST(n AS VARCHAR(10)) AS actname
  FROM dbo.GetNums(1, @num_partitions) AS P;

INSERT INTO dbo.Transactions WITH (TABLOCK) (actid, tranid, val)
  SELECT NP.n, RPP.n,
    (ABS(CHECKSUM(NEWID())%2)*2-1) * (1 + ABS(CHECKSUM(NEWID())%5))
  FROM dbo.GetNums(1, @num_partitions) AS NP
    CROSS JOIN dbo.GetNums(1, @rows_per_partition) AS RPP;
GO

----------------------------------------------------------------------
-- Indexing Guidelines
----------------------------------------------------------------------

----------------------------------------------------------------------
-- POC Index
----------------------------------------------------------------------

-- make sure index does not exist
DROP INDEX IF EXISTS idx_actid_val_i_tranid ON dbo.Transactions;

-- without POC index plan requires a Sort operator
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- create POC index
CREATE INDEX idx_actid_val_i_tranid
  ON dbo.Transactions(actid, val)
  INCLUDE(tranid);

-- with POC index plan doesn't require Sort operator
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

----------------------------------------------------------------------
-- Merge Join (Concatenation)
----------------------------------------------------------------------

-- create and populate Credits and Debits tables
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Credits;
DROP TABLE IF EXISTS dbo.Debits;

SELECT *
INTO dbo.Credits
FROM dbo.Transactions
WHERE val > 0;

ALTER TABLE dbo.Credits
  ADD CONSTRAINT PK_Credits
    PRIMARY KEY(actid, tranid);

SELECT *
INTO dbo.Debits
FROM dbo.Transactions
WHERE val < 0;

ALTER TABLE dbo.Debits
  ADD CONSTRAINT PK_Debits
    PRIMARY KEY(actid, tranid);

-- create POC indexes
CREATE INDEX idx_actid_val_i_tranid
  ON dbo.Credits(actid, val)
  INCLUDE(tranid);

CREATE INDEX idx_actid_val_i_tranid
  ON dbo.Debits(actid, val)
  INCLUDE(tranid);

-- query the unified credits and debits
WITH C AS
(
  SELECT actid, tranid, val FROM dbo.Debits
  UNION ALL
  SELECT actid, tranid, val FROM dbo.Credits
)
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM C;

----------------------------------------------------------------------
-- Backward Scans
----------------------------------------------------------------------

-- no window partition clause

-- forward scan of index can benefit from parallelism
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(ORDER BY actid, val) AS rownum
FROM dbo.Transactions
WHERE tranid < 1000;

-- bacward scan of index can be used, bat cannot benefit from parallelism
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(ORDER BY actid DESC, val DESC) AS rownum
FROM dbo.Transactions
WHERE tranid < 1000;

-- with partitioning, ascending order, ordered forward scan of index
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- with partitioning, descending order, sort takes place
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownum
FROM dbo.Transactions;

-- adding presentation ORDER BY removes the sort
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownum
FROM dbo.Transactions
ORDER BY actid DESC;

-- STRING_AGG, Query 1
SELECT actid, 
  STRING_AGG(CAST(val AS VARCHAR(MAX)), ',')
    WITHIN GROUP(ORDER BY tranid) AS amounts
FROM dbo.Transactions
GROUP BY actid;

-- STRING_AGG, Query 2
SELECT actid, 
  STRING_AGG(CAST(val AS VARCHAR(MAX)), ',')
    WITHIN GROUP(ORDER BY tranid DESC) AS amounts
FROM dbo.Transactions
GROUP BY actid;

-- STRING_AGG, Query 3
SELECT actid, 
  STRING_AGG(CAST(val AS VARCHAR(MAX)), ',')
    WITHIN GROUP(ORDER BY tranid DESC) AS amounts
FROM dbo.Transactions
GROUP BY actid
ORDER BY actid DESC;

----------------------------------------------------------------------
-- Emulating NULLS LAST Efficiently
----------------------------------------------------------------------

-- Figure 5-9, default NULLS FIRST, no sorting
SELECT orderid, shippeddate,
  ROW_NUMBER() OVER(ORDER BY shippeddate) AS rownum
FROM Sales.Orders;

-- Listing 5-3: Query Output Showing NULLs First
/*
orderid     shippeddate rownum
----------- ----------- -------
11008       NULL        1
11019       NULL        2
11039       NULL        3
11040       NULL        4
11045       NULL        5
...
11073       NULL        17
11074       NULL        18
11075       NULL        19
11076       NULL        20
11077       NULL        21
10249       2017-07-10  22
10252       2017-07-11  23
10250       2017-07-12  24
10251       2017-07-15  25
10255       2017-07-15  26
...
11050       2019-05-05  826
11055       2019-05-05  827
11063       2019-05-06  828
11067       2019-05-06  829
11069       2019-05-06  830

(830 rows affected)
*/

/*
-- standard query
SELECT orderid, shippeddate,
  ROW_NUMBER() OVER(ORDER BY shippeddate NULLS LAST) AS rownum
FROM Sales.Orders;
*/

-- Figure 5-10, emulating NULLS LAST, sorting required
SELECT orderid, shippeddate,
  ROW_NUMBER() OVER(ORDER BY CASE
                               WHEN shippeddate IS NOT NULL THEN 1
                               ELSE 2
                             END, shippeddate) AS rownum
FROM Sales.Orders;

-- Listing 5-4: Query Output Showing NULLs Last
/*
orderid     shippeddate rownum
----------- ----------- -------
10249       2017-07-10  1
10252       2017-07-11  2
10250       2017-07-12  3
10251       2017-07-15  4
10255       2017-07-15  5
...
11050       2019-05-05  805
11055       2019-05-05  806
11063       2019-05-06  807
11067       2019-05-06  808
11069       2019-05-06  809
11008       NULL        810
11019       NULL        811
11039       NULL        812
11040       NULL        813
11045       NULL        814
...
11073       NULL        826
11074       NULL        827
11075       NULL        828
11076       NULL        829
11077       NULL        830

(830 rows affected)
*/

-- Figure 5-11, efficient solution
WITH C AS
(
  SELECT orderid, shippeddate, 1 AS sortcol
  FROM Sales.Orders
  WHERE shippeddate IS NOT NULL
  
  UNION ALL
  
  SELECT orderid, shippeddate, 2 AS sortcol
  FROM Sales.Orders
  WHERE shippeddate IS NULL
)
SELECT orderid, shippeddate,
  ROW_NUMBER() OVER(ORDER BY sortcol, shippeddate) AS rownum
FROM C;

/*
orderid     shippeddate rownum
----------- ----------- -------
10249       2017-07-10  1
10252       2017-07-11  2
10250       2017-07-12  3
10251       2017-07-15  4
10255       2017-07-15  5
...
11050       2019-05-05  805
11055       2019-05-05  806
11063       2019-05-06  807
11067       2019-05-06  808
11069       2019-05-06  809
11008       NULL        810
11019       NULL        811
11039       NULL        812
11040       NULL        813
11045       NULL        814
...
11073       NULL        826
11074       NULL        827
11075       NULL        828
11076       NULL        829
11077       NULL        830

(830 rows affected)
*/

----------------------------------------------------------------------
-- Improved Parallelism with APPLY
----------------------------------------------------------------------

-- without APPLY
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownumasc,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownumdesc
FROM dbo.Transactions;

-- Listing 5-5: Parallel APPLY Technique
-- with APPLY (need at least 8 CPUs) 
SELECT C.actid, A.tranid, A.val, A.rownumasc, A.rownumdesc
FROM dbo.Accounts AS C
  CROSS APPLY (SELECT tranid, val,
                 ROW_NUMBER() OVER(ORDER BY val) AS rownumasc,
                 ROW_NUMBER() OVER(ORDER BY val DESC) AS rownumdesc
               FROM dbo.Transactions AS T
               WHERE T.actid = C.actid) AS A;

-- cleanup
DROP INDEX IF EXISTS idx_actid_val_i_tranid ON dbo.Transactions;

----------------------------------------------------------------------
-- Batch-Mode Processing
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Batch-Mode on Columnstore
----------------------------------------------------------------------

ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

-- row mode, with sort
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- create POC index
CREATE INDEX idx_actid_val_i_tranid
  ON dbo.Transactions(actid, val)
  INCLUDE(tranid);

-- row mode, without sort
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- drop rowstore index
DROP INDEX IF EXISTS idx_actid_val_i_tranid ON dbo.Transactions;

-- create columnstore index
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs
 ON dbo.Transactions(actid, tranid, val);

-- batch mode, with sort
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- drop columnstore index
DROP INDEX IF EXISTS idx_cs ON dbo.Transactions;

-- create rowstore index
CREATE INDEX idx_actid_val_i_tranid
  ON dbo.Transactions(actid, val)
  INCLUDE(tranid);

-- create fake columnstore index
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.Transactions(actid)
  WHERE actid = -1 AND actid = -2;

-- uses row mode
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- drop fake columnstore index
DROP INDEX IF EXISTS idx_cs ON dbo.Transactions;

-- row mode, without sort
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid) AS balance
FROM dbo.Transactions;

-- create fake columnstore index
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.Transactions(actid)
  WHERE actid = -1 AND actid = -2;

-- batch mode, without sort
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid) AS balance
FROM dbo.Transactions;

-- drop fake columnstore index
DROP INDEX IF EXISTS idx_cs ON dbo.Transactions;

-- another backdoor to enable batch-processing
CREATE TABLE dbo.FakeCS
(
  col1 INT NOT NULL,
  index idx_cs CLUSTERED COLUMNSTORE
);

SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid) AS balance
FROM dbo.Transactions
  LEFT OUTER JOIN dbo.FakeCS
    ON 1 = 2;

-- cleanup
DROP TABLE IF EXISTS dbo.FakeCS;

----------------------------------------------------------------------
-- Batch-Mode on Rowstore
----------------------------------------------------------------------

-- enable 2019 compatibility mode
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 150;

-- batch mode on rowstore, without sort
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- batch mode on rowstore, without sort
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid) AS balance
FROM dbo.Transactions;

-- switch back to compatibility level 140
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

----------------------------------------------------------------------
-- Ranking Functions
----------------------------------------------------------------------

-- set compatibility to 140 to disable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

-- ROW_NUMBER
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- arbitrary ordering
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
FROM dbo.Transactions;

-- NTILE
SELECT actid, tranid, val,
  NTILE(100) OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- RANK
SELECT actid, tranid, val,
  RANK() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- DENSE_RANK
SELECT actid, tranid, val,
  DENSE_RANK() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

----------------------------------------------------------------------
-- Batch-Mode Processing
----------------------------------------------------------------------

-- set compatibility to 150 or above to enable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 150;

-- ROW_NUMBER
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- NTILE
SELECT actid, tranid, val,
  NTILE(100) OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- RANK
SELECT actid, tranid, val,
  RANK() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

-- DENSE_RANK
SELECT actid, tranid, val,
  DENSE_RANK() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;

----------------------------------------------------------------------
-- Aggregate and Offset Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Without Ordering and Framing
----------------------------------------------------------------------

-- set compatibility to 140 to disable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

-- window aggregate with just partitioning
SELECT actid, tranid, val,
  MAX(val) OVER(PARTITION BY actid) AS mx
FROM dbo.Transactions;

-- window aggregate with partitioning, plus filter
WITH C AS
(
  SELECT actid, tranid, val,
    MAX(val) OVER(PARTITION BY actid) AS mx
  FROM dbo.Transactions
)
SELECT actid, tranid, val
FROM C
WHERE val = mx;

-- alternative with grouped aggregate
WITH Aggs AS
(
  SELECT actid, MAX(val) AS mx
  FROM dbo.Transactions
  GROUP BY actid
)
SELECT T.actid, T.tranid, T.val, A.mx
FROM dbo.Transactions AS T
  INNER JOIN Aggs AS A
    ON T.actid = A.actid;

-- alternative with grouped aggregate, plus filter
WITH Aggs AS
(
  SELECT actid, MAX(val) AS mx
  FROM dbo.Transactions
  GROUP BY actid
)
SELECT T.actid, T.tranid, T.val
FROM dbo.Transactions AS T
  INNER JOIN Aggs AS A
    ON T.actid = A.actid
   AND T.val = A.mx;

----------------------------------------------------------------------
-- Batch-Mode Processing
----------------------------------------------------------------------

-- set compatibility to 150 or above to enable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 150;

-- window aggregate with just partitioning
SELECT actid, tranid, val,
  MAX(val) OVER(PARTITION BY actid) AS mx
FROM dbo.Transactions;

-- window aggregate with partitioning, plus filter
WITH C AS
(
  SELECT actid, tranid, val,
    MAX(val) OVER(PARTITION BY actid) AS mx
  FROM dbo.Transactions
)
SELECT actid, tranid, val
FROM C
WHERE val = mx;

-- force serial plan
WITH C AS
(
  SELECT actid, tranid, val,
    MAX(val) OVER(PARTITION BY actid) AS mx
  FROM dbo.Transactions
)
SELECT actid, tranid, val
FROM C
WHERE val = mx
OPTION(MAXDOP 1);

----------------------------------------------------------------------
-- With Ordering and Framing
----------------------------------------------------------------------

-- set compatibility to 140 to disable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

----------------------------------------------------------------------
-- UNBOUNDED PRECEDING AND CURRENT ROW
----------------------------------------------------------------------

-- ROWS
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS balance
FROM dbo.Transactions;

-- RANGE
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS balance
FROM dbo.Transactions;

-- implied RANGE
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid) AS balance
FROM dbo.Transactions;

-- with APPLY
SELECT C.actid, A.tranid, A.val, A.balance
FROM dbo.Accounts AS C
  CROSS APPLY (SELECT tranid, val,
                 SUM(val) OVER(ORDER BY tranid
                               RANGE BETWEEN UNBOUNDED PRECEDING
                                         AND CURRENT ROW) AS balance
               FROM dbo.Transactions AS T
               WHERE T.actid = C.actid) AS A;

----------------------------------------------------------------------
-- Expanding All Frame Rows
----------------------------------------------------------------------

-- subtractable aggregates
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN 5 PRECEDING
                         AND 2 PRECEDING) AS sumval
FROM dbo.Transactions;

-- nonsubtractable aggregates
SELECT actid, tranid, val,
  MAX(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN 100 PRECEDING
                          AND  2 PRECEDING) AS maxval
FROM dbo.Transactions;

-- with APPLY
SELECT C.actid, A.tranid, A.val, A.maxval
FROM dbo.Accounts AS C
  CROSS APPLY (SELECT tranid, val,
                 MAX(val) OVER(ORDER BY tranid
                               ROWS BETWEEN 100 PRECEDING
                                        AND  2 PRECEDING) AS maxval
               FROM dbo.Transactions AS T
               WHERE T.actid = C.actid) AS A;

-- test for in-memory vs. on-disk worktable
SET STATISTICS IO ON;

SELECT actid, tranid, val,
  MAX(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN 9999 PRECEDING
                         AND 9999 PRECEDING) AS maxval
FROM dbo.Transactions;

SELECT actid, tranid, val,
  MAX(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN 10000 PRECEDING
                         AND 10000 PRECEDING) AS maxval
FROM dbo.Transactions;

SET STATISTICS IO OFF;

-- xevent
CREATE EVENT SESSION xe_window_spool ON SERVER
ADD EVENT sqlserver.window_spool_ondisk_warning
  ( ACTION (sqlserver.plan_handle, sqlserver.sql_text) )
/* ADD TARGET package0.asynchronous_file_target
  ( SET FILENAME  = N'c:\temp\xe_xe_window_spool.xel', 
    metadatafile  = N'c:\temp\xe_xe_window_spool.xem' ) */;

ALTER EVENT SESSION xe_window_spool ON SERVER STATE = START;

-- cleanup
DROP EVENT SESSION xe_window_spool ON SERVER;

----------------------------------------------------------------------
-- Computing Two Cumulative Values
----------------------------------------------------------------------

-- subtractable aggregates, more than 4 rows in frame
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN 100 PRECEDING
                         AND   2 PRECEDING) AS sumval
FROM dbo.Transactions;

-- with APPLY
SELECT C.actid, A.tranid, A.val, A.sumval
FROM dbo.Accounts AS C
  CROSS APPLY (SELECT tranid, val,
                 SUM(val) OVER(ORDER BY tranid
                               ROWS BETWEEN 100 PRECEDING
                                         AND  2 PRECEDING) AS sumval
               FROM dbo.Transactions AS T
               WHERE T.actid = C.actid) AS A;

----------------------------------------------------------------------
-- Batch-Mode Processing
----------------------------------------------------------------------

-- set compatibility to 150 or above to enable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 150;

-- ROWS, batch mode
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS balance
FROM dbo.Transactions;

-- RANGE, batch mode
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS balance
FROM dbo.Transactions;

-- implied RANGE
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid) AS balance
FROM dbo.Transactions;

-- nonclassic frame, row mode
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND 1 PRECEDING) AS prevbalance
FROM dbo.Transactions;

-- LAG with offset 1, batch mode
SELECT actid, tranid, val,
  LAG(val) OVER(PARTITION BY actid
                ORDER BY tranid) AS prevval
FROM dbo.Transactions;

-- LAG with nondefault offset, row mode
SELECT actid, tranid, val,
  LAG(val, 3) OVER(PARTITION BY actid
                   ORDER BY tranid) AS prevval
FROM dbo.Transactions;

----------------------------------------------------------------------
-- Distribution Functions
----------------------------------------------------------------------

-- set compatibility to 140 to disable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 140;

----------------------------------------------------------------------
-- PERCENT_RANK, CUME_DIST
----------------------------------------------------------------------

-- PERCENT_RANK and CUME_DIST
SELECT testid, studentid, score,
  PERCENT_RANK() OVER(PARTITION BY testid ORDER BY score) AS percentrank
FROM Stats.Scores;

SELECT tranid, actid, val,
  PERCENT_RANK() OVER(PARTITION BY actid ORDER BY val) AS percentrank
FROM dbo.Transactions;

SELECT testid, studentid, score,
  CUME_DIST()    OVER(PARTITION BY testid ORDER BY score) AS cumedist
FROM Stats.Scores;

SELECT tranid, actid, val,
  CUME_DIST() OVER(PARTITION BY actid ORDER BY val) AS cumedist
FROM dbo.Transactions;

----------------------------------------------------------------------
-- PERCENTILE_CONT, PERCENTILE_DISC
----------------------------------------------------------------------

-- PERCENTILE_CONT, PERCENTILE_DISC
SELECT testid, score,
  PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentiledisc
FROM Stats.Scores;

SELECT tranid, actid, val,
  PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY val)
    OVER(PARTITION BY actid) AS percentiledisc
FROM dbo.Transactions;

SELECT testid, score,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentilecont
FROM Stats.Scores;

SELECT tranid, actid, val,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY val)
    OVER(PARTITION BY actid) AS percentilecont
FROM dbo.Transactions;

----------------------------------------------------------------------
-- Batch-Mode Processing
----------------------------------------------------------------------

-- set compatibility to 150 or above to enable batch mode on rowstore
ALTER DATABASE TSQLV5 SET COMPATIBILITY_LEVEL = 150;

-- PERCENT_RANK
SELECT tranid, actid, val,
  PERCENT_RANK() OVER(PARTITION BY actid ORDER BY val) AS percentrank
FROM dbo.Transactions;

-- CUME_DIST
SELECT tranid, actid, val,
  CUME_DIST() OVER(PARTITION BY actid ORDER BY val) AS cumedisc
FROM dbo.Transactions;

-- PERCENTILE_DISC
SELECT tranid, actid, val,
  PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY val)
    OVER(PARTITION BY actid) AS percentiledisc
FROM dbo.Transactions;

-- PERCENTILE_CONT
SELECT tranid, actid, val,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY val)
    OVER(PARTITION BY actid) AS percentilecont
FROM dbo.Transactions;
