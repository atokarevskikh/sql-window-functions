----------------------------------------------------------------------
-- T-SQL Window Functions Second Edition
-- Chapter 01 - SQL Windowing
-- © Itzik Ben-Gan
----------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQLV5;

----------------------------------------------------------------------
-- Background to window functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Window Functions, Described
----------------------------------------------------------------------

USE TSQLV5;

SELECT orderid, orderdate, val,
  RANK() OVER(ORDER BY val DESC) AS rnk
FROM Sales.OrderValues
ORDER BY rnk;

/*
orderid  orderdate  val       rnk
-------- ---------- --------- ----
10865    2019-02-02 16387.50  1
10981    2019-03-27 15810.00  2
11030    2019-04-17 12615.05  3
10889    2019-02-16 11380.00  4
10417    2018-01-16 11188.40  5
10817    2019-01-06 10952.85  6
10897    2019-02-19 10835.24  7
10479    2018-03-19 10495.60  8
10540    2018-05-19 10191.70  9
10691    2018-10-03 10164.80  10
...
*/

----------------------------------------------------------------------
-- Set-Based vs. Cursor Programming
----------------------------------------------------------------------

SELECT orderid, orderdate, val,
  RANK() OVER(ORDER BY val DESC) AS rnk
FROM Sales.OrderValues;

/*
orderid  orderdate  val       rnk
-------- ---------- --------- ----
10865    2019-02-02 16387.50  1
10981    2019-03-27 15810.00  2
11030    2019-04-17 12615.05  3
10889    2019-02-16 11380.00  4
10417    2018-01-16 11188.40  5
...
*/

----------------------------------------------------------------------
-- Drawbacks of alternatives to windows
----------------------------------------------------------------------

-- Listing 1-1: Mixing detail and the result of a grouped query
WITH Aggregates AS
(
  SELECT custid, SUM(val) AS sumval, AVG(val) AS avgval
  FROM Sales.OrderValues
  GROUP BY custid
)
SELECT O.orderid, O.custid, O.val,
  CAST(100. * O.val / A.sumval AS NUMERIC(5, 2)) AS pctcust,
  O.val - A.avgval AS diffcust
FROM Sales.OrderValues AS O
  INNER JOIN Aggregates AS A
    ON O.custid = A.custid;

/*
orderid  custid  val     pctcust  diffcust
-------- ------- ------- -------- ------------
10835    1       845.80  19.79    133.633334
10952    1       471.20  11.03    -240.966666
10643    1       814.50  19.06    102.333334
10692    1       878.00  20.55    165.833334
11011    1       933.50  21.85    221.333334
10702    1       330.00  7.72     -382.166666
10625    2       479.75  34.20    129.012500
10759    2       320.00  22.81    -30.737500
10308    2       88.80   6.33     -261.937500
10926    2       514.40  36.67    163.662500
...
*/

-- Listing 1-2: Mixing detail and the results of two grouped queries
WITH CustAggregates AS
(
  SELECT custid, SUM(val) AS sumval, AVG(val) AS avgval
  FROM Sales.OrderValues
  GROUP BY custid
),
GrandAggregates AS
(
  SELECT SUM(val) AS sumval, AVG(val) AS avgval
  FROM Sales.OrderValues
)
SELECT O.orderid, O.custid, O.val,
  CAST(100. * O.val / CA.sumval AS NUMERIC(5, 2)) AS pctcust,
  O.val - CA.avgval AS diffcust,
  CAST(100. * O.val / GA.sumval AS NUMERIC(5, 2)) AS pctall,
  O.val - GA.avgval AS diffall
FROM Sales.OrderValues AS O
  INNER JOIN CustAggregates AS CA
    ON O.custid = CA.custid
  CROSS JOIN GrandAggregates AS GA;

/*
orderid  custid  val     pctcust  diffcust     pctall  diffall
-------- ------- ------- -------- ------------ ------- -------------
10835    1       845.80  19.79    133.633334   0.07    -679.252072
10952    1       471.20  11.03    -240.966666  0.04    -1053.852072
10643    1       814.50  19.06    102.333334   0.06    -710.552072
10692    1       878.00  20.55    165.833334   0.07    -647.052072
11011    1       933.50  21.85    221.333334   0.07    -591.552072
10702    1       330.00  7.72     -382.166666  0.03    -1195.052072
10625    2       479.75  34.20    129.012500   0.04    -1045.302072
10759    2       320.00  22.81    -30.737500   0.03    -1205.052072
10308    2       88.80   6.33     -261.937500  0.01    -1436.252072
10926    2       514.40  36.67    163.662500   0.04    -1010.652072
...
*/

-- Listing 1-3: Mixing detail and the results of scalar aggregate subqueries
-- subqueries, detail and customer aggregates
SELECT orderid, custid, val,
  CAST(100. * val /
        (SELECT SUM(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid) AS NUMERIC(5, 2)) AS pctcust,
  val - (SELECT AVG(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid) AS diffcust
FROM Sales.OrderValues AS O1;

-- subqueries, detail, customer and grand aggregates
SELECT orderid, custid, val,
  CAST(100. * val /
        (SELECT SUM(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid) AS NUMERIC(5, 2)) AS pctcust,
  val - (SELECT AVG(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid) AS diffcust,
  CAST(100. * val /
        (SELECT SUM(O2.val)
         FROM Sales.OrderValues AS O2) AS NUMERIC(5, 2)) AS pctall,
  val - (SELECT AVG(O2.val)
         FROM Sales.OrderValues AS O2) AS diffall
FROM Sales.OrderValues AS O1;

-- window functions, detail and cust aggregates
SELECT orderid, custid, val,
  CAST(100. * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust,
  val - AVG(val) OVER(PARTITION BY custid) AS diffcust
FROM Sales.OrderValues;

-- window functions, detail, cust and grand aggregates
SELECT orderid, custid, val,
  CAST(100. * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust,
  val - AVG(val) OVER(PARTITION BY custid) AS diffcust,
  CAST(100. * val / SUM(val) OVER() AS NUMERIC(5, 2)) AS pctall,
  val - AVG(val) OVER() AS diffall
FROM Sales.OrderValues;

-- window functions operate on the result of the query
SELECT orderid, custid, val,
  CAST(100. * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust,
  val - AVG(val) OVER(PARTITION BY custid) AS diffcust,
  CAST(100. * val / SUM(val) OVER() AS NUMERIC(5, 2)) AS pctall,
  val - AVG(val) OVER() AS diffall
FROM Sales.OrderValues
WHERE orderdate >= '20180101'
  AND orderdate < '20190101';

-- Listing 1-4: Repeating filter in all subqueries
SELECT orderid, custid, val,
  CAST(100. * val /
        (SELECT SUM(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid
           AND orderdate >= '20180101'
           AND orderdate < '20190101') AS NUMERIC(5, 2)) AS pctcust,
  val - (SELECT AVG(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE O2.custid = O1.custid
           AND orderdate >= '20180101'
           AND orderdate < '20190101') AS diffcust,
  CAST(100. * val /
        (SELECT SUM(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE orderdate >= '20180101'
           AND orderdate < '20190101') AS NUMERIC(5, 2)) AS pctall,
  val - (SELECT AVG(O2.val)
         FROM Sales.OrderValues AS O2
         WHERE orderdate >= '20180101'
           AND orderdate < '20190101') AS diffall
FROM Sales.OrderValues AS O1
WHERE orderdate >= '20180101'
  AND orderdate < '20190101';

----------------------------------------------------------------------
-- Glimpse to Solutions using Window Functions
----------------------------------------------------------------------

-- sample data for islands problem
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO

CREATE TABLE dbo.T1
(
  col1 INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY
);

INSERT INTO dbo.T1(col1) 
  VALUES(2),(3),(11),(12),(13),(27),(33),(34),(35),(42);
GO

/*
startrange  endrange
----------- -----------
2           3
11          13
27          27
33          35
42          42
*/

-- T1.col1 sequence values and a group identifier
/*
col1  grp
----- ---
2     a
3     a
11    b
12    b
13    b
27    c
33    d
34    d
35    d
42    e
*/

-- calculating group identifier using traditional query elements
SELECT col1,
  (SELECT MIN(B.col1)
    FROM dbo.T1 AS B
    WHERE B.col1 >= A.col1
      -- is this row the last in its group?
      AND NOT EXISTS
        (SELECT *
         FROM dbo.T1 AS C
         WHERE C.col1 = B.col1 + 1)) AS grp
FROM dbo.T1 AS A;

/*
col1        grp
----------- -----------
2           3
3           3
11          13
12          13
13          13
27          27
33          35
34          35
35          35
42          42
*/
-- final solution using traditional query elements
SELECT MIN(col1) AS startrange, MAX(col1) AS endrange
FROM (SELECT col1,
        (SELECT MIN(B.col1)
         FROM dbo.T1 AS B
         WHERE B.col1 >= A.col1
           AND NOT EXISTS
             (SELECT *
              FROM dbo.T1 AS C
              WHERE C.col1 = B.col1 + 1)) AS grp
      FROM dbo.T1 AS A) AS D
GROUP BY grp;

-- row numbers based on col1 ordering
SELECT col1, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
FROM dbo.T1;

/*
col1        rownum
----------- --------------------
2           1
3           2
11          3
12          4
13          5
27          6
33          7
34          8
35          9
42          10
*/

-- difference between col1 and row number
SELECT col1, col1 - ROW_NUMBER() OVER(ORDER BY col1) AS diff
FROM dbo.T1;

/*
col1        diff
----------- --------------------
2           1
3           1
11          8
12          8
13          8
27          21
33          26
34          26
35          26
42          32
*/

-- final solution using window functions
WITH C AS
(
  SELECT col1,
    -- the difference is constant and unique per island
    col1 - ROW_NUMBER() OVER(ORDER BY col1) AS grp
  FROM dbo.T1
)
SELECT MIN(col1) AS startrange, MAX(col1) AS endrange
FROM C
GROUP BY grp;

----------------------------------------------------------------------
-- Elements of window functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Window Partitioning
----------------------------------------------------------------------

-- Listing 1-5: Query with Two RANK Calculations
SELECT custid, orderid, val,
  RANK() OVER(ORDER BY val DESC) AS rnkall,
  RANK() OVER(PARTITION BY custid
              ORDER BY val DESC) AS rnkcust
FROM Sales.OrderValues;

----------------------------------------------------------------------
-- Window Ordering
----------------------------------------------------------------------

SELECT custid, orderid, val,
  RANK() OVER(ORDER BY val DESC) AS rnkall,
  RANK() OVER(PARTITION BY custid
              ORDER BY val DESC) AS rnkcust
FROM Sales.OrderValues;

-- unsupported NULLS LAST option
/*
SELECT orderid, shippeddate
FROM Sales.Orders
ORDER BY shippeddate NULLS LAST;
*/

-- supported alternative
SELECT orderid, shippeddate
FROM Sales.Orders
ORDER BY
  CASE WHEN shippeddate IS NOT NULL THEN 1 ELSE 2 END,
  shippeddate;

/*
orderid     shippeddate
----------- -----------
10249       2017-07-10
10252       2017-07-11
10250       2017-07-12
10251       2017-07-15
10255       2017-07-15
...
11050       2019-05-05
11055       2019-05-05
11063       2019-05-06
11067       2019-05-06
11069       2019-05-06
11008       NULL
11019       NULL
11039       NULL
11040       NULL
...
*/

----------------------------------------------------------------------
-- Window Framing
----------------------------------------------------------------------

SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runqty
FROM Sales.EmpOrders;

/*
empid  ordermonth qty  runqty
------ ---------- ---- -------
1      2017-07-01 121  121
1      2017-08-01 247  368
1      2017-09-01 255  623
1      2017-10-01 143  766
1      2017-11-01 318  1084
...
2      2017-07-01 50   50
2      2017-08-01 94   144
2      2017-09-01 137  281
2      2017-10-01 248  529
2      2017-11-01 237  766
...
*/

----------------------------------------------------------------------
-- Query Elements Supporting Window Functions
----------------------------------------------------------------------

-- sample data for ambiguity example
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO

CREATE TABLE dbo.T1
(
  col1 VARCHAR(10) NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY
);

INSERT INTO dbo.T1(col1) 
  VALUES('A'),('B'),('C'),('D'),('E'),('F');
GO

/*
-- query 1 for ambiguity example
SELECT col1
FROM dbo.T1
WHERE col1 > 'B'
  AND ROW_NUMBER() OVER(ORDER BY col1) <= 3;

-- query 2 for ambiguity example
SELECT col1
FROM dbo.T1
WHERE ROW_NUMBER() OVER(ORDER BY col1) <= 3
  AND col1 > 'B';
*/

-- evaluating expressions before removing duplicates

-- query 1
SELECT empid, country
FROM HR.Employees;

/*
empid       country
----------- ---------------
1           USA
2           USA
3           USA
4           USA
5           UK
6           UK
7           UK
8           USA
9           UK
*/

-- query 2
SELECT DISTINCT country, ROW_NUMBER() OVER(ORDER BY country) AS rownum
FROM HR.Employees;

/*
country  rownum
-------- -------
UK       1
UK       2
UK       3
UK       4
USA      5
USA      6
USA      7
USA      8
USA      9
*/

-- query 3
WITH EmpCountries AS
(
  SELECT DISTINCT country FROM HR.Employees
)
SELECT country, ROW_NUMBER() OVER(ORDER BY country) AS rownum
FROM EmpCountries;

/*
country  rownum
-------- -------
UK       1
USA      2
*/

-- window functions operate on the result of the query
SELECT O.empid,
  SUM(OD.qty) AS qty,
  RANK() OVER(ORDER BY SUM(OD.qty) DESC) AS rnk
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE O.orderdate >= '20180101'
  AND O.orderdate < '20190101'
GROUP BY O.empid;

/*
empid  qty   rnk
------ ----- ----
4      5273  1
3      4436  2
1      3877  3
8      2843  4
2      2604  5
7      2292  6
6      1738  7
5      1471  8
9      955   9
*/

-- simpler solution for assigning row numbers to distinct employee countries
SELECT country, ROW_NUMBER() OVER(ORDER BY country) AS rownum
FROM HR.Employees
GROUP BY country;

/*
country  rownum
-------- -------
UK       1
USA      2
*/

----------------------------------------------------------------------
-- Circumventing Limitation
----------------------------------------------------------------------

-- SELECT WHERE
WITH C AS
(
  SELECT orderid, orderdate, val,
    RANK() OVER(ORDER BY val DESC) AS rnk
  FROM Sales.OrderValues
)
SELECT *
FROM C
WHERE rnk <= 5;

/*
orderid  orderdate  val       rnk
-------- ---------- --------- ----
10865    2019-02-02 16387.50  1
10981    2019-03-27 15810.00  2
11030    2019-04-17 12615.05  3
10889    2019-02-16 11380.00  4
10417    2018-01-16 11188.40  5
*/

-- UPDATE SET

-- sample data for UPDATE with window functions
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO

CREATE TABLE dbo.T1
(
  col1 INT NULL,
  col2 VARCHAR(10) NOT NULL
);

INSERT INTO dbo.T1(col2) 
  VALUES('C'),('A'),('B'),('A'),('C'),('B');
GO

/*
UPDATE dbo.T1
  SET col1 = ROW_NUMBER() OVER(ORDER BY col2);
*/

-- UPDATE with window functions
WITH C AS
(
  SELECT col1, col2,
    ROW_NUMBER() OVER(ORDER BY col2) AS rownum
  FROM dbo.T1
)
UPDATE C
  SET col1 = rownum;

SELECT col1, col2
FROM dbo.T1;

/*
col1  col2
----- -----
5     C
1     A
3     B
2     A
6     C
4     B
*/
GO

----------------------------------------------------------------------
-- Suggestion to Add Filter
----------------------------------------------------------------------

/*
SELECT orderid, orderdate, val
FROM Sales.OrderValues
QUALIFY RANK() OVER(ORDER BY val DESC) <= 5;

SELECT orderid, orderdate, val,
  RANK() OVER(ORDER BY val DESC) AS rnk
FROM Sales.OrderValues
QUALIFY rnk <= 5;
*/

----------------------------------------------------------------------
-- Reuse of Window Definitions
----------------------------------------------------------------------

-- query without WINDOW clause
SELECT empid, ordermonth, qty,
  SUM(qty) OVER (PARTITION BY empid
                 ORDER BY ordermonth
                 ROWS BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS runsumqty,
  AVG(qty) OVER (PARTITION BY empid
                 ORDER BY ordermonth
                 ROWS BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS runavgqty,
  MIN(qty) OVER (PARTITION BY empid
                 ORDER BY ordermonth
                 ROWS BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS runminqty,
  MAX(qty) OVER (PARTITION BY empid
                 ORDER BY ordermonth
                 ROWS BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS runmaxqty
FROM Sales.EmpOrders;

-- query with WINDOW clause
/*
SELECT empid, ordermonth, qty,
  SUM(qty) OVER W1 AS runsumqty,
  AVG(qty) OVER W1 AS runavgqty,
  MIN(qty) OVER W1 AS runminqty,
  MAX(qty) OVER W1 AS runmaxqty
FROM Sales.EmpOrders
WINDOW W1 AS ( PARTITION BY empid
               ORDER BY ordermonth
               ROWS BETWEEN UNBOUNDED PRECEDING
                        AND CURRENT ROW );
*/