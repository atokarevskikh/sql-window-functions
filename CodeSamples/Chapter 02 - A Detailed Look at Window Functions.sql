----------------------------------------------------------------------
-- T-SQL Window Functions Second Edition
-- Chapter 02 - A Detailed Look at Window Functions
-- © Itzik Ben-Gan
----------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQLV5;

----------------------------------------------------------------------
-- Window Functions Breakdown
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Window Aggregate Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Window Aggregate Functions, Described
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Partitioning
----------------------------------------------------------------------

-- default and explicit partitioning
USE TSQLV5;

SELECT orderid, custid, val,
  SUM(val) OVER() AS sumall,
  SUM(val) OVER(PARTITION BY custid) AS sumcust
FROM Sales.OrderValues AS O1;

/*
orderid  custid  val     sumall      sumcust
-------- ------- ------- ----------- --------
10643    1       814.50  1265793.22  4273.00
10692    1       878.00  1265793.22  4273.00
10702    1       330.00  1265793.22  4273.00
10835    1       845.80  1265793.22  4273.00
10952    1       471.20  1265793.22  4273.00
11011    1       933.50  1265793.22  4273.00
10926    2       514.40  1265793.22  1402.95
10759    2       320.00  1265793.22  1402.95
10625    2       479.75  1265793.22  1402.95
10308    2       88.80   1265793.22  1402.95
...
*/

-- expressions involving base elements and window functions
SELECT orderid, custid, val,
  CAST(100. * val / SUM(val) OVER() AS NUMERIC(5, 2)) AS pctall,
  CAST(100. * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust
FROM Sales.OrderValues AS O1;

/*
orderid  custid  val     pctall  pctcust
-------- ------- ------- ------- --------
10643    1       814.50  0.06    19.06
10692    1       878.00  0.07    20.55
10702    1       330.00  0.03    7.72
10835    1       845.80  0.07    19.79
10952    1       471.20  0.04    11.03
11011    1       933.50  0.07    21.85
10926    2       514.40  0.04    36.67
10759    2       320.00  0.03    22.81
10625    2       479.75  0.04    34.20
10308    2       88.80   0.01    6.33
...
*/

----------------------------------------------------------------------
-- Framing
----------------------------------------------------------------------

----------------------------------------------------------------------
-- ROWS
----------------------------------------------------------------------

-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runqty
FROM Sales.EmpOrders;

/*
empid  ordermonth  qty  runqty
------ ----------- ---- -------
1      2017-07-01  121  121
1      2017-08-01  247  368
1      2017-09-01  255  623
1      2017-10-01  143  766
1      2017-11-01  318  1084
...                
2      2017-07-01  50   50
2      2017-08-01  94   144
2      2017-09-01  137  281
2      2017-10-01  248  529
2      2017-11-01  237  766
...
*/

-- more concise alternative
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS UNBOUNDED PRECEDING) AS runqty
FROM Sales.EmpOrders;

-- ROWS BETWEEN <n> PRECEDING AND <n> FOLLOWING
SELECT empid, ordermonth, 
  MAX(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN 1 PRECEDING
                         AND 1 PRECEDING) AS prvqty,
  qty AS curqty,
  MAX(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN 1 FOLLOWING
                         AND 1 FOLLOWING) AS nxtqty,
  AVG(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN 1 PRECEDING
                         AND 1 FOLLOWING) AS avgqty
FROM Sales.EmpOrders;

/*
empid  ordermonth  prvqty  curqty  nxtqty  avgqty
------ ----------- ------- ------- ------- -------
1      2017-07-01  NULL    121     247     184
1      2017-08-01  121     247     255     207
1      2017-09-01  247     255     143     215
1      2017-10-01  255     143     318     238
1      2017-11-01  143     318     536     332
...
1      2019-01-01  583     397     566     515
1      2019-02-01  397     566     467     476
1      2019-03-01  566     467     586     539
1      2019-04-01  467     586     299     450
1      2019-05-01  586     299     NULL    442
...
*/

-- determinism

-- Listing 2-1: DDL and Sample Data for T1
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1
(
  keycol INT         NOT NULL CONSTRAINT PK_T1 PRIMARY KEY,
  col1   VARCHAR(10) NOT NULL
);

INSERT INTO dbo.T1 VALUES
  (2, 'A'),(3, 'A'),
  (5, 'B'),(7, 'B'),(11, 'B'),
  (13, 'C'),(17, 'C'),(19, 'C'),(23, 'C');

-- nondeterministic query using the ROWS option

/*
-- try running the query before and after creating the following index
CREATE UNIQUE INDEX idx_col1D_keycol ON dbo.T1(col1 DESC, keycol);
*/

SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS cnt
FROM dbo.T1;

/*
-- before
keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          2
5           B          3
7           B          4
11          B          5
13          C          6
17          C          7
19          C          8
23          C          9
*/

/*
-- after
keycol      col1       cnt
----------- ---------- -----------
3           A          1
2           A          2
11          B          3
7           B          4
5           B          5
23          C          6
19          C          7
17          C          8
13          C          9
*/

SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1, keycol
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS cnt
FROM dbo.T1;

/*
keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          2
5           B          3
7           B          4
11          B          5
13          C          6
17          C          7
19          C          8
23          C          9
*/

----------------------------------------------------------------------
-- GROUPS
----------------------------------------------------------------------

-- return per order the number of orders placed in the last three days of activity
/*
SELECT orderid, orderdate,
  COUNT(*) OVER(ORDER BY orderdate
                GROUPS BETWEEN 2 PRECEDING
                           AND CURRENT ROW) AS numordersinlast3days
FROM Sales.Orders;
*/

/*
orderid  orderdate  numordersinlast3days
-------- ---------- --------------------
10248    2017-07-04 1
10249    2017-07-05 2
10250    2017-07-08 4
10251    2017-07-08 4
10252    2017-07-09 4
10253    2017-07-10 4
10254    2017-07-11 3
10255    2017-07-12 3
10256    2017-07-15 3
10257    2017-07-16 3
...
11067    2019-05-04 10
11068    2019-05-04 10
11069    2019-05-04 10
11070    2019-05-05 10
11071    2019-05-05 10
11072    2019-05-05 10
11073    2019-05-05 10
11074    2019-05-06 11
11075    2019-05-06 11
11076    2019-05-06 11
11077    2019-05-06 11
*/

-- workaround in SQL Server
WITH C AS
(
  SELECT orderdate,
    SUM(COUNT(*))
      OVER(ORDER BY orderdate
           ROWS BETWEEN 2 PRECEDING
                    AND CURRENT ROW) AS numordersinlast3days
  FROM Sales.Orders
  GROUP BY orderdate
)
SELECT O.orderid, O.orderdate, C.numordersinlast3days
FROM Sales.Orders AS O
  INNER JOIN C
    ON O.orderdate = C.orderdate;

-- return for each order its current order value, as well as the percent of all order values of orders placed in the last three days of activity
/*
SELECT orderid, orderdate, val,
  CAST( 100.00 * val /
          SUM(val) OVER(ORDER BY orderdate
                        GROUPS BETWEEN 2 PRECEDING 
                                   AND CURRENT ROW)
       AS NUMERIC(5, 2) ) AS pctoflast3days
FROM Sales.OrderValues;
*/

/*
orderid  orderdate  val      pctoflast3days
-------- ---------- -------- ---------------
10248    2017-07-04 440.00   100.00
10249    2017-07-05 1863.40  80.90
10250    2017-07-08 1552.60  34.43
10251    2017-07-08 654.06   14.50
10252    2017-07-09 3597.90  46.92
10253    2017-07-10 1444.80  19.93
10254    2017-07-11 556.62   9.94
10255    2017-07-12 2490.50  55.44
10256    2017-07-15 517.80   14.52
10257    2017-07-16 1119.90  27.13
...
11067    2019-05-04 86.85    0.83
11068    2019-05-04 2027.08  19.40
11069    2019-05-04 360.00   3.45
11070    2019-05-05 1629.98  10.48
11071    2019-05-05 484.50   3.11
11072    2019-05-05 5218.00  33.55
11073    2019-05-05 300.00   1.93
11074    2019-05-06 232.09   1.80
11075    2019-05-06 498.10   3.87
11076    2019-05-06 792.75   6.15
11077    2019-05-06 1255.72  9.75
*/

-- workaround in SQL Server
WITH C AS
(
  SELECT orderdate,
    SUM(SUM(val))
      OVER(ORDER BY orderdate
           ROWS BETWEEN 2 PRECEDING
                    AND CURRENT ROW) AS sumval
  FROM Sales.OrderValues
  GROUP BY orderdate
)
SELECT O.orderid, O.orderdate,
 CAST( 100.00 * O.val / C.sumval AS NUMERIC(5, 2) ) AS pctoflast3days
FROM Sales.OrderValues AS O
  INNER JOIN C
    ON O.orderdate = C.orderdate;

----------------------------------------------------------------------
-- RANGE
----------------------------------------------------------------------

-- RANGE INTERVAL '2' MONTH PRECEDING
/*
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                RANGE BETWEEN INTERVAL '2' MONTH PRECEDING
                          AND CURRENT ROW) AS sum3month
FROM Sales.EmpOrders;
*/

-- workaround in SQL Server
-- step 1, produce set of months between min and max in the table
SELECT 
  DATEADD(month, N.n,
    (SELECT MIN(ordermonth) FROM Sales.EmpOrders)) AS ordermonth
FROM dbo.GetNums(0,
  DATEDIFF(month,
    (SELECT MIN(ordermonth) FROM Sales.EmpOrders),
    (SELECT MAX(ordermonth) FROM Sales.EmpOrders))) AS N;

/*
ordermonth
----------
2017-07-01
2017-08-01
2017-09-01
2017-10-01
2017-11-01
...
2019-01-01
2019-02-01
2019-03-01
2019-04-01
2019-05-01

(23 rows affected)
*/

-- step 2, produce all possible combinations of months and employees
WITH M AS
(
  SELECT 
    DATEADD(month, N.n,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders)) AS ordermonth
  FROM dbo.GetNums(0,
    DATEDIFF(month,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders),
      (SELECT MAX(ordermonth) FROM Sales.EmpOrders))) AS N
)
SELECT E.empid, M.ordermonth
FROM HR.Employees AS E
  CROSS JOIN M;

-- step 3, join result of step 2 with EmpOrders view and compute aggregate
WITH M AS
(
  SELECT 
    DATEADD(month, N.n,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders)) AS ordermonth
  FROM dbo.GetNums(0,
    DATEDIFF(month,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders),
      (SELECT MAX(ordermonth) FROM Sales.EmpOrders))) AS N
)
SELECT E.empid, M.ordermonth, EO.qty,
  SUM(EO.qty) OVER(PARTITION BY E.empid
                   ORDER BY M.ordermonth
                   ROWS 2 PRECEDING) AS sum3month
FROM HR.Employees AS E
  CROSS JOIN M
  LEFT OUTER JOIN Sales.EmpOrders AS EO
    ON E.empid = EO.empid
    AND M.ordermonth = EO.ordermonth;

/*
empid  ordermonth  qty   sum3month
------ ----------- ----- -----------
...               
9      2017-07-01  294   294
9      2017-08-01  NULL  294
9      2017-09-01  NULL  294
9      2017-10-01  256   256
9      2017-11-01  NULL  256
9      2017-12-01  25    281
9      2018-01-01  74    99
9      2018-02-01  NULL  99
9      2018-03-01  137   211
9      2018-04-01  52    189
9      2018-05-01  8     197
9      2018-06-01  161   221
9      2018-07-01  4     173
9      2018-08-01  98    263
...
*/

-- step 4, filter only applicable rows
WITH M AS
(
  SELECT 
    DATEADD(month, N.n,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders)) AS ordermonth
  FROM dbo.GetNums(0,
    DATEDIFF(month,
      (SELECT MIN(ordermonth) FROM Sales.EmpOrders),
      (SELECT MAX(ordermonth) FROM Sales.EmpOrders))) AS N
),
C AS
(
  SELECT E.empid, M.ordermonth, EO.qty,
    SUM(EO.qty) OVER(PARTITION BY E.empid
                     ORDER BY M.ordermonth
                     ROWS 2 PRECEDING) AS sum3month
  FROM HR.Employees AS E
    CROSS JOIN M
    LEFT OUTER JOIN Sales.EmpOrders AS EO
      ON E.empid = EO.empid
      AND M.ordermonth = EO.ordermonth
)
SELECT empid, ordermonth, qty, sum3month
FROM C
WHERE qty IS NOT NULL;

-- also equivalent to
SELECT empid, ordermonth, qty,
  (SELECT SUM(qty)
   FROM Sales.EmpOrders AS O2
   WHERE O2.empid = O1.empid
     AND O2.ordermonth BETWEEN DATEADD(month, -2, O1.ordermonth)
                           AND O1.ordermonth) AS sum3month
FROM Sales.EmpOrders AS O1;

-- RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS runqty
FROM Sales.EmpOrders;

/*
empid  ordermonth  qty      runqty
------ ----------- -------- -------
1      2017-07-01  121      121
1      2017-08-01  247      368
1      2017-09-01  255      623
1      2017-10-01  143      766
1      2017-11-01  318      1084
...                         
2      2017-07-01  50       50
2      2017-08-01  94       144
2      2017-09-01  137      281
2      2017-10-01  248      529
2      2017-11-01  237      766
...
*/

SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                RANGE UNBOUNDED PRECEDING) AS runqty
FROM Sales.EmpOrders;

SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth) AS runqty
FROM Sales.EmpOrders;

-- ROWS UNBOUNDED PRECEDING when ties exist
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS cnt
FROM dbo.T1;

/*
keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          2
5           B          3
7           B          4
11          B          5
13          C          6
17          C          7
19          C          8
23          C          9
*/

-- RANGE UNBOUNDED PRECEDING when ties exist
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW) AS cnt
FROM dbo.T1;

/*
keycol      col1       cnt
----------- ---------- -----------
2           A          2
3           A          2
5           B          5
7           B          5
11          B          5
13          C          9
17          C          9
19          C          9
23          C          9
*/

-- break ties
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1, keycol
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS cnt
FROM dbo.T1;

/*
keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          2
5           B          3
7           B          4
11          B          5
13          C          6
17          C          7
19          C          8
23          C          9
*/

-- apply perliminary grouping
SELECT col1,
  SUM(COUNT(*)) OVER(ORDER BY col1
                     ROWS BETWEEN UNBOUNDED PRECEDING
                              AND CURRENT ROW) AS cnt
FROM dbo.T1
GROUP BY col1;

/*
col1       cnt
---------- -----------
A          2
B          5
C          9
*/

----------------------------------------------------------------------
-- Window Frame Exclusion
----------------------------------------------------------------------

/*
-- Listing 2-2: Queries with Different Window Frame Exclusion Options
-- EXCLUDE NO OTHERS (don't exclude rows)
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW
                EXCLUDE NO OTHERS) AS cnt
FROM dbo.T1;

keycol      col1       cnt
----------- ---------- -----------
2           A          2
3           A          2
5           B          5
7           B          5
11          B          5
13          C          9
17          C          9
19          C          9
23          C          9

-- EXCLUDE CURRENT ROW (exclude current row)
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW
                EXCLUDE CURRENT ROW) AS cnt
FROM dbo.T1;

keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          1
5           B          4
7           B          4
11          B          4
13          C          8
17          C          8
19          C          8
23          C          8

-- EXCLUDE GROUP (exclude current row and its peers)
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW
                EXCLUDE GROUP) AS cnt
FROM dbo.T1;

keycol      col1       cnt
----------- ---------- -----------
2           A          0
3           A          0
5           B          2
7           B          2
11          B          2
13          C          5
17          C          5
19          C          5
23          C          5

-- EXCLUDE TIES (keep current row, exclude peers)
SELECT keycol, col1,
  COUNT(*) OVER(ORDER BY col1
                RANGE BETWEEN UNBOUNDED PRECEDING
                          AND CURRENT ROW
                EXCLUDE TIES) AS cnt
FROM dbo.T1;

keycol      col1       cnt
----------- ---------- -----------
2           A          1
3           A          1
5           B          3
7           B          3
11          B          3
13          C          6
17          C          6
19          C          6
23          C          6
*/

----------------------------------------------------------------------
-- Further Windowing Ideas
----------------------------------------------------------------------

----------------------------------------------------------------------
-- FILTER clause
----------------------------------------------------------------------

-- using the FILTER clause, filter 3 months before now
/*
SELECT empid, ordermonth, qty,
  qty - AVG(qty)
          FILTER (WHERE ordermonth <=
                    DATEADD(month, -3, CURRENT_TIMESTAMP))
          OVER(PARTITION BY empid) AS diff
FROM Sales.EmpOrders;
*/

-- an altrnative to the FILTER clause, filter 3 months before now
SELECT empid, ordermonth, qty,
  qty - AVG(CASE WHEN ordermonth <=
              DATEADD(month, -3, CURRENT_TIMESTAMP)
                THEN qty
            END)
          OVER(PARTITION BY empid) AS diff
FROM Sales.EmpOrders;

----------------------------------------------------------------------
-- Nested Window Functions
----------------------------------------------------------------------

-- nested row number function
-- show the current order value, as well as the difference from the
-- employee average excluding the very first and last employee’s orders
/*
SELECT orderid, orderdate, empid, custid, val,
  val - AVG(CASE
              WHEN  ROW_NUMBER(FRAME_ROW) > ROW_NUMBER(BEGIN_PARTITION)
                AND ROW_NUMBER(FRAME_ROW) < ROW_NUMBER(END_PARTITION)
                  THEN val
            END)
          OVER(PARTITION BY empid
               ORDER BY orderdate, orderid
               ROWS BETWEEN UNBOUNDED PRECEDING
                        AND UNBOUNDED FOLLOWING) AS diff
FROM Sales.OrderValues;
*/

-- nested value_of expression at row function 
-- filter orders by the same employee but a different customer than the current
/*
SELECT orderid, orderdate, empid, custid, val,
  val - AVG(CASE
             WHEN custid <> VALUE OF custid AT CURRENT_ROW
               THEN val
            END)
          OVER(PARTITION BY empid) AS diff
FROM Sales.OrderValues;
*/

-- range between two months before the current month and the current month
/*
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                RANGE BETWEEN INTERVAL '2' MONTH PRECEDING
                          AND CURRENT ROW) AS sum3month
FROM Sales.EmpOrders;
*/

-- alternative with nested window functions
/*
SELECT empid, ordermonth, qty,
  SUM(CASE
        WHEN ordermonth BETWEEN DATEADD(month, -2,
                                  VALUE OF ordermonth AT CURRENT_ROW)
                            AND VALUE OF ordermonth AT CURRENT_ROW
        THEN qty
      END)
    OVER(PARTITION BY empid
                ORDER BY ordermonth
                RANGE UNBOUNDED PRECEDING) AS sum3month
FROM Sales.EmpOrders;
*/

----------------------------------------------------------------------
-- RESET WHEN
----------------------------------------------------------------------

-- Listing 2-3: Code to Create and Populate T2
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T2;

CREATE TABLE dbo.T2
(
  ordcol  INT NOT NULL,
  datacol INT NOT NULL,
  CONSTRAINT PK_T2
    PRIMARY KEY(ordcol)
);

INSERT INTO dbo.T2 VALUES
  (1,   10),
  (4,   15),
  (5,    5),
  (6,   10),
  (8,   15),
  (10,  20),
  (17,  10),
  (18,  10),
  (20,  30),
  (31,  20);

-- running sum, stop before sum exceeds 50
-- in other words, start a new partition when sum exceeds 50
/*
SELECT ordcol, datacol,
  SUM(datacol) 
    OVER(ORDER BY ordcol
         RESET WHEN
           SUM(qty) OVER(ORDER BY ordcol
                         ROWS UNBOUNDED PRECEDING) > 50
         ROWS UNBOUNDED PRECEDING) AS runsum
FROM dbo.T2;
*/

/*
ordcol  datacol  runsum
------- -------- -------
1       10       10
4       15       25
5       5        30
6       10       40
8       15       15
10      20       35
17      10       45
18      10       10
20      30       40
31      20       20
*/

-- running sum, stop when sum reaches or exceeds 50 for the first time
/*
SELECT ordcol, datacol,
  SUM(datacol) 
    OVER(ORDER BY ordcol
         RESET WHEN
           SUM(qty) OVER(ORDER BY ordcol
                         ROWS BETWEEN UNBOUNDED PRECEDING
                                  AND 1 PRECEDING) >= 50
         ROWS UNBOUNDED PRECEDING) AS runsum
FROM dbo.T2;
*/

/*
ordcol  datacol  runsum
------- -------- -------
1       10       10
4       15       25
5       5        30
6       10       40
8       15       55
10      20       20
17      10       30
18      10       40
20      30       70
31      20       20
*/

----------------------------------------------------------------------
-- Distinct Aggregates
----------------------------------------------------------------------

-- distinct window aggregate example (currently unsupported)
/*
SELECT empid, orderdate, orderid, val,
  COUNT(DISTINCT custid) OVER(PARTITION BY empid
                              ORDER BY orderdate) AS numcusts
FROM Sales.OrderValues;
*/

-- Listing 2-4: Emulating Distinct Aggregate with ROW_NUMBER, Step 1
SELECT empid, orderdate, orderid, custid, val,
  CASE 
    WHEN ROW_NUMBER() OVER(PARTITION BY empid, custid
                           ORDER BY orderdate) = 1
      THEN custid
  END AS distinct_custid
FROM Sales.OrderValues;

/*
empid  orderdate  orderid  custid  val      distinct_custid
------ ---------- -------- ------- -------- ---------------
1      2019-01-15 10835    1       845.80   1
1      2019-03-16 10952    1       471.20   NULL
1      2018-09-22 10677    3       813.37   3
1      2018-02-21 10453    4       407.70   4
1      2018-06-04 10558    4       2142.90  NULL
1      2018-11-17 10743    4       319.20   NULL
1      2018-05-01 10524    5       3192.65  5
1      2018-08-11 10626    5       1503.60  NULL
1      2018-10-01 10689    5       472.50   NULL
1      2018-11-07 10733    5       1459.00  NULL
1      2017-10-29 10340    9       2436.18  9
1      2018-05-02 10525    9       818.40   NULL
1      2019-01-12 10827    9       843.00   NULL
1      2019-03-25 10975    10      717.50   10
1      2019-04-16 11027    10      877.73   NULL
1      2019-04-14 11023    11      1500.00  11
1      2018-11-19 10746    14      2311.70  14
1      2019-03-23 10969    15      108.00   15
1      2019-01-09 10825    17      1030.76  17
1      2019-05-04 11067    17      86.85    NULL
1      2017-09-20 10311    18      268.80   18
1      2017-11-26 10364    19      950.00   19
1      2018-01-01 10400    19      3063.00  NULL
1      2017-07-17 10258    20      1614.88  20
1      2017-11-11 10351    20      5398.73  NULL
1      2018-12-11 10773    20      2030.40  NULL
1      2018-12-15 10776    20      6635.28  NULL
1      2019-03-23 10968    20      1408.00  NULL
...
*/

-- Listing 2-5: Emulating Distinct Aggregate with ROW_NUMBER, Complete Solution
WITH C AS
(
  SELECT empid, orderdate, orderid, custid, val,
    CASE 
      WHEN ROW_NUMBER() OVER(PARTITION BY empid, custid
                             ORDER BY orderdate) = 1
        THEN custid
    END AS distinct_custid
  FROM Sales.OrderValues
)
SELECT empid, orderdate, orderid, val,
  COUNT(distinct_custid) OVER(PARTITION BY empid
                              ORDER BY orderdate) AS numcusts
FROM C;

/*
empid  orderdate               orderid  val      numcusts
------ ----------------------- -------- -------- ---------
1      2017-07-17 10258    1614.88  1
1      2017-08-01 10270    1376.00  2
1      2017-08-07 10275    291.84   3
1      2017-08-20 10285    1743.36  4
1      2017-08-28 10292    1296.00  5
1      2017-08-29 10293    848.70   6
1      2017-09-12 10304    954.40   6
1      2017-09-16 10306    498.50   7
1      2017-09-20 10311    268.80   8
1      2017-09-25 10314    2094.30  9
1      2017-09-27 10316    2835.00  9
1      2017-10-09 10325    1497.00  10
1      2017-10-29 10340    2436.18  11
1      2017-11-11 10351    5398.73  11
1      2017-11-19 10357    1167.68  12
1      2017-11-22 10361    2046.24  12
1      2017-11-26 10364    950.00   13
1      2017-12-03 10371    72.96    14
1      2017-12-05 10374    459.00   15
1      2017-12-09 10377    863.60   17
1      2017-12-09 10376    399.00   17
1      2017-12-17 10385    691.20   18
1      2017-12-18 10387    1058.40  19
1      2017-12-25 10393    2556.95  21
1      2017-12-25 10394    442.00   21
1      2017-12-27 10396    1903.80  22
1      2018-01-01 10400    3063.00  22
1      2018-01-01 10401    3868.60  22
...
*/

----------------------------------------------------------------------
-- Nested Aggregates
----------------------------------------------------------------------

-- percent of employee total out of grand total
SELECT empid,
  SUM(val) AS emptotal,
  SUM(val) / SUM(SUM(val)) OVER() * 100. AS pct
FROM Sales.OrderValues
GROUP BY empid;

/*
empid  emptotal   pct
------ ---------- -----------
3      202812.88  16.022500
6      73913.15   5.839200
9      77308.08   6.107400
7      124568.24  9.841100
1      192107.65  15.176800
4      232890.87  18.398800
2      166537.76  13.156700
5      68792.30   5.434700
8      126862.29  10.022300
*/

-- step 1: grouped aggregate
SELECT empid,
  SUM(val) AS emptotal
FROM Sales.OrderValues
GROUP BY empid;

/*
empid  emptotal
------ -----------
3      202812.88
6      73913.15
9      77308.08
7      124568.24
1      192107.65
4      232890.87
2      166537.76
5      68792.30
8      126862.29
*/

-- step 2: final query
SELECT empid,
  SUM(val) AS emptotal,
  SUM(val) / SUM(SUM(val)) OVER() * 100. AS pct
FROM Sales.OrderValues
GROUP BY empid;

-- with a CTE
WITH C AS
(
  SELECT empid,
    SUM(val) AS emptotal
  FROM Sales.OrderValues
  GROUP BY empid
)
SELECT empid, emptotal,
  emptotal / SUM(emptotal) OVER() * 100. AS pct
FROM C;

-- following fails
/*
WITH C AS
(
  SELECT empid, orderdate,
    CASE 
      WHEN ROW_NUMBER() OVER(PARTITION BY empid, custid
                             ORDER BY orderdate) = 1
        THEN custid
    END AS distinct_custid
  FROM Sales.Orders
)
SELECT empid, orderdate,
  COUNT(distinct_custid) OVER(PARTITION BY empid
                              ORDER BY orderdate) AS numcusts
FROM C
GROUP BY empid, orderdate;
*/

/*
Msg 8120, Level 16, State 1, Line 12
Column 'C.distinct_custid' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.
*/

-- following succeeds
-- Listing 2-6: Nesting a Group Function within a Window Function
WITH C AS
(
  SELECT empid, orderdate,
    CASE 
      WHEN ROW_NUMBER() OVER(PARTITION BY empid, custid
                             ORDER BY orderdate) = 1
        THEN custid
    END AS distinct_custid
  FROM Sales.Orders
)
SELECT empid, orderdate,
  SUM(COUNT(distinct_custid)) OVER(PARTITION BY empid
                                   ORDER BY orderdate) AS numcusts
FROM C
GROUP BY empid, orderdate;

/*
empid       orderdate               numcusts
----------- ----------------------- -----------
1           2017-07-17 1
1           2017-08-01 2
1           2017-08-07 3
1           2017-08-20 4
1           2017-08-28 5
1           2017-08-29 6
1           2017-09-12 6
1           2017-09-16 7
1           2017-09-20 8
1           2017-09-25 9
1           2017-09-27 9
1           2017-10-09 10
1           2017-10-29 11
1           2017-11-11 11
1           2017-11-19 12
1           2017-11-22 12
1           2017-11-26 13
1           2017-12-03 14
1           2017-12-05 15
1           2017-12-09 17
1           2017-12-17 18
1           2017-12-18 19
1           2017-12-25 21
1           2017-12-27 22
1           2018-01-01 22
...
*/

----------------------------------------------------------------------
-- Ranking Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Row Number and Ntile Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- ROW_NUMBER
----------------------------------------------------------------------

-- Listing 2-7: Query with ROW_NUMBER Function
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY orderid) AS rownum
FROM Sales.OrderValues;

/*
orderid  val      rownum
-------- -------- -------
10248    440.00   1
10249    1863.40  2
10250    1552.60  3
10251    654.06   4
10252    3597.90  5
10253    1444.80  6
10254    556.62   7
10255    2490.50  8
10256    517.80   9
10257    1119.90  10
...
*/

-- guarantee presentation ordering
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY orderid) AS rownum
FROM Sales.OrderValues
ORDER BY rownum;

-- different presentation ordering and window ordering
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY orderid) AS rownum
FROM Sales.OrderValues
ORDER BY val DESC;

/*
orderid  val       rownum
-------- --------- -------
10865    16387.50  618
10981    15810.00  734
11030    12615.05  783
10889    11380.00  642
10417    11188.40  170
10817    10952.85  570
10897    10835.24  650
10479    10495.60  232
10540    10191.70  293
10691    10164.80  444
...
*/

-- alternative with COUNT window aggregate
SELECT orderid, val,
  COUNT(*) OVER(ORDER BY orderid
                ROWS UNBOUNDED PRECEDING) AS rownum
FROM Sales.OrderValues;

-- alternative without window functions
SELECT orderid, val,
  (SELECT COUNT(*)
   FROM Sales.OrderValues AS O2
   WHERE O2.orderid <= O1.orderid) AS rownum
FROM Sales.OrderValues AS O1;

----------------------------------------------------------------------
-- Determinism
----------------------------------------------------------------------

-- nondeterministic calculation
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY orderdate DESC) AS rownum
FROM Sales.OrderValues;

/*
orderid  orderdate               val      rownum
-------- ----------------------- -------- -------
11074    2019-05-06 232.09   1
11075    2019-05-06 498.10   2
11076    2019-05-06 792.75   3
11077    2019-05-06 1255.72  4
11070    2019-05-05 1629.98  5
11071    2019-05-05 484.50   6
11072    2019-05-05 5218.00  7
11073    2019-05-05 300.00   8
11067    2019-05-04 86.85    9
11068    2019-05-04 2027.08  10
...
*/

-- deterministic calculation
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY orderdate DESC, orderid DESC) AS rownum
FROM Sales.OrderValues;

/*
orderid  orderdate               val      rownum
-------- ----------------------- -------- -------
11077    2019-05-06 1255.72  1
11076    2019-05-06 792.75   2
11075    2019-05-06 498.10   3
11074    2019-05-06 232.09   4
11073    2019-05-05 300.00   5
11072    2019-05-05 5218.00  6
11071    2019-05-05 484.50   7
11070    2019-05-05 1629.98  8
11069    2019-05-04 360.00   9
11068    2019-05-04 2027.08  10
...
*/

-- alternative without window functions
SELECT orderdate, orderid, val,
  (SELECT COUNT(*)
   FROM Sales.OrderValues AS O2
   WHERE O2.orderdate >= O1.orderdate
     AND (O2.orderdate > O1.orderdate
          OR O2.orderid >= O1.orderid)) AS rownum
FROM Sales.OrderValues AS O1;


-- attempt 1 for ROW_NUMBER with no ordering
/*
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER() AS rownum
FROM Sales.OrderValues;
*/

/*
Msg 4112, Level 15, State 1, Line 2
The function 'ROW_NUMBER' must have an OVER clause with ORDER BY.
*/

-- attempt 2 for ROW_NUMBER with no ordering
/*
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY NULL) AS rownum
FROM Sales.OrderValues;
*/

/*
Msg 5309, Level 16, State 1, Line 2
Windowed functions and NEXT VALUE FOR functions do not support constants as ORDER BY clause expressions.
*/

-- Sidebar about sequences

-- create sequence
CREATE SEQUENCE dbo.Seq1 AS INT MINVALUE 1;

-- obtain new value from a sequence
SELECT NEXT VALUE FOR dbo.Seq1;

-- use in a query
SELECT orderid, orderdate, val,
  NEXT VALUE FOR dbo.Seq1 AS seqval
FROM Sales.OrderValues;

-- with an OVER clause
SELECT orderid, orderdate, val,
  NEXT VALUE FOR dbo.Seq1 OVER(ORDER BY orderdate, orderid) AS seqval
FROM Sales.OrderValues;

-- attempt 3 for ROW_NUMBER with no ordering
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
FROM Sales.OrderValues;

/*
orderid  orderdate               val      rownum
-------- ----------------------- -------- -------
10248    2017-07-04 440.00   1
10249    2017-07-05 1863.40  2
10250    2017-07-08 1552.60  3
10251    2017-07-08 654.06   4
10252    2017-07-09 3597.90  5
10253    2017-07-10 1444.80  6
10254    2017-07-11 556.62   7
10255    2017-07-12 2490.50  8
10256    2017-07-15 517.80   9
10257    2017-07-16 1119.90  10
...
*/

-- attempt 4 for ROW_NUMBER with no ordering
/*
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY 1/1) AS rownum
FROM Sales.OrderValues;
*/

/*
Msg 5308, Level 16, State 1, Line 1238
Windowed functions, aggregates and NEXT VALUE FOR functions do not support integer indices as ORDER BY clause expressions.
*/

-- attempt 5 for ROW_NUMBER with no ordering
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY 1/0) AS rownum
FROM Sales.OrderValues;

----------------------------------------------------------------------
-- NTILE
----------------------------------------------------------------------

-- Listing 2-8: Query Computing Row Numbers and Tile Numbers
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  NTILE(10) OVER(ORDER BY val) AS tile
FROM Sales.OrderValues;

/*
orderid  val       rownum  tile
-------- --------- ------- -----
10782    12.50     1       1
10807    18.40     2       1
10586    23.80     3       1
10767    28.00     4       1
10898    30.00     5       1
...
10708    180.40    78      1
10476    180.48    79      1
10313    182.40    80      1
10810    187.00    81      1
11065    189.42    82      1
10496    190.00    83      1
10793    191.10    84      2
10428    192.00    85      2
10520    200.00    86      2
11040    200.00    87      2
11043    210.00    88      2
...
10417    11188.40  826     10
10889    11380.00  827     10
11030    12615.05  828     10
10981    15810.00  829     10
10865    16387.50  830     10
*/

-- Listing 2-9: Query Computing Page Numbers
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  (ROW_NUMBER() OVER(ORDER BY val) - 1) / 10 + 1 AS pagenum
FROM Sales.OrderValues;

/*
orderid  val       rownum  pagenum
-------- --------- ------- --------
10782    12.50     1       1
10807    18.40     2       1
10586    23.80     3       1
10767    28.00     4       1
10898    30.00     5       1
10900    33.75     6       1
10883    36.00     7       1
11051    36.00     8       1
10815    40.00     9       1
10674    45.00     10      1
11057    45.00     11      2
10271    48.00     12      2
10602    48.75     13      2
10422    49.80     14      2
10738    52.35     15      2
10754    55.20     16      2
10631    55.80     17      2
10620    57.50     18      2
10963    57.80     19      2
11037    60.00     20      2
10683    63.00     21      3
...
10515    9921.30   820     82
10691    10164.80  821     83
10540    10191.70  822     83
10479    10495.60  823     83
10897    10835.24  824     83
10817    10952.85  825     83
10417    11188.40  826     83
10889    11380.00  827     83
11030    12615.05  828     83
10981    15810.00  829     83
10865    16387.50  830     83
*/

-- deterministic NTILE
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY val, orderid) AS rownum,
  NTILE(10) OVER(ORDER BY val, orderid) AS tile
FROM Sales.OrderValues;

-- Listing 2-10: Query Showing Uneven Distribution of Extra Rows among Tiles
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY val, orderid) AS rownum,
  NTILE(100) OVER(ORDER BY val, orderid) AS tile
FROM Sales.OrderValues;

/*
orderid  val       rownum  tile
-------- --------- ------- -----
10782    12.50     1       1
10807    18.40     2       1
10586    23.80     3       1
10767    28.00     4       1
10898    30.00     5       1
10900    33.75     6       1
10883    36.00     7       1
11051    36.00     8       1
10815    40.00     9       1
10674    45.00     10      2
11057    45.00     11      2
10271    48.00     12      2
10602    48.75     13      2
10422    49.80     14      2
10738    52.35     15      2
10754    55.20     16      2
10631    55.80     17      2
10620    57.50     18      2
10963    57.80     19      3
...
10816    8446.45   814     98
10353    8593.28   815     99
10514    8623.45   816     99
11032    8902.50   817     99
10424    9194.56   818     99
10372    9210.90   819     99
10515    9921.30   820     99
10691    10164.80  821     99
10540    10191.70  822     99
10479    10495.60  823     100
10897    10835.24  824     100
10817    10952.85  825     100
10417    11188.40  826     100
10889    11380.00  827     100
11030    12615.05  828     100
10981    15810.00  829     100
10865    16387.50  830     100
*/

-- alternative to NTILE without window functions

-- calculation for given cardinality, number of tiles and row number
DECLARE @cnt AS INT = 830, @numtiles AS INT = 100, @rownum AS INT = 42;

WITH C1 AS
(
  SELECT 
    @cnt / @numtiles     AS basetilesize,
    @cnt / @numtiles + 1 AS extendedtilesize,
    @cnt % @numtiles     AS remainder
),
C2 AS
(
  SELECT *, extendedtilesize * remainder AS cutoffrow
  FROM C1
)
SELECT
  CASE WHEN @rownum <= cutoffrow
    THEN (@rownum - 1) / extendedtilesize + 1
    ELSE remainder + ((@rownum - cutoffrow) - 1) / basetilesize + 1
  END AS tile
FROM C2;
GO

-- calculation for given number of tiles against a table
-- Listing 2-11: Query Computing Tile Numbers without the NTILE Function
DECLARE @numtiles AS INT = 100;

WITH C1 AS
(
  SELECT 
    COUNT(*) / @numtiles AS basetilesize,
    COUNT(*) / @numtiles + 1 AS extendedtilesize,
    COUNT(*) % @numtiles AS remainder
  FROM Sales.OrderValues
),
C2 AS
(
  SELECT *, extendedtilesize * remainder AS cutoffrow
  FROM C1
),
C3 AS
(
  SELECT O1.orderid, O1.val,
    (SELECT COUNT(*)
     FROM Sales.OrderValues AS O2
     WHERE O2.val <= O1.val
       AND (O2.val < O1.val
            OR O2.orderid <= O1.orderid)) AS rownum
  FROM Sales.OrderValues AS O1
)
SELECT C3.*,
  CASE WHEN C3.rownum <= C2.cutoffrow
    THEN (C3.rownum - 1) / C2.extendedtilesize + 1
    ELSE C2.remainder + ((C3.rownum - C2.cutoffrow) - 1) / C2.basetilesize + 1
  END AS tile
FROM C3 CROSS JOIN C2;

----------------------------------------------------------------------
-- Rank Functions
----------------------------------------------------------------------

-- ROW_NUMBER, RANK, DENSE_RANK
SELECT orderid, orderdate, val,
  ROW_NUMBER() OVER(ORDER BY orderdate DESC) AS rownum,
  RANK()       OVER(ORDER BY orderdate DESC) AS rnk,
  DENSE_RANK() OVER(ORDER BY orderdate DESC) AS drnk
FROM Sales.OrderValues;

/*
orderid  orderdate               val      rownum  rnk  drnk
-------- ----------------------- -------- ------- ---- ----
11077    2019-05-06 232.09   1       1    1
11076    2019-05-06 498.10   2       1    1
11075    2019-05-06 792.75   3       1    1
11074    2019-05-06 1255.72  4       1    1
11073    2019-05-05 1629.98  5       5    2
11072    2019-05-05 484.50   6       5    2
11071    2019-05-05 5218.00  7       5    2
11070    2019-05-05 300.00   8       5    2
11069    2019-05-04 86.85    9       9    3
11068    2019-05-04 2027.08  10      9    3
...
*/

-- alternative to ROW_NUMBER, RANK, DENSE_RANK
SELECT orderid, orderdate, val,
  (SELECT COUNT(*)
   FROM Sales.OrderValues AS O2
   WHERE O2.orderdate > O1.orderdate) + 1 AS rnk,
  (SELECT COUNT(DISTINCT orderdate)
   FROM Sales.OrderValues AS O2
   WHERE O2.orderdate > O1.orderdate) + 1 AS drnk
FROM Sales.OrderValues AS O1;

----------------------------------------------------------------------
-- Distribution Functions
----------------------------------------------------------------------

-- Contents of Scores Table
SELECT testid, studentid, score
FROM Stats.Scores;

/*
testid     studentid  score
---------- ---------- -----
Test ABC   Student A  95
Test ABC   Student B  80
Test ABC   Student C  55
Test ABC   Student D  55
Test ABC   Student E  50
Test ABC   Student F  80
Test ABC   Student G  95
Test ABC   Student H  65
Test ABC   Student I  75
Test XYZ   Student A  95
Test XYZ   Student B  80
Test XYZ   Student C  55
Test XYZ   Student D  55
Test XYZ   Student E  50
Test XYZ   Student F  80
Test XYZ   Student G  95
Test XYZ   Student H  65
Test XYZ   Student I  75
Test XYZ   Student J  95
*/

----------------------------------------------------------------------
-- Rank Distribution Functions
----------------------------------------------------------------------

-- Listing 2-12: Query Computing PERCENT_RANK and CUME_DIST
SELECT testid, studentid, score,
  PERCENT_RANK() OVER(PARTITION BY testid ORDER BY score) AS percentrank,
  CUME_DIST()    OVER(PARTITION BY testid ORDER BY score) AS cumedist
FROM Stats.Scores;

-- formatted
SELECT testid, studentid, score,
  CAST(PERCENT_RANK() OVER(PARTITION BY testid ORDER BY score) AS NUMERIC(4, 3)) AS percentrank,
  CAST(CUME_DIST()    OVER(PARTITION BY testid ORDER BY score) AS NUMERIC(4, 3)) AS cumedist
FROM Stats.Scores;

/*
testid     studentid  score percentrank  cumedist
---------- ---------- ----- ------------ ---------
Test ABC   Student E  50    0.000        0.111
Test ABC   Student C  55    0.125        0.333
Test ABC   Student D  55    0.125        0.333
Test ABC   Student H  65    0.375        0.444
Test ABC   Student I  75    0.500        0.556
Test ABC   Student F  80    0.625        0.778
Test ABC   Student B  80    0.625        0.778
Test ABC   Student A  95    0.875        1.000
Test ABC   Student G  95    0.875        1.000
Test XYZ   Student E  50    0.000        0.100
Test XYZ   Student C  55    0.111        0.300
Test XYZ   Student D  55    0.111        0.300
Test XYZ   Student H  65    0.333        0.400
Test XYZ   Student I  75    0.444        0.500
Test XYZ   Student B  80    0.556        0.700
Test XYZ   Student F  80    0.556        0.700
Test XYZ   Student G  95    0.778        1.000
Test XYZ   Student J  95    0.778        1.000
Test XYZ   Student A  95    0.778        1.000
*/

-- computing percentile rank and cumulative distribution without PERCENT_RANK and CUME_DIST functions
WITH C AS
(
  SELECT testid, studentid, score,
    RANK() OVER(PARTITION BY testid ORDER BY score) AS rk,
    COUNT(*) OVER(PARTITION BY testid) AS nr
  FROM Stats.Scores
)
SELECT testid, studentid, score,
  1.0 * (rk - 1) / (nr - 1) AS percentrank,
  1.0 * (SELECT COALESCE(MIN(C2.rk) - 1, C1.nr)
         FROM C AS C2
         WHERE C2.testid = C1.testid
           AND C2.rk > C1.rk) / nr AS cumedist
FROM C AS C1;

-- an example involving aggregates
SELECT empid, COUNT(*) AS numorders,
  PERCENT_RANK() OVER(ORDER BY COUNT(*)) AS percentrank,
  CUME_DIST() OVER(ORDER BY COUNT(*)) AS cumedist
FROM Sales.Orders
GROUP BY empid;

-- formatted
SELECT empid, COUNT(*) AS numorders,
  CAST(PERCENT_RANK() OVER(ORDER BY COUNT(*)) AS NUMERIC(4, 3)) AS percentrank,
  CAST(CUME_DIST() OVER(ORDER BY COUNT(*)) AS NUMERIC(4, 3)) AS cumedist
FROM Sales.Orders
GROUP BY empid;
GO

/*
empid  numorders  percentrank  cumedist
------ ---------- ------------ ---------
5      42         0.000        0.111
9      43         0.125        0.222
6      67         0.250        0.333
7      72         0.375        0.444
2      96         0.500        0.556
8      104        0.625        0.667
1      123        0.750        0.778
3      127        0.875        0.889
4      156        1.000        1.000
*/

----------------------------------------------------------------------
-- Inverse Distribution Functions
----------------------------------------------------------------------

-- unsupported code
/*
SELECT groupcol, PERCENTILE_FUNCTION(0.5) WITHIN GROUP(ORDER BY ordcol) AS median
FROM T1
GROUP BY groupcol;
*/

-- Listing 2-13: Query Computing Median Test Scores with Window Functions 
DECLARE @pct AS FLOAT = 0.5;

SELECT testid, studentid, score,
  PERCENTILE_DISC(@pct) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentiledisc,
  PERCENTILE_CONT(@pct) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentilecont
FROM Stats.Scores;
GO

/*
testid     studentid  score percentiledisc percentilecont
---------- ---------- ----- -------------- ----------------------
Test ABC   Student E  50    75             75
Test ABC   Student C  55    75             75
Test ABC   Student D  55    75             75
Test ABC   Student H  65    75             75
Test ABC   Student I  75    75             75
Test ABC   Student B  80    75             75
Test ABC   Student F  80    75             75
Test ABC   Student A  95    75             75
Test ABC   Student G  95    75             75
Test XYZ   Student E  50    75             77.5
Test XYZ   Student C  55    75             77.5
Test XYZ   Student D  55    75             77.5
Test XYZ   Student H  65    75             77.5
Test XYZ   Student I  75    75             77.5
Test XYZ   Student B  80    75             77.5
Test XYZ   Student F  80    75             77.5
Test XYZ   Student A  95    75             77.5
Test XYZ   Student G  95    75             77.5
Test XYZ   Student J  95    75             77.5
*/

-- Listing 2-14: Query Computing Tenth Percentile Test Scores with Window Functions 
DECLARE @pct AS FLOAT = 0.1;

SELECT testid, studentid, score,
  PERCENTILE_DISC(@pct) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentiledisc,
  PERCENTILE_CONT(@pct) WITHIN GROUP(ORDER BY score)
    OVER(PARTITION BY testid) AS percentilecont
FROM Stats.Scores;
GO

/*
testid     studentid  score percentiledisc percentilecont
---------- ---------- ----- -------------- ----------------------
Test ABC   Student E  50    50             54
Test ABC   Student C  55    50             54
Test ABC   Student D  55    50             54
Test ABC   Student H  65    50             54
Test ABC   Student I  75    50             54
Test ABC   Student B  80    50             54
Test ABC   Student F  80    50             54
Test ABC   Student A  95    50             54
Test ABC   Student G  95    50             54
Test XYZ   Student E  50    50             54.5
Test XYZ   Student C  55    50             54.5
Test XYZ   Student D  55    50             54.5
Test XYZ   Student H  65    50             54.5
Test XYZ   Student I  75    50             54.5
Test XYZ   Student B  80    50             54.5
Test XYZ   Student F  80    50             54.5
Test XYZ   Student A  95    50             54.5
Test XYZ   Student G  95    50             54.5
Test XYZ   Student J  95    50             54.5
*/

----------------------------------------------------------------------
-- Offset Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- LAG and LEAD
----------------------------------------------------------------------

-- Listing 2-15: Query with LAG and LEAD
SELECT custid, orderdate, orderid, val,
  LAG(val)  OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS prevval,
  LEAD(val) OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues;

/*
custid  orderdate   orderid  val      prevval  nextval
------- ----------- -------- -------- -------- --------
1       2018-08-25  10643    814.50   NULL     878.00
1       2018-10-03  10692    878.00   814.50   330.00
1       2018-10-13  10702    330.00   878.00   845.80
1       2019-01-15  10835    845.80   330.00   471.20
1       2019-03-16  10952    471.20   845.80   933.50
1       2019-04-09  11011    933.50   471.20   NULL
2       2017-09-18  10308    88.80    NULL     479.75
2       2018-08-08  10625    479.75   88.80    320.00
2       2018-11-28  10759    320.00   479.75   514.40
2       2019-03-04  10926    514.40   320.00   NULL
3       2017-11-27  10365    403.20   NULL     749.06
3       2018-04-15  10507    749.06   403.20   1940.85
3       2018-05-13  10535    1940.85  749.06   2082.00
3       2018-06-19  10573    2082.00  1940.85  813.37
3       2018-09-22  10677    813.37   2082.00  375.50
3       2018-09-25  10682    375.50   813.37   660.00
3       2019-01-28  10856    660.00   375.50   NULL
...
*/

-- Listing 2-16: Query using LAG with an Explicit Offset
SELECT custid, orderdate, orderid,
  LAG(val, 3) OVER(PARTITION BY custid
                   ORDER BY orderdate, orderid) AS prev3val
FROM Sales.OrderValues;

/*
custid  orderdate   orderid  prev3val
------- ----------- -------- ---------
1       2018-08-25  10643    NULL
1       2018-10-03  10692    NULL
1       2018-10-13  10702    NULL
1       2019-01-15  10835    814.50
1       2019-03-16  10952    878.00
1       2019-04-09  11011    330.00
2       2017-09-18  10308    NULL
2       2018-08-08  10625    NULL
2       2018-11-28  10759    NULL
2       2019-03-04  10926    88.80
3       2017-11-27  10365    NULL
3       2018-04-15  10507    NULL
3       2018-05-13  10535    NULL
3       2018-06-19  10573    403.20
3       2018-09-22  10677    749.06
3       2018-09-25  10682    1940.85
3       2019-01-28  10856    2082.00
...
*/

-- Solution 1 for getting previous and next without LAG and LEAD
WITH OrdersRN AS
(
  SELECT custid, orderdate, orderid, val,
    ROW_NUMBER() OVER(ORDER BY custid, orderdate, orderid) AS rn
  FROM Sales.OrderValues
)
SELECT C.custid, C.orderdate, C.orderid, C.val,
  P.val AS prevval,
  N.val AS nextval
FROM OrdersRN AS C
  LEFT OUTER JOIN OrdersRN AS P
    ON C.custid = P.custid
    AND C.rn = P.rn + 1
  LEFT OUTER JOIN OrdersRN AS N
    ON C.custid = N.custid
    AND C.rn = N.rn - 1;

-- Solution 1 for getting previous and next without LAG and LEAD
-- By Kamil Kosno
WITH C AS
(
  SELECT custid, orderid,
    ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS curid,
    ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) + 1 AS previd,
    ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) - 1 AS nextid
  FROM Sales.OrderValues
)
SELECT custid, curid, previd, nextid
FROM C
  UNPIVOT(rownum FOR rownumtype IN(curid, previd, nextid)) AS U
  PIVOT(MAX(orderid) FOR rownumtype IN(curid, previd, nextid)) AS P
WHERE curid IS NOT NULL
ORDER BY custid, curid;

/*
custid  curid  previd  nextid
------- ------ ------- -------
1       10643  NULL    10692
1       10692  10643   10702
1       10702  10692   10835
1       10835  10702   10952
1       10952  10835   11011
1       11011  10952   NULL
2       10308  NULL    10625
2       10625  10308   10759
2       10759  10625   10926
2       10926  10759   NULL
3       10365  NULL    10507
3       10507  10365   10535
3       10535  10507   10573
3       10573  10535   10677
3       10677  10573   10682
3       10682  10677   10856
3       10856  10682   NULL
...
*/

----------------------------------------------------------------------
-- FIRST_VALUE, LAST_VALUE, NTH_VALUE
----------------------------------------------------------------------

-- Listing 2-17: Query with FIRST_VALUE and LAST_VALUE
SELECT custid, orderdate, orderid, val,
  FIRST_VALUE(val) OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN UNBOUNDED PRECEDING
                                 AND CURRENT ROW) AS val_firstorder,
  LAST_VALUE(val)  OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN CURRENT ROW
                                 AND UNBOUNDED FOLLOWING) AS val_lastorder
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

/*
custid  orderdate   orderid  val      val_firstorder  val_lastorder
------- ----------- -------- -------- --------------- --------------
1       2018-08-25  10643    814.50   814.50          933.50
1       2018-10-03  10692    878.00   814.50          933.50
1       2018-10-13  10702    330.00   814.50          933.50
1       2019-01-15  10835    845.80   814.50          933.50
1       2019-03-16  10952    471.20   814.50          933.50
1       2019-04-09  11011    933.50   814.50          933.50
2       2017-09-18  10308    88.80    88.80           514.40
2       2018-08-08  10625    479.75   88.80           514.40
2       2018-11-28  10759    320.00   88.80           514.40
2       2019-03-04  10926    514.40   88.80           514.40
3       2017-11-27  10365    403.20   403.20          660.00
3       2018-04-15  10507    749.06   403.20          660.00
3       2018-05-13  10535    1940.85  403.20          660.00
3       2018-06-19  10573    2082.00  403.20          660.00
3       2018-09-22  10677    813.37   403.20          660.00
3       2018-09-25  10682    375.50   403.20          660.00
3       2019-01-28  10856    660.00   403.20          660.00
...
*/

-- Listing 2-18: Query with FIRST_VALUE and LAST_VALUE Embedded in Calculations
SELECT custid, orderdate, orderid, val,
  val - FIRST_VALUE(val) OVER(PARTITION BY custid
                              ORDER BY orderdate, orderid
                              ROWS BETWEEN UNBOUNDED PRECEDING
                                       AND CURRENT ROW) AS difffirst,
  val - LAST_VALUE(val)  OVER(PARTITION BY custid
                              ORDER BY orderdate, orderid
                              ROWS BETWEEN CURRENT ROW
                                       AND UNBOUNDED FOLLOWING) AS difflast
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

/*
custid  orderdate   orderid  val     difffirst  difflast
------- ----------- -------- ------- ---------- ---------
1       2018-08-25  10643    814.50  0.00       -119.00
1       2018-10-03  10692    878.00  63.50      -55.50
1       2018-10-13  10702    330.00  -484.50    -603.50
1       2019-01-15  10835    845.80  31.30      -87.70
1       2019-03-16  10952    471.20  -343.30    -462.30
1       2019-04-09  11011    933.50  119.00     0.00
2       2017-09-18  10308    88.80   0.00       -425.60
2       2018-08-08  10625    479.75  390.95     -34.65
2       2018-11-28  10759    320.00  231.20     -194.40
2       2019-03-04  10926    514.40  425.60     0.00
3       2017-11-27  10365    403.20  0.00       -256.80
3       2018-04-15  10507    749.06  345.86     89.06
3       2018-05-13  10535    1940.8  1537.65    1280.85
3       2018-06-19  10573    2082.0  1678.80    1422.00
3       2018-09-22  10677    813.37  410.17     153.37
3       2018-09-25  10682    375.50  -27.70     -284.50
3       2019-01-28  10856    660.00  256.80     0.00
...
*/

-- Listing 2-19: Query Emulating FIRST_VALUE, LAST_VALUE, and NTH_VALUE without these Functions
WITH OrdersRN AS
(
  SELECT custid, val,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY orderdate, orderid) AS rna,
    ROW_NUMBER() OVER(PARTITION BY custid
                      ORDER BY orderdate DESC, orderid DESC) AS rnd
  FROM Sales.OrderValues
),
Agg AS
(
  SELECT custid,
    MAX(CASE WHEN rna = 1 THEN val END) AS firstorderval,
    MAX(CASE WHEN rnd = 1 THEN val END) AS lastorderval,
    MAX(CASE WHEN rna = 3 THEN val END) AS thirdorderval
  FROM OrdersRN
  GROUP BY custid
)
SELECT O.custid, O.orderdate, O.orderid, O.val,
  A.firstorderval, A.lastorderval, A.thirdorderval
FROM Sales.OrderValues AS O
  INNER JOIN Agg AS A
    ON O.custid = A.custid
ORDER BY custid, orderdate, orderid;

/*
custid  orderdate   orderid  val      firstorderval  lastorderval  thirdorderval
------- ----------- -------- -------- -------------- ------------- --------------
1       2018-08-25  10643    814.50   814.50         933.50        330.00
1       2018-10-03  10692    878.00   814.50         933.50        330.00
1       2018-10-13  10702    330.00   814.50         933.50        330.00
1       2019-01-15  10835    845.80   814.50         933.50        330.00
1       2019-03-16  10952    471.20   814.50         933.50        330.00
1       2019-04-09  11011    933.50   814.50         933.50        330.00
2       2017-09-18  10308    88.80    88.80          514.40        320.00
2       2018-08-08  10625    479.75   88.80          514.40        320.00
2       2018-11-28  10759    320.00   88.80          514.40        320.00
2       2019-03-04  10926    514.40   88.80          514.40        320.00
3       2017-11-27  10365    403.20   403.20         660.00        1940.85
3       2018-04-15  10507    749.06   403.20         660.00        1940.85
3       2018-05-13  10535    1940.85  403.20         660.00        1940.85
3       2018-06-19  10573    2082.00  403.20         660.00        1940.85
3       2018-09-22  10677    813.37   403.20         660.00        1940.85
3       2018-09-25  10682    375.50   403.20         660.00        1940.85
3       2019-01-28  10856    660.00   403.20         660.00        1940.85
...
*/

----------------------------------------------------------------------
-- RESPECT NULLS | IGNORE NULLS
----------------------------------------------------------------------

-- Listing 2-20: Code to Create and Populate T1
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

-- workaround in SQL Server , Step 1
SELECT id, col1,
  CASE WHEN col1 IS NOT NULL THEN id END AS goodid
FROM dbo.T1;

/*
id   col1  goodid
---- ----- -------
2    NULL  NULL
3    10    3
5    -1    5
7    NULL  NULL
11   NULL  NULL
13   -12   13
17   NULL  NULL
19   NULL  NULL
23   1759  23
*/

-- Step 2
SELECT id, col1,
  MAX(CASE WHEN col1 IS NOT NULL THEN id END)
    OVER(ORDER BY id ROWS UNBOUNDED PRECEDING) AS grp
FROM dbo.T1;

/*
id   col1  grp
---- ----- -----
2    NULL  NULL
3    10    3
5    -1    5
7    NULL  5
11   NULL  5
13   -12   13
17   NULL  13
19   NULL  13
23   1759  23
*/

-- Step 3
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
