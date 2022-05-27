----------------------------------------------------------------------
-- T-SQL Window Functions Second Edition
-- Chapter 06 - T-SQL Solutions using Window Functions
-- © Itzik Ben-Gan
----------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQLV5;

----------------------------------------------------------------------
-- Virtual Auxiliary Table of Numbers
----------------------------------------------------------------------

-- two rows
SELECT c FROM (VALUES(1),(1)) AS D(c);

/*
c
-----------
1
1
*/

-- four rows
WITH
  L0   AS (SELECT c FROM (VALUES(1),(1)) AS D(c))
SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B;

/*
c
-----------
1
1
1
1
*/

-- 16 rows
WITH
  L0   AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
  L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B)
SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B;

/*
c
-----------
1
1
1
1
1
1
1
1
1
1
1
1
1
1
1
1
*/

-- definition of GetNums function, using the TOP filter
USE TSQLV5;
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

-- definition of GetNums function, using the OFFSET-FETCH filter
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
  SELECT @low + rownum - 1 AS n
  FROM Nums
  ORDER BY rownum
  OFFSET 0 ROWS FETCH NEXT @high - @low + 1 ROWS ONLY;
GO

-- test function
SELECT n FROM dbo.GetNums(11, 20);

/*
n
--------------------
11
12
13
14
15
16
17
18
19
20
*/

-- generate 10,000,000 numbers
SELECT n FROM dbo.GetNums(1, 10000000);
GO

----------------------------------------------------------------------
-- Sequences of Date and Time Values
----------------------------------------------------------------------

DECLARE 
  @start AS DATE = '20190201',
  @end   AS DATE = '20190212';

SELECT DATEADD(day, n, @start) AS dt
FROM dbo.GetNums(0, DATEDIFF(day, @start, @end)) AS Nums;
GO

/*
dt
----------
2019-02-01
2019-02-02
2019-02-03
2019-02-04
2019-02-05
2019-02-06
2019-02-07
2019-02-08
2019-02-09
2019-02-10
2019-02-11
2019-02-12
*/

DECLARE 
  @start AS DATETIME2 = '20190212 00:00:00.0000000',
  @end   AS DATETIME2 = '20190218 12:00:00.0000000';

SELECT DATEADD(hour, n*12, @start) AS dt
FROM dbo.GetNums(0, DATEDIFF(hour, @start, @end)/12) AS Nums;
GO

/*
dt
---------------------------
2019-02-12 00:00:00.0000000
2019-02-12 12:00:00.0000000
2019-02-13 00:00:00.0000000
2019-02-13 12:00:00.0000000
2019-02-14 00:00:00.0000000
2019-02-14 12:00:00.0000000
2019-02-15 00:00:00.0000000
2019-02-15 12:00:00.0000000
2019-02-16 00:00:00.0000000
2019-02-16 12:00:00.0000000
2019-02-17 00:00:00.0000000
2019-02-17 12:00:00.0000000
2019-02-18 00:00:00.0000000
2019-02-18 12:00:00.0000000
*/

----------------------------------------------------------------------
-- Sequences of Keys
----------------------------------------------------------------------

-- assign unique keys

-- sample data
DROP TABLE IF EXISTS Sales.MyOrders;
GO

SELECT 0 AS orderid, custid, empid, orderdate
INTO Sales.MyOrders
FROM Sales.Orders;

SELECT * FROM Sales.MyOrders;

/*
orderid     custid      empid       orderdate
----------- ----------- ----------- ----------
0           85          5           2017-07-04
0           79          6           2017-07-05
0           34          4           2017-07-08
0           84          3           2017-07-08
0           76          4           2017-07-09
0           34          3           2017-07-10
0           14          5           2017-07-11
0           68          9           2017-07-12
0           88          3           2017-07-15
0           35          4           2017-07-16
...
*/

-- assign keys
WITH C AS
(
  SELECT orderid, ROW_NUMBER() OVER(ORDER BY orderdate, custid) AS rownum
  FROM Sales.MyOrders
)
UPDATE C
  SET orderid = rownum;

SELECT * FROM Sales.MyOrders;

/*
orderid     custid      empid       orderdate
----------- ----------- ----------- ----------
1           85          5           2017-07-04
2           79          6           2017-07-05
3           34          4           2017-07-08
4           84          3           2017-07-08
5           76          4           2017-07-09
6           34          3           2017-07-10
7           14          5           2017-07-11
8           68          9           2017-07-12
9           88          3           2017-07-15
10          35          4           2017-07-16
...
*/

-- apply a range of sequence values obtained from a sequence table
DROP TABLE IF EXISTS dbo.MySequence;
CREATE TABLE dbo.MySequence(val INT);
INSERT INTO dbo.MySequence VALUES(0);
GO

-- single sequence value

-- sequence proc
CREATE OR ALTER PROC dbo.GetSequence
  @val AS INT OUTPUT
AS
UPDATE dbo.MySequence
  SET @val = val += 1;
GO

-- get next sequence (run twice)
DECLARE @key AS INT;
EXEC dbo.GetSequence @val = @key OUTPUT;
SELECT @key;
GO

-- range of sequence values

-- alter sequence proc to support a block of sequence values
ALTER PROC dbo.GetSequence
  @val AS INT OUTPUT,
  @n   AS INT = 1
AS
UPDATE dbo.MySequence
  SET @val = val + 1,
       val += @n;
GO

-- assign sequence values to multiple rows

-- need to assign surrogate keys to the following customers from MySequence
SELECT custid
FROM Sales.Customers
WHERE country = N'UK';

/*
custid
-----------
4
11
16
19
38
53
72
*/

-- solution
DECLARE @firstkey AS INT, @rc AS INT;

DECLARE @CustsStage AS TABLE
(
  custid INT,
  rownum INT
);

INSERT INTO @CustsStage(custid, rownum)
  SELECT custid, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
  FROM Sales.Customers
  WHERE country = N'UK';

SET @rc = @@rowcount;

EXEC dbo.GetSequence @val = @firstkey OUTPUT, @n = @rc;

SELECT custid, @firstkey + rownum - 1 AS keycol
FROM @CustsStage;
GO

/*
custid      keycol
----------- -----------
4           3
11          4
16          5
19          6
38          7
53          8
72          9
*/

-- Listing 6-1: Adding Customers from France
DECLARE @firstkey AS INT, @rc AS INT;

DECLARE @CustsStage AS TABLE
(
  custid INT,
  rownum INT
);

INSERT INTO @CustsStage(custid, rownum)
  SELECT custid, ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
  FROM Sales.Customers
  WHERE country = N'France';

SET @rc = @@rowcount;

EXEC dbo.GetSequence @val = @firstkey OUTPUT, @n = @rc;

SELECT custid, @firstkey + rownum - 1 AS keycol
FROM @CustsStage;
GO

/*
custid      keycol
----------- -----------
7           10
9           11
18          12
23          13
26          14
40          15
41          16
57          17
74          18
84          19
85          20
*/

-- cleanup
DROP PROC IF EXISTS dbo.GetSequence;
DROP TABLE IF EXISTS dbo.MySequence;

----------------------------------------------------------------------
-- Paging
----------------------------------------------------------------------

-- create index
CREATE UNIQUE INDEX idx_od_oid_i_cid_eid
  ON Sales.Orders(orderdate, orderid)
  INCLUDE(custid, empid);
GO

-- Listing 6-2: Code Returning Third Page of Orders using ROW_NUMBER
DECLARE
  @pagenum  AS INT = 3,
  @pagesize AS INT = 25;

WITH C AS
(
  SELECT ROW_NUMBER() OVER( ORDER BY orderdate, orderid ) AS rownum,
    orderid, orderdate, custid, empid
  FROM Sales.Orders
)
SELECT orderid, orderdate, custid, empid
FROM C
WHERE rownum BETWEEN (@pagenum - 1) * @pagesize + 1
                 AND @pagenum * @pagesize
ORDER BY rownum;
GO

/*
orderid     orderdate  custid      empid
----------- ---------- ----------- -----------
10298       2017-09-05 37          6
10299       2017-09-06 67          4
10300       2017-09-09 49          2
10301       2017-09-09 86          8
10302       2017-09-10 76          4
10303       2017-09-11 30          7
10304       2017-09-12 80          1
10305       2017-09-13 55          8
10306       2017-09-16 69          1
10307       2017-09-17 48          2
10308       2017-09-18 2           7
10309       2017-09-19 37          3
10310       2017-09-20 77          8
10311       2017-09-20 18          1
10312       2017-09-23 86          2
10313       2017-09-24 63          2
10314       2017-09-25 65          1
10315       2017-09-26 38          4
10316       2017-09-27 65          1
10317       2017-09-30 48          6
10318       2017-10-01 38          8
10319       2017-10-02 80          7
10320       2017-10-03 87          5
10321       2017-10-03 38          3
10322       2017-10-04 58          7
*/

-- with OFFSET/FETCH
DECLARE
  @pagenum  AS INT = 3,
  @pagesize AS INT = 25;

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO

-- cleanup
DROP INDEX IF EXISTS idx_od_oid_i_cid_eid ON Sales.Orders;

----------------------------------------------------------------------
-- Removing Duplicates
----------------------------------------------------------------------

DROP TABLE IF EXISTS Sales.MyOrders;
GO

SELECT * INTO Sales.MyOrders FROM Sales.Orders
UNION ALL
SELECT * FROM Sales.Orders WHERE orderid % 100 = 0
UNION ALL
SELECT * FROM Sales.Orders WHERE orderid % 50 = 0;
GO

-- small number of duplicates

-- mark duplicates
SELECT orderid,
  ROW_NUMBER() OVER(PARTITION BY orderid
                    ORDER BY (SELECT NULL)) AS n
FROM Sales.MyOrders;

/*
orderid     n
----------- ----
10248       1
10249       1
10250       1
10250       2
10251       1
...
10299       1
10300       1
10300       2
10300       3
10301       1
10302       1
...

(855 rows affected)
*/

-- remove duplicates
WITH C AS
(
  SELECT orderid,
    ROW_NUMBER() OVER(PARTITION BY orderid
                      ORDER BY (SELECT NULL)) AS n
  FROM Sales.MyOrders
)
DELETE FROM C
WHERE n > 1;

-- Large number of duplicates
WITH C AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY orderid
                      ORDER BY (SELECT NULL)) AS n
  FROM Sales.MyOrders
)
SELECT orderid, custid, empid, orderdate, requireddate, shippeddate, 
  shipperid, freight, shipname, shipaddress, shipcity, shipregion, 
  shippostalcode, shipcountry
INTO Sales.MyOrdersTmp
FROM C
WHERE n = 1;

-- recreate indexes, constraints

TRUNCATE TABLE Sales.MyOrders;
ALTER TABLE Sales.MyOrdersTmp SWITCH TO Sales.MyOrders;
DROP TABLE Sales.MyOrdersTmp;

-- another solution
-- mark row numbers and ranks
SELECT orderid,
  ROW_NUMBER() OVER(ORDER BY orderid) AS rownum,
  RANK() OVER(ORDER BY orderid) AS rnk
FROM Sales.MyOrders;

/*
orderid     rownum               rnk
----------- -------------------- --------------------
10248       1                    1
10248       2                    1
10248       3                    1
10249       4                    4
10249       5                    4
10249       6                    4
10250       7                    7
10250       8                    7
10250       9                    7
*/

-- remove duplicates
WITH C AS
(
  SELECT orderid,
    ROW_NUMBER() OVER(ORDER BY orderid) AS rownum,
    RANK() OVER(ORDER BY orderid) AS rnk
  FROM Sales.MyOrders
)
DELETE FROM C
WHERE rownum <> rnk;

-- cleanup
DROP TABLE IF EXISTS Sales.MyOrders;

----------------------------------------------------------------------
-- Pivoting
----------------------------------------------------------------------

-- total order values for each year and month
-- show years on rows, months on columns, and total order values in data
WITH C AS
(
  SELECT YEAR(orderdate) AS orderyear, MONTH(orderdate) AS ordermonth, val
  FROM Sales.OrderValues
)
SELECT *
FROM C
  PIVOT(SUM(val)
    FOR ordermonth IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS P;

/*
orderyear  1         2         3          4           5         6
---------- --------- --------- ---------- ----------- --------- ---------
2019       94222.12  99415.29  104854.18  123798.70   18333.64  NULL
2017       NULL      NULL      NULL       NULL        NULL      NULL
2018       61258.08  38483.64  38547.23   53032.95    53781.30  36362.82

orderyear  7         8         9          10          11        12
---------- --------- --------- ---------- ----------- --------- ---------
2019       NULL      NULL      NULL       NULL        NULL      NULL
2017       27861.90  25485.28  26381.40   37515.73    45600.05  45239.63
2018       51020.86  47287.68  55629.27   66749.23    43533.80  71398.44
*/

-- order values of 5 most recent orders per customer
-- show customer IDs on rows, ordinals on columns, and total order values in data

-- generate row numbers
SELECT custid, val,
  ROW_NUMBER() OVER(PARTITION BY custid
                    ORDER BY orderdate DESC, orderid DESC) AS rownum
FROM Sales.OrderValues;

/*
custid  val      rownum
------- -------- -------
1       933.50   1
1       471.20   2
1       845.80   3
1       330.00   4
1       878.00   5
1       814.50   6
2       514.40   1
2       320.00   2
2       479.75   3
2       88.80    4
3       660.00   1
3       375.50   2
3       813.37   3
3       2082.00  4
3       1940.85  5
3       749.06   6
3       403.20   7
...
*/

-- handle pivoting
WITH C AS
(
  SELECT custid, val,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY orderdate DESC, orderid DESC) AS rownum
  FROM Sales.OrderValues
)
SELECT *
FROM C
  PIVOT(MAX(val) FOR rownum IN ([1],[2],[3],[4],[5])) AS P;

/*
custid  1        2        3        4        5
------- -------- -------- -------- -------- ---------
1       933.50   471.20   845.80   330.00   878.00
2       514.40   320.00   479.75   88.80    NULL
3       660.00   375.50   813.37   2082.00  1940.85
4       491.50   4441.25  390.00   282.00   191.10
5       1835.70  709.55   1096.20  2048.21  1064.50
6       858.00   677.00   625.00   464.00   330.00
7       730.00   660.00   450.00   593.75   1761.00
8       224.00   3026.85  982.00   NULL     NULL
9       792.75   360.00   1788.63  917.00   1979.23
10      525.00   1309.50  877.73   1014.00  717.50
...
*/

-- concatenate order IDs of 5 most recent orders per customer, using CONCAT to concatenate
WITH C AS
(
  SELECT custid, CAST(orderid AS VARCHAR(11)) AS sorderid,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY orderdate DESC, orderid DESC) AS rownum
  FROM Sales.OrderValues
)
SELECT custid, CONCAT([1], ','+[2], ','+[3], ','+[4], ','+[5]) AS orderids
FROM C
  PIVOT(MAX(sorderid) FOR rownum IN ([1],[2],[3],[4],[5])) AS P;

/*
custid      orderids
----------- -----------------------------------------------------------
1           11011,10952,10835,10702,10692
2           10926,10759,10625,10308
3           10856,10682,10677,10573,10535
4           11016,10953,10920,10864,10793
5           10924,10875,10866,10857,10837
6           11058,10956,10853,10614,10582
7           10826,10679,10628,10584,10566
8           10970,10801,10326
9           11076,10940,10932,10876,10871
10          11048,11045,11027,10982,10975
...
*/

-- using + to concatenate
WITH C AS
(
  SELECT custid, CAST(orderid AS VARCHAR(11)) AS sorderid,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY orderdate DESC, orderid DESC) AS rownum
  FROM Sales.OrderValues
)
SELECT custid, 
  [1] + COALESCE(','+[2], '')
      + COALESCE(','+[3], '')
      + COALESCE(','+[4], '')
      + COALESCE(','+[5], '') AS orderids
FROM C
  PIVOT(MAX(sorderid) FOR rownum IN ([1],[2],[3],[4],[5])) AS P;
GO

----------------------------------------------------------------------
-- TOP N Per Group
----------------------------------------------------------------------

-- TOP OVER (unsupported)
/*
SELECT
  TOP (3) OVER(
    PARTITION BY custid
    ORDER BY orderdate DESC, orderid DESC)
  custid, orderdate, orderid, empid
FROM Sales.Orders;
*/
GO

-- POC index
CREATE UNIQUE INDEX idx_cid_odD_oidD_i_empid
  ON Sales.Orders(custid, orderdate DESC, orderid DESC)
  INCLUDE(empid);

-- low density of partitioning element
WITH C AS
(
  SELECT custid, orderdate, orderid, empid,
    ROW_NUMBER() OVER(
      PARTITION BY custid
      ORDER BY orderdate DESC, orderid DESC) AS rownum
  FROM Sales.Orders
)
SELECT custid, orderdate, orderid, empid, rownum
FROM C
WHERE rownum <= 3
ORDER BY custid, rownum;

-- high density of partitioning column
SELECT C.custid, A.orderdate, A.orderid, A.empid
FROM Sales.Customers AS C
  CROSS APPLY (SELECT TOP (3) orderdate, orderid, empid
               FROM Sales.Orders AS O
               WHERE O.custid = C.custid
               ORDER BY orderdate DESC, orderid DESC) AS A;

-- alternative using OFFSET-FETCH
SELECT C.custid, A.orderdate, A.orderid, A.empid
FROM Sales.Customers AS C
  CROSS APPLY (SELECT orderdate, orderid, empid
               FROM Sales.Orders AS O
               WHERE O.custid = C.custid
               ORDER BY orderdate DESC, orderid DESC
               OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A;
               
-- cleanup
DROP INDEX IF EXISTS idx_cid_odD_oidD_i_empid ON Sales.Orders;

-- carry-along-sort technique
WITH C AS
(
  SELECT custid, 
    MAX(CONVERT(CHAR(8), orderdate, 112)
        + STR(orderid, 10)
        + STR(empid, 10) COLLATE Latin1_General_BIN2) AS mx
  FROM Sales.Orders
  GROUP BY custid
)
SELECT custid,
  CAST(SUBSTRING(mx,  1,  8) AS DATETIME) AS orderdate,
  CAST(SUBSTRING(mx,  9, 10) AS INT)      AS custid,
  CAST(SUBSTRING(mx, 19, 10) AS INT)      AS empid
FROM C;

----------------------------------------------------------------------
-- Emulating IGNORE NULLS to Get the Last Non-NULL
----------------------------------------------------------------------

-- create and populate T1
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO

CREATE TABLE dbo.T1
(
  id INT NOT NULL CONSTRAINT PK_T1 PRIMARY KEY,
  col1 INT NULL
);

INSERT INTO dbo.T1(id, col1) VALUES
  ( 2, NULL),
  ( 3,   10),
  ( 5,   -1),
  ( 7, NULL),
  (11, NULL),
  (13,  -12),
  (17, NULL),
  (19, NULL),
  (23, 1759);

-- standard query
/*
SELECT id, col1,
  COALESCE(col1, LAG(col1) IGNORE NULLS OVER(ORDER BY id)) AS lastval
FROM dbo.T1;
*/

-- desired result
/*
id  col1  lastval
--- ----- --------
2   NULL  NULL
3   10    10
5   -1    -1
7   NULL  -1
11  NULL  -1
13  -12   -12
17  NULL  -12
19  NULL  -12
23  1759  1759
*/

-- Solution 1 (from Chapter 2)
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

-- test performance

-- populate T1 with 10M rows
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

-- Solution 2: using carry-along-sort

-- step 1
SELECT id, col1, binstr,
  MAX(binstr) OVER(ORDER BY id ROWS UNBOUNDED PRECEDING) AS mx
FROM dbo.T1
  CROSS APPLY ( VALUES( CAST(id AS BINARY(4)) + CAST(col1 AS BINARY(4)) ) )
    AS A(binstr);

/*
id  col1  binstr             mx
--- ----- ------------------ ------------------
2   NULL  NULL               NULL
3   10    0x000000030000000A 0x000000030000000A
5   -1    0x00000005FFFFFFFF 0x00000005FFFFFFFF
7   NULL  NULL               0x00000005FFFFFFFF
11  NULL  NULL               0x00000005FFFFFFFF
13  -12   0x0000000DFFFFFFF4 0x0000000DFFFFFFF4
17  NULL  NULL               0x0000000DFFFFFFF4
19  NULL  NULL               0x0000000DFFFFFFF4
23  1759  0x00000017000006DF 0x00000017000006DF
*/

-- complete solution, using row mode
SELECT id, col1,
  CAST( SUBSTRING( MAX( CAST(id AS BINARY(4)) + CAST(col1 AS BINARY(4)) )
                     OVER( ORDER BY id ROWS UNBOUNDED PRECEDING ), 5, 4)
    AS INT) AS lastval
FROM dbo.T1
OPTION(USE HINT('DISALLOW_BATCH_MODE'));

-- with batch processing, similar performance numbers
SELECT id, col1,
  CAST( SUBSTRING( MAX( CAST(id AS BINARY(4)) + CAST(col1 AS BINARY(4)) )
                     OVER( ORDER BY id ROWS UNBOUNDED PRECEDING ), 5, 4)
    AS INT) AS lastval
FROM dbo.T1;

----------------------------------------------------------------------
-- Mode
----------------------------------------------------------------------

-- index
CREATE INDEX idx_custid_empid ON Sales.Orders(custid, empid);

-- first step: calculate the count of orders for each customer and employee
SELECT custid, empid, COUNT(*) AS cnt
FROM Sales.Orders
GROUP BY custid, empid;

/*
custid      empid       cnt
----------- ----------- -----------
1           1           2
3           1           1
4           1           3
5           1           4
9           1           3
10          1           2
11          1           1
14          1           1
15          1           1
17          1           2
...
*/

-- second step: add calculation of row numbers:
SELECT custid, empid, COUNT(*) AS cnt,
  ROW_NUMBER() OVER(PARTITION BY custid
                    ORDER BY COUNT(*) DESC, empid DESC) AS rn
FROM Sales.Orders
GROUP BY custid, empid;

/*
custid      empid       cnt         rn
----------- ----------- ----------- --------------------
1           4           2           1
1           1           2           2
1           6           1           3
1           3           1           4
2           3           2           1
2           7           1           2
2           4           1           3
3           3           3           1
3           7           2           2
3           4           1           3
3           1           1           4
...
*/

-- solution based on window functions, using a tiebreaker
WITH C AS
(
  SELECT custid, empid, COUNT(*) AS cnt,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY COUNT(*) DESC, empid DESC) AS rn
  FROM Sales.Orders
  GROUP BY custid, empid
)
SELECT custid, empid, cnt
FROM C
WHERE rn = 1;

/*
custid      empid       cnt
----------- ----------- -----------
1           4           2
2           3           2
3           3           3
4           4           4
5           3           6
6           9           3
7           4           3
8           4           2
9           4           4
10          3           4
...
*/

-- solution based on ranking calculations, no tiebreaker
WITH C AS
(
  SELECT custid, empid, COUNT(*) AS cnt,
    RANK() OVER(PARTITION BY custid
                ORDER BY COUNT(*) DESC) AS rk
  FROM Sales.Orders
  GROUP BY custid, empid
)
SELECT custid, empid, cnt
FROM C
WHERE rk = 1;

/*
custid      empid       cnt
----------- ----------- -----------
1           1           2
1           4           2
2           3           2
3           3           3
4           4           4
5           3           6
6           9           3
7           4           3
8           4           2
9           4           4
10          3           4
11          6           2
11          4           2
11          3           2
...
*/

-- solution based on carry-along-sort

-- first, create the concatenated string
SELECT custid,
  CAST(COUNT(*) AS BINARY(4)) + CAST(empid AS BINARY(4)) AS cntemp
FROM Sales.Orders
GROUP BY custid, empid;

/*
custid      cntemp
----------- ------------------
1           0x0000000200000001
1           0x0000000100000003
1           0x0000000200000004
1           0x0000000100000006
2           0x0000000200000003
2           0x0000000100000004
2           0x0000000100000007
3           0x0000000100000001
3           0x0000000300000003
3           0x0000000100000004
3           0x0000000200000007
...
*/

-- complete solution
WITH C AS
(
  SELECT custid,
    CAST(COUNT(*) AS BINARY(4)) + CAST(empid AS BINARY(4)) AS cntemp
  FROM Sales.Orders
  GROUP BY custid, empid
)
SELECT custid,
  CAST(SUBSTRING(MAX(cntemp), 5, 4) AS INT) AS empid,
  CAST(SUBSTRING(MAX(cntemp),  1, 4) AS INT) AS cnt
FROM C
GROUP BY custid;

/*
custid      empid       cnt
----------- ----------- -----------
1           4           2
2           3           2
3           3           3
4           4           4
5           3           6
6           9           3
7           4           3
8           4           2
9           4           4
10          3           4
...
*/

-- cleanup
DROP INDEX IF EXISTS idx_custid_empid ON Sales.Orders;

----------------------------------------------------------------------
-- Trimmed Mean
----------------------------------------------------------------------

-- compute NTILE(20)
SELECT empid, val,
  NTILE(20) OVER(PARTITION BY empid ORDER BY val) AS ntile20
FROM Sales.OrderValues;

/*
empid  val       ntile20
------ --------- --------
1      33.75     1
1      69.60     1
1      72.96     1
1      86.85     1
1      93.50     1
1      108.00    1
1      110.00    1
1      137.50    2
1      147.00    2
1      154.40    2
1      230.40    2
1      230.85    2
1      240.00    2
1      268.80    2
...
1      3192.65   19
1      3424.00   19
1      3463.00   19
1      3687.00   19
1      3868.60   19
1      4109.70   19
1      4330.40   20
1      4807.00   20
1      5398.73   20
1      6375.00   20
1      6635.28   20
1      15810.00  20
...
*/

-- compute trimmed mean
WITH C AS
(
  SELECT empid, val,
    NTILE(20) OVER(PARTITION BY empid ORDER BY val) AS ntile20
  FROM Sales.OrderValues
)
SELECT empid, AVG(val) AS avgval
FROM C
WHERE ntile20 BETWEEN 2 AND 19
GROUP BY empid;

/*
empid  avgval
------ ------------
1      1347.059818
2      1389.643793
3      1269.213508
4      1314.047234
5      1424.875675
6      1048.360166
7      1444.162307
8      1135.191827
9      1554.841578
*/

----------------------------------------------------------------------
-- Running Totals
----------------------------------------------------------------------

-- Listing 6-3: Create and Populate the Transactions Table with a Small Set of Sample Data
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Transactions;

CREATE TABLE dbo.Transactions
(
  actid  INT   NOT NULL,                -- partitioning column
  tranid INT   NOT NULL,                -- ordering column
  val    MONEY NOT NULL,                -- measure
  CONSTRAINT PK_Transactions PRIMARY KEY(actid, tranid)
);
GO

-- small set of sample data
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

-- Listing 6-4: Desired Results for Running Totals Task
/*
actid       tranid      val                   balance
----------- ----------- --------------------- ---------------------
1           1           4.00                  4.00
1           2           -2.00                 2.00
1           3           5.00                  7.00
1           4           2.00                  9.00
1           5           1.00                  10.00
1           6           3.00                  13.00
1           7           -4.00                 9.00
1           8           -1.00                 8.00
1           9           -2.00                 6.00
1           10          -3.00                 3.00
2           1           2.00                  2.00
2           2           1.00                  3.00
2           3           5.00                  8.00
2           4           1.00                  9.00
2           5           -5.00                 4.00
2           6           4.00                  8.00
2           7           2.00                  10.00
2           8           -4.00                 6.00
2           9           -5.00                 1.00
2           10          4.00                  5.00
3           1           -3.00                 -3.00
3           2           3.00                  0.00
3           3           -2.00                 -2.00
3           4           1.00                  -1.00
3           5           4.00                  3.00
3           6           -1.00                 2.00
3           7           5.00                  7.00
3           8           3.00                  10.00
3           9           5.00                  15.00
3           10          -3.00                 12.00
*/

-- larger set of sample data (change inputs as needed)
DECLARE
  @num_partitions     AS INT = 100,
  @rows_per_partition AS INT = 10000;

TRUNCATE TABLE dbo.Transactions;

INSERT INTO dbo.Transactions WITH (TABLOCK) (actid, tranid, val)
  SELECT NP.n, RPP.n,
    (ABS(CHECKSUM(NEWID())%2)*2-1) * (1 + ABS(CHECKSUM(NEWID())%5))
  FROM dbo.GetNums(1, @num_partitions) AS NP
    CROSS JOIN dbo.GetNums(1, @rows_per_partition) AS RPP;

-- Set-Based Solution Using Window Functions
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS UNBOUNDED PRECEDING) AS balance
FROM dbo.Transactions;

-- Set-Based Solution Using Subqueries
SELECT actid, tranid, val,
  (SELECT SUM(T2.val)
   FROM dbo.Transactions AS T2
   WHERE T2.actid = T1.actid
     AND T2.tranid <= T1.tranid) AS balance
FROM dbo.Transactions AS T1;

-- Set-Based Solution Using Joins
SELECT T1.actid, T1.tranid, T1.val,
  SUM(T2.val) AS balance
FROM dbo.Transactions AS T1
  INNER JOIN dbo.Transactions AS T2
    ON T2.actid = T1.actid
   AND T2.tranid <= T1.tranid
GROUP BY T1.actid, T1.tranid, T1.val;

-- Listing 6-5: Cursor-Based Solution for Running Totals
SET NOCOUNT ON;
DECLARE @Result AS TABLE
(
  actid   INT,
  tranid  INT,
  val     MONEY,
  balance MONEY
);

DECLARE
  @C        AS CURSOR,
  @actid    AS INT,
  @prvactid AS INT,
  @tranid   AS INT,
  @val      AS MONEY,
  @balance  AS MONEY;

SET @C = CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
  SELECT actid, tranid, val
  FROM dbo.Transactions
  ORDER BY actid, tranid;

OPEN @C

FETCH NEXT FROM @C INTO @actid, @tranid, @val;

SELECT @prvactid = @actid, @balance = 0;

WHILE @@fetch_status = 0
BEGIN
  IF @actid <> @prvactid
    SELECT @prvactid = @actid, @balance = 0;

  SET @balance = @balance + @val;

  INSERT INTO @Result VALUES(@actid, @tranid, @val, @balance);
  
  FETCH NEXT FROM @C INTO @actid, @tranid, @val;
END

SELECT * FROM @Result;

-- Listing 6-6: CLR-Based Solution for Running Totals
/*
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void AccountBalances()
    {
        using (SqlConnection conn = new SqlConnection("context connection=true;"))
        {
            SqlCommand comm = new SqlCommand();
            comm.Connection = conn;
            comm.CommandText = @"" +
                "SELECT actid, tranid, val " +
                "FROM dbo.Transactions " +
                "ORDER BY actid, tranid;";

            SqlMetaData[] columns = new SqlMetaData[4];
            columns[0] = new SqlMetaData("actid"  , SqlDbType.Int);
            columns[1] = new SqlMetaData("tranid" , SqlDbType.Int);
            columns[2] = new SqlMetaData("val"    , SqlDbType.Money);
            columns[3] = new SqlMetaData("balance", SqlDbType.Money);

            SqlDataRecord record = new SqlDataRecord(columns);

            SqlContext.Pipe.SendResultsStart(record);

            conn.Open();

            SqlDataReader reader = comm.ExecuteReader();

            SqlInt32 prvactid = 0;
            SqlMoney balance = 0;

            while (reader.Read())
            {
                SqlInt32 actid = reader.GetSqlInt32(0);
                SqlMoney val = reader.GetSqlMoney(2);

                if (actid == prvactid)
                {
                    balance += val;
                }
                else
                {
                    balance = val;
                }

                prvactid = actid;

                record.SetSqlInt32(0, reader.GetSqlInt32(0));
                record.SetSqlInt32(1, reader.GetSqlInt32(1));
                record.SetSqlMoney(2, val);
                record.SetSqlMoney(3, balance);

                SqlContext.Pipe.SendResultsRow(record);
            }

            SqlContext.Pipe.SendResultsEnd();
        }
    }
};
*/

CREATE ASSEMBLY AccountBalances 
  FROM 'C:\AccountBalances\AccountBalances.dll';
GO

CREATE PROCEDURE dbo.AccountBalances
AS EXTERNAL NAME AccountBalances.StoredProcedures.AccountBalances;
GO

EXEC dbo.AccountBalances;

-- cleanup
DROP PROCEDURE IF EXISTS dbo.AccountBalances;
DROP ASSEMBLY IF EXISTS AccountBalances;
GO

-- Listing 6-7: Solution with Recursive CTE to Running Totals
SELECT actid, tranid, val,
  ROW_NUMBER() OVER(PARTITION BY actid ORDER BY tranid) AS rownum
INTO #Transactions
FROM dbo.Transactions;

CREATE UNIQUE CLUSTERED INDEX idx_rownum_actid ON #Transactions(rownum, actid);

WITH C AS
(
  SELECT 1 AS rownum, actid, tranid, val, val AS sumqty
  FROM #Transactions
  WHERE rownum = 1
  
  UNION ALL
  
  SELECT PRV.rownum + 1, PRV.actid, CUR.tranid, CUR.val, PRV.sumqty + CUR.val
  FROM C AS PRV
    INNER JOIN #Transactions AS CUR
      ON CUR.rownum = PRV.rownum + 1
      AND CUR.actid = PRV.actid
)
SELECT actid, tranid, val, sumqty
FROM C
OPTION (MAXRECURSION 0);

DROP TABLE IF EXISTS #Transactions;
GO

-- Nested Iterations, Using Loops
SELECT ROW_NUMBER() OVER(PARTITION BY actid ORDER BY tranid) AS rownum,
  actid, tranid, val, CAST(val AS BIGINT) AS sumqty
INTO #Transactions
FROM dbo.Transactions;

CREATE UNIQUE CLUSTERED INDEX idx_rownum_actid ON #Transactions(rownum, actid);

DECLARE @rownum AS INT;
SET @rownum = 1;

WHILE 1 = 1
BEGIN
  SET @rownum = @rownum + 1;
  
  UPDATE CUR
    SET sumqty = PRV.sumqty + CUR.val
  FROM #Transactions AS CUR
    INNER JOIN #Transactions AS PRV
      ON CUR.rownum = @rownum
     AND PRV.rownum = @rownum - 1
     AND CUR.actid = PRV.actid;

  IF @@rowcount = 0 BREAK;
END

SELECT actid, tranid, val, sumqty
FROM #Transactions;

DROP TABLE IF EXISTS #Transactions;
GO

-- Listing 6-8: Solution using Multirow UPDATE with Variables
CREATE TABLE #Transactions
(
  actid          INT,
  tranid         INT,
  val            MONEY,
  balance        MONEY
);

CREATE CLUSTERED INDEX idx_actid_tranid ON #Transactions(actid, tranid);

INSERT INTO #Transactions WITH (TABLOCK) (actid, tranid, val, balance)
  SELECT actid, tranid, val, 0.00
  FROM dbo.Transactions
  ORDER BY actid, tranid;

DECLARE @prevaccount AS INT, @prevbalance AS MONEY;

UPDATE #Transactions
  SET @prevbalance = balance = CASE
                                 WHEN actid = @prevaccount
                                   THEN @prevbalance + val
                                 ELSE val
                               END,
      @prevaccount = actid
FROM #Transactions WITH(INDEX(1), TABLOCKX)
OPTION (MAXDOP 1);

SELECT * FROM #Transactions;

DROP TABLE IF EXISTS #Transactions;
GO

----------------------------------------------------------------------
-- Max Concurrent Sessions
----------------------------------------------------------------------

-- Creating and Populating Sessions
SET NOCOUNT ON;
USE TSQLV5;

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

/*
app        mx
---------- -----------
app1       4
app2       3
*/

-- large set of sample data
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

-- traditional set-based solution
WITH TimePoints AS 
(
  SELECT app, starttime AS ts FROM dbo.Sessions
),
Counts AS
(
  SELECT app, ts,
    (SELECT COUNT(*)
     FROM dbo.Sessions AS S
     WHERE P.app = S.app
       AND P.ts >= S.starttime
       AND P.ts < S.endtime) AS concurrent
  FROM TimePoints AS P
)      
SELECT app, MAX(concurrent) AS mx
FROM Counts
GROUP BY app;

-- supporting index
CREATE INDEX idx_start_end ON dbo.Sessions(app, starttime, endtime);

-- drop index
DROP INDEX IF EXISTS idx_start_end ON dbo.Sessions;

-- indexes for solutions based on window functions
CREATE UNIQUE INDEX idx_start ON dbo.Sessions(app, starttime, keycol);
CREATE UNIQUE INDEX idx_end ON dbo.Sessions(app, endtime, keycol);

-- return a sequence of start and end events
SELECT keycol, app, starttime AS ts, +1 AS type
FROM dbo.Sessions
  
UNION ALL
  
SELECT keycol, app, endtime AS ts, -1 AS type
FROM dbo.Sessions
  
ORDER BY app, ts, type, keycol;

-- Listing 6-9: Chronological Sequence of Session Start and End Events
/*
keycol  app   ts                   type
------- ----- -------------------- -----
2       app1  2019-02-12 08:30:00  1
3       app1  2019-02-12 08:30:00  1
3       app1  2019-02-12 08:45:00  -1
5       app1  2019-02-12 09:00:00  1
7       app1  2019-02-12 09:15:00  1
11      app1  2019-02-12 09:15:00  1
5       app1  2019-02-12 09:30:00  -1
11      app1  2019-02-12 09:30:00  -1
2       app1  2019-02-12 10:30:00  -1
7       app1  2019-02-12 10:30:00  -1
13      app1  2019-02-12 10:30:00  1
17      app1  2019-02-12 10:45:00  1
19      app1  2019-02-12 11:00:00  1
17      app1  2019-02-12 11:30:00  -1
19      app1  2019-02-12 12:30:00  -1
13      app1  2019-02-12 14:30:00  -1
23      app2  2019-02-12 08:30:00  1
23      app2  2019-02-12 08:45:00  -1
29      app2  2019-02-12 09:00:00  1
29      app2  2019-02-12 09:30:00  -1
31      app2  2019-02-12 11:45:00  1
31      app2  2019-02-12 12:00:00  -1
37      app2  2019-02-12 12:30:00  1
41      app2  2019-02-12 12:45:00  1
43      app2  2019-02-12 13:00:00  1
41      app2  2019-02-12 13:30:00  -1
37      app2  2019-02-12 14:00:00  -1
43      app2  2019-02-12 14:00:00  -1
47      app2  2019-02-12 14:00:00  1
53      app2  2019-02-12 15:30:00  1
47      app2  2019-02-12 16:30:00  -1
53      app2  2019-02-12 17:00:00  -1
*/

-- solution using window aggregate function
WITH C1 AS
(
  SELECT keycol, app, starttime AS ts, +1 AS type
  FROM dbo.Sessions
    
  UNION ALL
    
  SELECT keycol, app, endtime AS ts, -1 AS type
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(type) OVER(PARTITION BY app
                   ORDER BY ts, type, keycol
                   ROWS UNBOUNDED PRECEDING) AS cnt
  FROM C1
)
SELECT app, MAX(cnt) AS mx
FROM C2
GROUP BY app;

-- force serial plan
WITH C1 AS
(
  SELECT keycol, app, starttime AS ts, +1 AS type
  FROM dbo.Sessions
    
  UNION ALL
    
  SELECT keycol, app, endtime AS ts, -1 AS type
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(type) OVER(PARTITION BY app
                   ORDER BY ts, type, keycol
                   ROWS UNBOUNDED PRECEDING) AS cnt
  FROM C1
)
SELECT app, MAX(cnt) AS mx
FROM C2
GROUP BY app
OPTION(MAXDOP 1);

-- solution using ROW_NUMBER
WITH C1 AS
(
  SELECT app, starttime AS ts, +1 AS type, keycol,
    ROW_NUMBER() OVER(PARTITION BY app ORDER BY starttime, keycol)
      AS start_ordinal
  FROM dbo.Sessions

  UNION ALL

  SELECT app, endtime AS ts, -1 AS type, keycol, NULL AS start_ordinal
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY app ORDER BY ts, type, keycol)
      AS start_or_end_ordinal
  FROM C1
)
SELECT app, MAX(start_ordinal - (start_or_end_ordinal - start_ordinal)) AS mx
FROM C2
GROUP BY app;

----------------------------------------------------------------------
-- Packing Intervals
----------------------------------------------------------------------

-- Listing 6-10: Creating and Populating Users and Sessions with Small Sets of Sample Data
SET NOCOUNT ON;
USE TSQLV5;

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
  @num_users          AS INT          = 2000,
  @intervals_per_user AS INT          = 2500,
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

-- traditional solution
-- run time: several hours

-- Listing 6-12: Traditional Set-Based Solution to Packing Intervals
WITH StartTimes AS
(
  SELECT DISTINCT username, starttime
  FROM dbo.Sessions AS S1
  WHERE NOT EXISTS
    (SELECT * FROM dbo.Sessions AS S2
     WHERE S2.username = S1.username
       AND S2.starttime < S1.starttime
       AND S2.endtime >= S1.starttime)
),
EndTimes AS
(
  SELECT DISTINCT username, endtime
  FROM dbo.Sessions AS S1
  WHERE NOT EXISTS
    (SELECT * FROM dbo.Sessions AS S2
     WHERE S2.username = S1.username
       AND S2.endtime > S1.endtime
       AND S2.starttime <= S1.endtime)
)
SELECT username, starttime,
  (SELECT MIN(endtime) FROM EndTimes AS E
   WHERE E.username = S.username
     AND endtime >= starttime) AS endtime
FROM StartTimes AS S;

-- cleanup indexes for traditional solution
DROP INDEX IF EXISTS idx_user_start_end ON dbo.Sessions;
DROP INDEX IF EXISTS idx_user_end_start ON dbo.Sessions;

-- fake filtered columnstore index to support Solution 1 and Solution 2 based on window functions
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_cs ON dbo.Sessions(id)
  WHERE id = -1 AND id = -2;

-- indexes for Solution 1 based on window functions
CREATE UNIQUE INDEX idx_user_start_id ON dbo.Sessions(username, starttime, id);
CREATE UNIQUE INDEX idx_user_end_id ON dbo.Sessions(username, endtime, id);

-- Listing 6-13: Solution 1 Based on Window Functions to Packing Intervals
WITH C1 AS
(
  SELECT id, username, starttime AS ts, +1 AS type
  FROM dbo.Sessions

  UNION ALL

  SELECT id, username, endtime AS ts, -1 AS type
  FROM dbo.Sessions
),
C2 AS
(
  SELECT username, ts, type,
    SUM(type) OVER(PARTITION BY username
                   ORDER BY ts, type DESC, id
                   ROWS UNBOUNDED PRECEDING) AS cnt
  FROM C1
),
C3 AS
(
  SELECT username, ts, 
    (ROW_NUMBER() OVER(PARTITION BY username ORDER BY ts) - 1) / 2 + 1 AS grp
  FROM C2
  WHERE (type = 1 AND cnt = 1)
     OR (type = -1 AND cnt = 0)
)
SELECT username, MIN(ts) AS starttime, max(ts) AS endtime
FROM C3
GROUP BY username, grp;

-- Listing 6-14: Output of Code in C2
/*
username  ts                type   cnt
--------- ----------------- ------ ----
User1     2019-12-01 08:00  1      1
User1     2019-12-01 08:30  1      2
User1     2019-12-01 08:30  -1     1
User1     2019-12-01 09:00  1      2
User1     2019-12-01 09:00  -1     1
User1     2019-12-01 09:30  -1     0
User1     2019-12-01 10:00  1      1
User1     2019-12-01 10:30  1      2
User1     2019-12-01 11:00  -1     1
User1     2019-12-01 11:30  1      2
User1     2019-12-01 12:00  -1     1
User1     2019-12-01 12:30  -1     0
User2     2019-12-01 08:00  1      1
User2     2019-12-01 08:30  1      2
User2     2019-12-01 09:00  1      3
User2     2019-12-01 09:30  -1     2
User2     2019-12-01 10:00  -1     1
User2     2019-12-01 10:30  -1     0
User2     2019-12-01 11:00  1      1
User2     2019-12-01 11:30  -1     0
User2     2019-12-01 11:32  1      1
User2     2019-12-01 12:00  -1     0
User2     2019-12-01 12:04  1      1
User2     2019-12-01 12:30  -1     0
User3     2019-12-01 08:00  1      1
User3     2019-12-01 08:00  1      2
User3     2019-12-01 08:30  1      3
User3     2019-12-01 08:30  -1     2
User3     2019-12-01 09:00  -1     1
User3     2019-12-01 09:00  -1     0
User3     2019-12-01 09:30  1      1
User3     2019-12-01 09:30  -1     0
*/

-- C3
/*
username  ts                grp
--------- ----------------- ----
User1     2019-12-01 08:00  1
User1     2019-12-01 09:30  1
User1     2019-12-01 10:00  2
User1     2019-12-01 12:30  2
User2     2019-12-01 08:00  1
User2     2019-12-01 10:30  1
User2     2019-12-01 11:00  2
User2     2019-12-01 11:30  2
User2     2019-12-01 11:32  3
User2     2019-12-01 12:00  3
User2     2019-12-01 12:04  4
User2     2019-12-01 12:30  4
User3     2019-12-01 08:00  1
User3     2019-12-01 09:00  1
User3     2019-12-01 09:30  2
User3     2019-12-01 09:30  2
*/

-- cleanup indexes
DROP INDEX IF EXISTS idx_user_start_id ON dbo.Sessions;
DROP INDEX IF EXISTS idx_user_end_id ON dbo.Sessions;

-- index for Solution 2 based on window functions
CREATE UNIQUE INDEX idx_user_start__end_id
  ON dbo.Sessions(username, starttime, endtime, id);

-- Listing 6-15: Solution 2 Based on Window Functions to Packing Intervals
WITH C1 AS
(
  SELECT *,
    CASE
      WHEN starttime <= 
        MAX(endtime) OVER(PARTITION BY username
                          ORDER BY starttime, endtime, id
                          ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
        THEN 0
        ELSE 1
      END AS isstart
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(isstart) OVER(PARTITION BY username
                      ORDER BY starttime, endtime, id
                      ROWS UNBOUNDED PRECEDING) AS grp
  FROM C1
)
SELECT username, MIN(starttime) AS starttime, max(endtime) AS endtime
FROM C2
GROUP BY username, grp;

-- C1
/*
id   username  starttime         endtime           isstart
---- --------- ----------------- ----------------- --------
1    User1     2019-12-01 08:00  2019-12-01 08:30  1
2    User1     2019-12-01 08:30  2019-12-01 09:00  0
3    User1     2019-12-01 09:00  2019-12-01 09:30  0
4    User1     2019-12-01 10:00  2019-12-01 11:00  1
5    User1     2019-12-01 10:30  2019-12-01 12:00  0
6    User1     2019-12-01 11:30  2019-12-01 12:30  0
7    User2     2019-12-01 08:00  2019-12-01 10:30  1
8    User2     2019-12-01 08:30  2019-12-01 10:00  0
9    User2     2019-12-01 09:00  2019-12-01 09:30  0
10   User2     2019-12-01 11:00  2019-12-01 11:30  1
11   User2     2019-12-01 11:32  2019-12-01 12:00  1
12   User2     2019-12-01 12:04  2019-12-01 12:30  1
14   User3     2019-12-01 08:00  2019-12-01 08:30  1
13   User3     2019-12-01 08:00  2019-12-01 09:00  0
15   User3     2019-12-01 08:30  2019-12-01 09:00  0
16   User3     2019-12-01 09:30  2019-12-01 09:30  1
*/

-- C2
/*
id   username  starttime         endtime           isstart  grp
---- --------- ----------------- ----------------- -------- ----
1    User1     2019-12-01 08:00  2019-12-01 08:30  1        1
2    User1     2019-12-01 08:30  2019-12-01 09:00  0        1
3    User1     2019-12-01 09:00  2019-12-01 09:30  0        1
4    User1     2019-12-01 10:00  2019-12-01 11:00  1        2
5    User1     2019-12-01 10:30  2019-12-01 12:00  0        2
6    User1     2019-12-01 11:30  2019-12-01 12:30  0        2
7    User2     2019-12-01 08:00  2019-12-01 10:30  1        1
8    User2     2019-12-01 08:30  2019-12-01 10:00  0        1
9    User2     2019-12-01 09:00  2019-12-01 09:30  0        1
10   User2     2019-12-01 11:00  2019-12-01 11:30  1        2
11   User2     2019-12-01 11:32  2019-12-01 12:00  1        3
12   User2     2019-12-01 12:04  2019-12-01 12:30  1        4
14   User3     2019-12-01 08:00  2019-12-01 08:30  1        1
13   User3     2019-12-01 08:00  2019-12-01 09:00  0        1
15   User3     2019-12-01 08:30  2019-12-01 09:00  0        1
16   User3     2019-12-01 09:30  2019-12-01 09:30  1        2
*/

----------------------------------------------------------------------
-- Gaps and Islands
----------------------------------------------------------------------

-- Listing 6-16: Code to Create and Populate Tables T1 and T2
SET NOCOUNT ON;
USE TSQLV5;

-- dbo.T1 (numeric sequence with unique values, interval: 1)
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

-- Gaps

-- desired results for numeric sequence
/*
rangestart  rangeend
----------- -----------
4           6
10          10
12          14
18          27
*/

-- desired results for temporal sequence
/*
rangestart rangeend
---------- ----------
2019-02-04 2019-02-06
2019-02-10 2019-02-10
2019-02-12 2019-02-14
2019-02-18 2019-02-27
*/

-- Numeric
WITH C AS
(
  SELECT col1 AS cur, LEAD(col1) OVER(ORDER BY col1) AS nxt
  FROM dbo.T1
)
SELECT cur + 1 AS rangestart, nxt - 1 AS rangeend
FROM C
WHERE nxt - cur > 1;

-- Temporal
WITH C AS
(
  SELECT col1 AS cur, LEAD(col1) OVER(ORDER BY col1) AS nxt
  FROM dbo.T2
)
SELECT DATEADD(day, 1, cur) AS rangestart, DATEADD(day, -1, nxt) rangeend
FROM C
WHERE DATEDIFF(day, cur, nxt) > 1;

-- Islands

-- desired results for numeric sequence
/*
start_range end_range
----------- -----------
2           3
7           9
11          11
15          17
28          28
*/

-- desired results for temporal sequence
/*
start_range end_range
----------- ----------
2019-02-02  2019-02-03
2019-02-07  2019-02-09
2019-02-11  2019-02-11
2019-02-15  2019-02-17
2019-02-28  2019-02-28
*/

-- Numeric

-- diff between col1 and dense rank
SELECT col1,
  DENSE_RANK() OVER(ORDER BY col1) AS drnk,
  col1 - DENSE_RANK() OVER(ORDER BY col1) AS diff
FROM dbo.T1;

/*
col1  drnk  diff
----- ----- -----
2     1     1
3     2     1
7     3     4
8     4     4
9     5     4
11    6     5
15    7     8
16    8     8
17    9     8
28    10    18
*/

WITH C AS
(
  SELECT col1, col1 - DENSE_RANK() OVER(ORDER BY col1) AS grp
  FROM dbo.T1
)
SELECT MIN(col1) AS start_range, MAX(col1) AS end_range
FROM C
GROUP BY grp;

-- Temporal
WITH C AS
(
  SELECT col1, DATEADD(day, -1 * DENSE_RANK() OVER(ORDER BY col1), col1) AS grp
  FROM dbo.T2
)
SELECT MIN(col1) AS start_range, MAX(col1) AS end_range
FROM C
GROUP BY grp;

-- ignore gaps of up to 2 days

-- desired results
/*
rangestart rangeend
---------- ----------
2019-02-02 2019-02-03
2019-02-15 2019-02-17
2019-02-28 2019-02-28
2019-02-07 2019-02-11
*/

WITH C1 AS
(
  SELECT col1,
    CASE
      WHEN DATEDIFF(day, LAG(col1) OVER(ORDER BY col1), col1) <= 2
        THEN 0
      ELSE 1
    END AS isstart
  FROM dbo.T2
),
C2 AS
(
  SELECT *,
    SUM(isstart) OVER(ORDER BY col1 ROWS UNBOUNDED PRECEDING) AS grp
  FROM C1
)
SELECT MIN(col1) AS rangestart, MAX(col1) AS rangeend
FROM C2
GROUP BY grp;

-- variation of islands problem
DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
  id  INT         NOT NULL PRIMARY KEY,
  val VARCHAR(10) NOT NULL
);
GO

INSERT INTO dbo.T1(id, val) VALUES
  (2, 'a'),
  (3, 'a'),
  (5, 'a'),
  (7, 'b'),
  (11, 'b'),
  (13, 'a'),
  (17, 'a'),
  (19, 'a'),
  (23, 'c'),
  (29, 'c'),
  (31, 'a'),
  (37, 'a'),
  (41, 'a'),
  (43, 'a'),
  (47, 'c'),
  (53, 'c'),
  (59, 'c');

-- desired results
/*
rangestart  rangeend    val
----------- ----------- ----------
2           5           a
7           11          b
13          19          a
23          29          c
31          43          a
47          59          c
*/

-- computing island identifier per val
WITH C1 AS
(
  SELECT id, val, CASE WHEN val = LAG(val) OVER(ORDER BY id) THEN 0 ELSE 1 END
    AS isstart
  FROM dbo.T1
),
C2 AS
(
  SELECT *,
    SUM(isstart) OVER(ORDER BY id ROWS UNBOUNDED PRECEDING) AS grp
  FROM C1
)
SELECT MIN(id) AS rangestart, MAX(id) AS rangeend, val
FROM C2
GROUP BY grp, val;

----------------------------------------------------------------------
-- Median
----------------------------------------------------------------------

-- desired results
/*
testid     median
---------- -------
Test ABC   75
Test XYZ   77.5
*/

-- solution using PERCENTILE_CONT
SELECT DISTINCT testid,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY score) OVER(PARTITION BY testid) AS median
FROM Stats.Scores;

-- solution using ROW_NUMBER and COUNT
WITH C AS
(
  SELECT testid, score,
    ROW_NUMBER() OVER(PARTITION BY testid ORDER BY score) AS pos,
    COUNT(*) OVER(PARTITION BY testid) AS cnt
  FROM Stats.Scores
)
SELECT testid, AVG(1. * score) AS median
FROM C
WHERE pos IN( (cnt + 1) / 2, (cnt + 2) / 2 )
GROUP BY testid;

-- solution using two ROW_NUMBER functions

-- step 1: compute row numbers
SELECT testid, score,
  ROW_NUMBER() OVER(PARTITION BY testid ORDER BY score, studentid) AS rna,
  ROW_NUMBER() OVER(PARTITION BY testid ORDER BY score DESC, studentid DESC)
    AS rnd
FROM Stats.Scores;

/*
testid     score rna  rnd
---------- ----- ---- ----
Test ABC   95    9    1
Test ABC   95    8    2
Test ABC   80    7    3
Test ABC   80    6    4
Test ABC   75    5    5
Test ABC   65    4    6
Test ABC   55    3    7
Test ABC   55    2    8
Test ABC   50    1    9
Test XYZ   95    10   1
Test XYZ   95    9    2
Test XYZ   95    8    3
Test XYZ   80    7    4
Test XYZ   80    6    5
Test XYZ   75    5    6
Test XYZ   65    4    7
Test XYZ   55    3    8
Test XYZ   55    2    9
Test XYZ   50    1    10
*/

-- complete solution
WITH C AS
(
  SELECT testid, score,
    ROW_NUMBER() OVER(PARTITION BY testid ORDER BY score, studentid) AS rna,
    ROW_NUMBER() OVER(PARTITION BY testid ORDER BY score DESC, studentid DESC)
      AS rnd
  FROM Stats.Scores
)
SELECT testid, AVG(1. * score) AS median
FROM C
WHERE ABS(rna - rnd) <= 1
GROUP BY testid;

-- solution with APPLY and OFFSET-FETCH
WITH C AS
(
  SELECT testid, (COUNT(*) - 1) / 2 AS ov, 2 - COUNT(*) % 2 AS fv
  FROM Stats.Scores
  GROUP BY testid
)
SELECT C.testid, AVG(1. * A.score) AS median
FROM C CROSS APPLY ( SELECT S.score
                     FROM Stats.Scores AS S
                     WHERE S.testid = C.testid
                     ORDER BY S.score
                     OFFSET C.ov ROWS FETCH NEXT C.fv ROWS ONLY ) AS A
GROUP BY C.testid;

----------------------------------------------------------------------
-- Conditional Aggregate
----------------------------------------------------------------------

USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO

CREATE TABLE dbo.T1
(
  ordcol  INT NOT NULL PRIMARY KEY,
  datacol INT NOT NULL
);

INSERT INTO dbo.T1 VALUES
  (1,   10),
  (4,  -15),
  (5,    5),
  (6,  -10),
  (8,  -15),
  (10,  20),
  (17,  10),
  (18, -10),
  (20, -30),
  (31,  20); 

-- calculate a non-negative sum of datacol based on ordcol ordering (courtacy of gordon linoff)
-- unsupported

-- desired results
/*
ordcol      datacol     nonnegativesum replenish
----------- ----------- -------------- -----------
1           10          10             0
4           -15         0              5
5           5           5              0
6           -10         0              5
8           -15         0              15
10          20          20             0
17          10          30             0
18          -10         20             0
20          -30         0              10
31          20          20             0
*/

-- Listing 6-17: Solution for Nonnegative Running Sum Task
WITH C1 AS
(
  SELECT ordcol, datacol,
    SUM(datacol) OVER (ORDER BY ordcol
                       ROWS UNBOUNDED PRECEDING) AS partsum
  FROM dbo.T1
),
C2 AS
(
  SELECT *,
    MIN(partsum) OVER (ORDER BY ordcol
                       ROWS UNBOUNDED PRECEDING) as mn
  FROM C1
)
SELECT ordcol, datacol, partsum, adjust,
  partsum + adjust AS nonnegativesum,
  adjust - LAG(adjust, 1, 0) OVER(ORDER BY ordcol) AS replenish
FROM C2
  CROSS APPLY(VALUES(CASE WHEN mn < 0 THEN -mn ELSE 0 END)) AS A(adjust);

/*
ordcol  datacol  partsum  adjust  nonnegativesum replenish
------- -------- -------- ------- -------------- ----------
1       10       10       0       10             0
4       -15      -5       5       0              5
5       5        0        5       5              0
6       -10      -10      10      0              5
8       -15      -25      25      0              15
10      20       -5       25      20             0
17      10       5        25      30             0
18      -10      -5       25      20             0
20      -30      -35      35      0              10
31      20       -15      35      20             0
*/

----------------------------------------------------------------------
-- Used with Hierarchical Data
----------------------------------------------------------------------

-- Listing 6-18: Code to Create and Populate the Employees Table
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Employees;
GO
CREATE TABLE dbo.Employees
(
  empid   INT         NOT NULL
    CONSTRAINT PK_Employees PRIMARY KEY,
  mgrid   INT         NULL
    CONSTRAINT FK_Employees_mgr_emp REFERENCES dbo.Employees,
  empname VARCHAR(25) NOT NULL,
  salary  MONEY       NOT NULL,
  CHECK (empid <> mgrid)
);

INSERT INTO dbo.Employees(empid, mgrid, empname, salary) VALUES
  (1,  NULL, 'David'  , $10000.00),
  (2,  1,    'Eitan'  ,  $7000.00),
  (3,  1,    'Ina'    ,  $7500.00),
  (4,  2,    'Seraph' ,  $5000.00),
  (5,  2,    'Jiru'   ,  $5500.00),
  (6,  2,    'Steve'  ,  $4500.00),
  (7,  3,    'Aaron'  ,  $5000.00),
  (8,  5,    'Lilach' ,  $3500.00),
  (9,  7,    'Rita'   ,  $3000.00),
  (10, 5,    'Sean'   ,  $3000.00),
  (11, 7,    'Gabriel',  $3000.00),
  (12, 9,    'Emilia' ,  $2000.00),
  (13, 9,    'Michael',  $2000.00),
  (14, 9,    'Didi'   ,  $1500.00);

CREATE UNIQUE INDEX idx_unc_mgrid_empid ON dbo.Employees(mgrid, empid);
GO

-- sorting hierarchy by empname

-- row numbers ordered by empname
WITH EmpsRN AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY mgrid ORDER BY empname, empid) AS n
  FROM dbo.Employees
)
SELECT * FROM EmpsRN;

/*
empid  mgrid  empname  salary    n
------ ------ -------- --------- ---
1      NULL   David    10000.00  1
2      1      Eitan    7000.00   1
3      1      Ina      7500.00   2
5      2      Jiru     5500.00   1
4      2      Seraph   5000.00   2
6      2      Steve    4500.00   3
7      3      Aaron    5000.00   1
8      5      Lilach   3500.00   1
10     5      Sean     3000.00   2
11     7      Gabriel  3000.00   1
9      7      Rita     3000.00   2
14     9      Didi     1500.00   1
12     9      Emilia   2000.00   2
13     9      Michael  2000.00   3
*/

-- Listing 6-19: Code Computing sortpath and lvl
WITH EmpsRN AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY mgrid ORDER BY empname, empid) AS n
  FROM dbo.Employees
),
EmpsPath
AS
(
  SELECT empid, empname, salary, 0 AS lvl,
    CAST(0x AS VARBINARY(MAX)) AS sortpath
  FROM dbo.Employees
  WHERE mgrid IS NULL

  UNION ALL

  SELECT C.empid, C.empname, C.salary, P.lvl + 1,
    P.sortpath + CAST(n AS BINARY(2)) AS sortpath
  FROM EmpsPath AS P
    INNER JOIN EmpsRN AS C
      ON C.mgrid = P.empid
)
SELECT *
FROM EmpsPath;

/*
empid  empname  salary    lvl  sortpath
------ -------- --------- ---- -------------------
1      David    10000.00  0    0x
2      Eitan    7000.00   1    0x0001
3      Ina      7500.00   1    0x0002
7      Aaron    5000.00   2    0x00020001
11     Gabriel  3000.00   3    0x000200010001
9      Rita     3000.00   3    0x000200010002
14     Didi     1500.00   4    0x0002000100020001
12     Emilia   2000.00   4    0x0002000100020002
13     Michael  2000.00   4    0x0002000100020003
5      Jiru     5500.00   2    0x00010001
4      Seraph   5000.00   2    0x00010002
6      Steve    4500.00   2    0x00010003
8      Lilach   3500.00   3    0x000100010001
10     Sean     3000.00   3    0x000100010002
*/

-- Listing 6-20: Sorting Employee Hierarchy, with Siblings Sorted by empname
WITH EmpsRN AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY mgrid ORDER BY empname, empid) AS n
  FROM dbo.Employees
),
EmpsPath
AS
(
  SELECT empid, empname, salary, 0 AS lvl,
    CAST(0x AS VARBINARY(MAX)) AS sortpath
  FROM dbo.Employees
  WHERE mgrid IS NULL

  UNION ALL

  SELECT C.empid, C.empname, C.salary, P.lvl + 1,
    P.sortpath + CAST(n AS BINARY(2)) AS sortpath
  FROM EmpsPath AS P
    INNER JOIN EmpsRN AS C
      ON C.mgrid = P.empid
)
SELECT empid, salary, REPLICATE(' | ', lvl) + empname AS empname
FROM EmpsPath
ORDER BY sortpath;

/*
empid       salary                empname
----------- --------------------- --------------------
1           10000.00              David
2           7000.00                | Eitan
5           5500.00                |  | Jiru
8           3500.00                |  |  | Lilach
10          3000.00                |  |  | Sean
4           5000.00                |  | Seraph
6           4500.00                |  | Steve
3           7500.00                | Ina
7           5000.00                |  | Aaron
11          3000.00                |  |  | Gabriel
9           3000.00                |  |  | Rita
14          1500.00                |  |  |  | Didi
12          2000.00                |  |  |  | Emilia
13          2000.00                |  |  |  | Michael
*/

-- Listing 6-21: Sorting Employee Hierarchy, with Siblings Sorted by salary
WITH EmpsRN AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY mgrid ORDER BY salary, empid) AS n
  FROM dbo.Employees
),
EmpsPath
AS
(
  SELECT empid, empname, salary, 0 AS lvl,
    CAST(0x AS VARBINARY(MAX)) AS sortpath
  FROM dbo.Employees
  WHERE mgrid IS NULL

  UNION ALL

  SELECT C.empid, C.empname, C.salary, P.lvl + 1,
    P.sortpath + CAST(n AS BINARY(2)) AS sortpath
  FROM EmpsPath AS P
    INNER JOIN EmpsRN AS C
      ON C.mgrid = P.empid
)
SELECT empid, salary, REPLICATE(' | ', lvl) + empname AS empname
FROM EmpsPath
ORDER BY sortpath;

/*
empid       salary                empname
----------- --------------------- --------------------
1           10000.00              David
2           7000.00                | Eitan
6           4500.00                |  | Steve
4           5000.00                |  | Seraph
5           5500.00                |  | Jiru
10          3000.00                |  |  | Sean
8           3500.00                |  |  | Lilach
3           7500.00                | Ina
7           5000.00                |  | Aaron
9           3000.00                |  |  | Rita
14          1500.00                |  |  |  | Didi
12          2000.00                |  |  |  | Emilia
13          2000.00                |  |  |  | Michael
11          3000.00                |  |  | Gabriel
*/
