---------------------------------------------------------------------
-- T-SQL Window Functions Second Edition
-- Chapter 04 - Row Pattern Recognition in SQL
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Background
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Feature R010, “Row pattern recognition: FROM clause”
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Sample Task
---------------------------------------------------------------------

-- Listing 4-1: Sample Data in Microsoft SQL Server
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Ticker;

CREATE TABLE dbo.Ticker
(
  symbol    VARCHAR(10)    NOT NULL,
  tradedate DATE           NOT NULL,
  price     NUMERIC(12, 2) NOT NULL,
  CONSTRAINT PK_Ticker
    PRIMARY KEY (symbol, tradedate)
);
GO

INSERT INTO dbo.Ticker(symbol, tradedate, price) VALUES
  ('STOCK1', '20190212', 150.00),
  ('STOCK1', '20190213', 151.00),
  ('STOCK1', '20190214', 148.00),
  ('STOCK1', '20190215', 146.00),
  ('STOCK1', '20190218', 142.00),
  ('STOCK1', '20190219', 144.00),
  ('STOCK1', '20190220', 152.00),
  ('STOCK1', '20190221', 152.00),
  ('STOCK1', '20190222', 153.00),
  ('STOCK1', '20190225', 154.00),
  ('STOCK1', '20190226', 154.00),
  ('STOCK1', '20190227', 154.00),
  ('STOCK1', '20190228', 153.00),
  ('STOCK1', '20190301', 145.00),
  ('STOCK1', '20190304', 140.00),
  ('STOCK1', '20190305', 142.00),
  ('STOCK1', '20190306', 143.00),
  ('STOCK1', '20190307', 142.00),
  ('STOCK1', '20190308', 140.00),
  ('STOCK1', '20190311', 138.00),
  ('STOCK2', '20190212', 330.00),
  ('STOCK2', '20190213', 329.00),
  ('STOCK2', '20190214', 329.00),
  ('STOCK2', '20190215', 326.00),
  ('STOCK2', '20190218', 325.00),
  ('STOCK2', '20190219', 326.00),
  ('STOCK2', '20190220', 328.00),
  ('STOCK2', '20190221', 326.00),
  ('STOCK2', '20190222', 320.00),
  ('STOCK2', '20190225', 317.00),
  ('STOCK2', '20190226', 319.00),
  ('STOCK2', '20190227', 325.00),
  ('STOCK2', '20190228', 322.00),
  ('STOCK2', '20190301', 324.00),
  ('STOCK2', '20190304', 321.00),
  ('STOCK2', '20190305', 319.00),
  ('STOCK2', '20190306', 322.00),
  ('STOCK2', '20190307', 326.00),
  ('STOCK2', '20190308', 326.00),
  ('STOCK2', '20190311', 324.00);

SELECT symbol, tradedate, price
FROM dbo.Ticker;

-- Listing 4-2: Contents of dbo.Ticker Table
/*
symbol  tradedate   price
------- ----------- -------
STOCK1  2019-02-12  150.00
STOCK1  2019-02-13  151.00
STOCK1  2019-02-14  148.00
STOCK1  2019-02-15  146.00
STOCK1  2019-02-18  142.00
STOCK1  2019-02-19  144.00
STOCK1  2019-02-20  152.00
STOCK1  2019-02-21  152.00
STOCK1  2019-02-22  153.00
STOCK1  2019-02-25  154.00
STOCK1  2019-02-26  154.00
STOCK1  2019-02-27  154.00
STOCK1  2019-02-28  153.00
STOCK1  2019-03-01  145.00
STOCK1  2019-03-04  140.00
STOCK1  2019-03-05  142.00
STOCK1  2019-03-06  143.00
STOCK1  2019-03-07  142.00
STOCK1  2019-03-08  140.00
STOCK1  2019-03-11  138.00
STOCK2  2019-02-12  330.00
STOCK2  2019-02-13  329.00
STOCK2  2019-02-14  329.00
STOCK2  2019-02-15  326.00
STOCK2  2019-02-18  325.00
STOCK2  2019-02-19  326.00
STOCK2  2019-02-20  328.00
STOCK2  2019-02-21  326.00
STOCK2  2019-02-22  320.00
STOCK2  2019-02-25  317.00
STOCK2  2019-02-26  319.00
STOCK2  2019-02-27  325.00
STOCK2  2019-02-28  322.00
STOCK2  2019-03-01  324.00
STOCK2  2019-03-04  321.00
STOCK2  2019-03-05  319.00
STOCK2  2019-03-06  322.00
STOCK2  2019-03-07  326.00
STOCK2  2019-03-08  326.00
STOCK2  2019-03-11  324.00
*/

-- Listing 4-3: Sample Data in Oracle
DROP TABLE Ticker;

CREATE TABLE Ticker
(
  symbol    VARCHAR2(10) NOT NULL,
  tradedate DATE         NOT NULL,
  price     NUMBER       NOT NULL,
  CONSTRAINT PK_Ticker
    PRIMARY KEY (symbol, tradedate)
);

INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '12-Feb-19', 150.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '13-Feb-19', 151.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '14-Feb-19', 148.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '15-Feb-19', 146.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '18-Feb-19', 142.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '19-Feb-19', 144.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '20-Feb-19', 152.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '21-Feb-19', 152.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '22-Feb-19', 153.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '25-Feb-19', 154.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '26-Feb-19', 154.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '27-Feb-19', 154.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '28-Feb-19', 153.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '01-Mar-19', 145.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '04-Mar-19', 140.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '05-Mar-19', 142.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '06-Mar-19', 143.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '07-Mar-19', 142.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '08-Mar-19', 140.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK1', '11-Mar-19', 138.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '12-Feb-19', 330.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '13-Feb-19', 329.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '14-Feb-19', 329.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '15-Feb-19', 326.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '18-Feb-19', 325.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '19-Feb-19', 326.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '20-Feb-19', 328.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '21-Feb-19', 326.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '22-Feb-19', 320.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '25-Feb-19', 317.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '26-Feb-19', 319.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '27-Feb-19', 325.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '28-Feb-19', 322.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '01-Mar-19', 324.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '04-Mar-19', 321.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '05-Mar-19', 319.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '06-Mar-19', 322.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '07-Mar-19', 326.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '08-Mar-19', 326.00);
INSERT INTO Ticker(symbol, tradedate, price)
  VALUES('STOCK2', '11-Mar-19', 324.00);
COMMIT;

SELECT symbol, tradedate, price
FROM Ticker;

-- Listing 4-4: Contents of Ticker Table
/*
SYMBOL     TRADEDATE      PRICE
---------- --------- ----------
STOCK1     12-FEB-19        150
STOCK1     13-FEB-19        151
STOCK1     14-FEB-19        148
STOCK1     15-FEB-19        146
STOCK1     18-FEB-19        142
STOCK1     19-FEB-19        144
STOCK1     20-FEB-19        152
STOCK1     21-FEB-19        152
STOCK1     22-FEB-19        153
STOCK1     25-FEB-19        154
STOCK1     26-FEB-19        154
STOCK1     27-FEB-19        154
STOCK1     28-FEB-19        153
STOCK1     01-MAR-19        145
STOCK1     04-MAR-19        140
STOCK1     05-MAR-19        142
STOCK1     06-MAR-19        143
STOCK1     07-MAR-19        142
STOCK1     08-MAR-19        140
STOCK1     11-MAR-19        138
STOCK2     12-FEB-19        330
STOCK2     13-FEB-19        329
STOCK2     14-FEB-19        329
STOCK2     15-FEB-19        326
STOCK2     18-FEB-19        325
STOCK2     19-FEB-19        326
STOCK2     20-FEB-19        328
STOCK2     21-FEB-19        326
STOCK2     22-FEB-19        320
STOCK2     25-FEB-19        317
STOCK2     26-FEB-19        319
STOCK2     27-FEB-19        325
STOCK2     28-FEB-19        322
STOCK2     01-MAR-19        324
STOCK2     04-MAR-19        321
STOCK2     05-MAR-19        319
STOCK2     06-MAR-19        322
STOCK2     07-MAR-19        326
STOCK2     08-MAR-19        326
STOCK2     11-MAR-19        324
*/

---------------------------------------------------------------------
-- ONE ROW PER MATCH
---------------------------------------------------------------------

-- LISTING 4-5: Solution Query for Sample Task with the ONE ROW PER MATCH Option
SELECT
  MR.symbol, MR.matchnum, MR.startdate, MR.startprice,
  MR.bottomdate, MR.bottomprice, MR.enddate, MR.endprice, MR.maxprice
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(B.tradedate) AS bottomdate,
      LAST(B.price) AS bottomprice,
      LAST(C.tradedate) AS enddate, -- same as LAST(tradedate)
      LAST(C.price) AS endprice,
      MAX(U.price) AS maxprice -- same as MAX(price)
    ONE ROW PER MATCH -- default
    AFTER MATCH SKIP PAST LAST ROW -- default
    PATTERN (A B+ C+)
    SUBSET U = (A, B, C)
    DEFINE
      -- A defaults to True, matches any row, same as A AS 1 = 1
      B AS B.price < PREV(B.price),
      C AS C.price > PREV(C.price)
  ) AS MR;

/*
symbol  matchnum  startdate   startprice bottomdate  bottomprice enddate     endprice  maxprice
------- --------- ----------- ---------- ----------- ----------- ----------- --------- ---------
STOCK1  1         2019-02-13  151.00     2019-02-18  142.00      2019-02-20  152.00    152.00
STOCK1  2         2019-02-27  154.00     2019-03-04  140.00      2019-03-06  143.00    154.00
STOCK2  1         2019-02-14  329.00     2019-02-18  325.00      2019-02-20  328.00    329.00
STOCK2  2         2019-02-21  326.00     2019-02-25  317.00      2019-02-27  325.00    326.00
STOCK2  3         2019-03-01  324.00     2019-03-05  319.00      2019-03-07  326.00    326.00
*/

-- solution query in Oracle
-- can't use AS clause to assign a table alias; use space instead
-- remove table qualifier, or use user name as qualifier
-- LISTING 4-6: Solution Query for Sample Task with the ONE ROW PER MATCH Option in Oracle
SELECT
  MR.symbol, MR.matchnum, MR.startdate, MR.startprice,
  MR.bottomdate, MR.bottomprice, MR.enddate, MR.endprice, MR.maxprice
FROM Ticker -- removed qualifier
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(B.tradedate) AS bottomdate,
      LAST(B.price) AS bottomprice,
      LAST(C.tradedate) AS enddate,
      LAST(C.price) AS endprice,
      MAX(U.price) AS maxprice
    ONE ROW PER MATCH
    AFTER MATCH SKIP PAST LAST ROW
    PATTERN (A B+ C+)
    SUBSET U = (A, B, C)
    DEFINE
      B AS B.price < PREV(B.price),
      C AS C.price > PREV(C.price)
  ) MR; -- removed AS clause

/*
SYMBOL  MATCHNUM  STARTDATE   STARTPRICE BOTTOMDATE  BOTTOMPRICE ENDDATE     ENDPRICE  MAXPRICE
------- --------- ----------- ---------- ----------- ----------- ----------- --------- ---------
STOCK1  1         13-FEB-19   151        18-FEB-19   142         20-FEB-19   152       152
STOCK1  2         27-FEB-19   154        04-MAR-19   140         06-MAR-19   143       154
STOCK2  1         14-FEB-19   329        18-FEB-19   325         20-FEB-19   328       329
STOCK2  2         21-FEB-19   326        25-FEB-19   317         27-FEB-19   325       326
STOCK2  3         01-MAR-19   324        05-MAR-19   319         07-MAR-19   326       326
*/

---------------------------------------------------------------------
-- ALL ROWS PER MATCH
---------------------------------------------------------------------

-- Listing 4-7: Sample Query Showing All Rows Per Match
SELECT
  MR.symbol, MR.tradedate, MR.price, MR.matchnum, MR.classy, 
  MR.startdate, MR.startprice, MR.bottomdate, MR.bottomprice,
  MR.enddate, MR.endprice, MR.maxprice
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      CLASSIFIER() AS classy,
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(B.tradedate) AS bottomdate,
      LAST(B.price) AS bottomprice,
      LAST(C.tradedate) AS enddate,
      LAST(C.price) AS endprice,
      MAX(U.price) AS maxprice
    ALL ROWS PER MATCH
    AFTER MATCH SKIP PAST LAST ROW
    PATTERN (A B+ C+)
    SUBSET U = (A, B, C)
    DEFINE
      B AS B.price < PREV(B.price),
      C AS C.price > PREV(C.price)
  ) AS MR;

/*
symbol  tradedate   price   matchnum  classy  startdate  startprice bottomdate  bottomprice enddate     endprice   maxprice
------- ----------- ------- --------- ------- ---------- ---------- ----------- ----------- ----------- ---------- ----------
STOCK1  2019-02-13  151.00  1         A       2019-02-13 151.00     NULL        NULL        NULL        NULL       151.00
STOCK1  2019-02-14  148.00  1         B       2019-02-13 151.00     2019-02-14  148.00      NULL        NULL       151.00
STOCK1  2019-02-15  146.00  1         B       2019-02-13 151.00     2019-02-15  146.00      NULL        NULL       151.00
STOCK1  2019-02-18  142.00  1         B       2019-02-13 151.00     2019-02-18  142.00      NULL        NULL       151.00
STOCK1  2019-02-19  144.00  1         C       2019-02-13 151.00     2019-02-18  142.00      2019-02-19  144.00     151.00
STOCK1  2019-02-20  152.00  1         C       2019-02-13 151.00     2019-02-18  142.00      2019-02-20  152.00     152.00
STOCK1  2019-02-27  154.00  2         A       2019-02-27 154.00     NULL        NULL        NULL        NULL       154.00
STOCK1  2019-02-28  153.00  2         B       2019-02-27 154.00     2019-02-28  153.00      NULL        NULL       154.00
STOCK1  2019-03-01  145.00  2         B       2019-02-27 154.00     2019-03-01  145.00      NULL        NULL       154.00
STOCK1  2019-03-04  140.00  2         B       2019-02-27 154.00     2019-03-04  140.00      NULL        NULL       154.00
STOCK1  2019-03-05  142.00  2         C       2019-02-27 154.00     2019-03-04  140.00      2019-03-05  142.00     154.00
STOCK1  2019-03-06  143.00  2         C       2019-02-27 154.00     2019-03-04  140.00      2019-03-06  143.00     154.00
STOCK2  2019-02-14  329.00  1         A       2019-02-14 329.00     NULL        NULL        NULL        NULL       329.00
STOCK2  2019-02-15  326.00  1         B       2019-02-14 329.00     2019-02-15  326.00      NULL        NULL       329.00
STOCK2  2019-02-18  325.00  1         B       2019-02-14 329.00     2019-02-18  325.00      NULL        NULL       329.00
STOCK2  2019-02-19  326.00  1         C       2019-02-14 329.00     2019-02-18  325.00      2019-02-19  326.00     329.00
STOCK2  2019-02-20  328.00  1         C       2019-02-14 329.00     2019-02-18  325.00      2019-02-20  328.00     329.00
STOCK2  2019-02-21  326.00  2         A       2019-02-21 326.00     NULL        NULL        NULL        NULL       326.00
STOCK2  2019-02-22  320.00  2         B       2019-02-21 326.00     2019-02-22  320.00      NULL        NULL       326.00
STOCK2  2019-02-25  317.00  2         B       2019-02-21 326.00     2019-02-25  317.00      NULL        NULL       326.00
STOCK2  2019-02-26  319.00  2         C       2019-02-21 326.00     2019-02-25  317.00      2019-02-26  319.00     326.00
STOCK2  2019-02-27  325.00  2         C       2019-02-21 326.00     2019-02-25  317.00      2019-02-27  325.00     326.00
STOCK2  2019-03-01  324.00  3         A       2019-03-01 324.00     NULL        NULL        NULL        NULL       324.00
STOCK2  2019-03-04  321.00  3         B       2019-03-01 324.00     2019-03-04  321.00      NULL        NULL       324.00
STOCK2  2019-03-05  319.00  3         B       2019-03-01 324.00     2019-03-05  319.00      NULL        NULL       324.00
STOCK2  2019-03-06  322.00  3         C       2019-03-01 324.00     2019-03-05  319.00      2019-03-06  322.00     324.00
STOCK2  2019-03-07  326.00  3         C       2019-03-01 324.00     2019-03-05  319.00      2019-03-07  326.00     326.00

(27 rows affected)
*/

-- Listing 4-8: Query Using ALL ROWS PER MATCH WITH UNMATCHED ROWS
SELECT
  MR.symbol, MR.tradedate, MR.price, MR.matchnum, MR.classy, 
  MR.startdate, MR.startprice, MR.bottomdate, MR.bottomprice, 
  MR.enddate, MR.endprice, MR.maxprice
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      CLASSIFIER() AS classy,
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(B.tradedate) AS bottomdate,
      LAST(B.price) AS bottomprice,
      LAST(C.tradedate) AS enddate,
      LAST(C.price) AS endprice,
      MAX(U.price) AS maxprice
    ALL ROWS PER MATCH WITH UNMATCHED ROWS
    AFTER MATCH SKIP PAST LAST ROW
    PATTERN (A B+ C+)
    SUBSET U = (A, B, C)
    DEFINE
      B AS B.price < PREV(B.price),
      C AS C.price > PREV(C.price)
  ) AS MR;

/*
symbol  tradedate   price   matchnum  classy  startdate   startprice bottomdate  bottomprice  enddate     endprice  maxprice
------- ----------- ------- --------- ------- ----------- ---------- ----------- ------------ ----------- --------- ---------
STOCK1  2019-02-12  150.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-02-13  151.00  1         A       2019-02-13  151.00     NULL        NULL         NULL        NULL      151.00
STOCK1  2019-02-14  148.00  1         B       2019-02-13  151.00     2019-02-14  148.00       NULL        NULL      151.00
STOCK1  2019-02-15  146.00  1         B       2019-02-13  151.00     2019-02-15  146.00       NULL        NULL      151.00
STOCK1  2019-02-18  142.00  1         B       2019-02-13  151.00     2019-02-18  142.00       NULL        NULL      151.00
STOCK1  2019-02-19  144.00  1         C       2019-02-13  151.00     2019-02-18  142.00       2019-02-19  144.00    151.00
STOCK1  2019-02-20  152.00  1         C       2019-02-13  151.00     2019-02-18  142.00       2019-02-20  152.00    152.00
STOCK1  2019-02-21  152.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-02-22  153.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-02-25  154.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-02-26  154.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-02-27  154.00  2         A       2019-02-27  154.00     NULL        NULL         NULL        NULL      154.00
STOCK1  2019-02-28  153.00  2         B       2019-02-27  154.00     2019-02-28  153.00       NULL        NULL      154.00
STOCK1  2019-03-01  145.00  2         B       2019-02-27  154.00     2019-03-01  145.00       NULL        NULL      154.00
STOCK1  2019-03-04  140.00  2         B       2019-02-27  154.00     2019-03-04  140.00       NULL        NULL      154.00
STOCK1  2019-03-05  142.00  2         C       2019-02-27  154.00     2019-03-04  140.00       2019-03-05  142.00    154.00
STOCK1  2019-03-06  143.00  2         C       2019-02-27  154.00     2019-03-04  140.00       2019-03-06  143.00    154.00
STOCK1  2019-03-07  142.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-03-08  140.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK1  2019-03-11  138.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK2  2019-02-12  330.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK2  2019-02-13  329.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK2  2019-02-14  329.00  1         A       2019-02-14  329.00     NULL        NULL         NULL        NULL      329.00
STOCK2  2019-02-15  326.00  1         B       2019-02-14  329.00     2019-02-15  326.00       NULL        NULL      329.00
STOCK2  2019-02-18  325.00  1         B       2019-02-14  329.00     2019-02-18  325.00       NULL        NULL      329.00
STOCK2  2019-02-19  326.00  1         C       2019-02-14  329.00     2019-02-18  325.00       2019-02-19  326.00    329.00
STOCK2  2019-02-20  328.00  1         C       2019-02-14  329.00     2019-02-18  325.00       2019-02-20  328.00    329.00
STOCK2  2019-02-21  326.00  2         A       2019-02-21  326.00     NULL        NULL         NULL        NULL      326.00
STOCK2  2019-02-22  320.00  2         B       2019-02-21  326.00     2019-02-22  320.00       NULL        NULL      326.00
STOCK2  2019-02-25  317.00  2         B       2019-02-21  326.00     2019-02-25  317.00       NULL        NULL      326.00
STOCK2  2019-02-26  319.00  2         C       2019-02-21  326.00     2019-02-25  317.00       2019-02-26  319.00    326.00
STOCK2  2019-02-27  325.00  2         C       2019-02-21  326.00     2019-02-25  317.00       2019-02-27  325.00    326.00
STOCK2  2019-02-28  322.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL
STOCK2  2019-03-01  324.00  3         A       2019-03-01  324.00     NULL        NULL         NULL        NULL      324.00
STOCK2  2019-03-04  321.00  3         B       2019-03-01  324.00     2019-03-04  321.00       NULL        NULL      324.00
STOCK2  2019-03-05  319.00  3         B       2019-03-01  324.00     2019-03-05  319.00       NULL        NULL      324.00
STOCK2  2019-03-06  322.00  3         C       2019-03-01  324.00     2019-03-05  319.00       2019-03-06  322.00    324.00
STOCK2  2019-03-07  326.00  3         C       2019-03-01  324.00     2019-03-05  319.00       2019-03-07  326.00    326.00
STOCK2  2019-03-08  326.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL 
STOCK2  2019-03-11  324.00  NULL      NULL    NULL        NULL       NULL        NULL         NULL        NULL      NULL 

(40 rows affected)
*/

-- ALL ROWS PER MATCH SHOW EMPTY MATCHES
-- for patterns like A*, shows empty matches
-- Listing 4-9: Query Showing Empty Matches
SELECT
  MR.symbol, MR.tradedate, MR.matchnum, MR.classy,
  MR.startdate, MR.startprice, MR.enddate, MR.endprice, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      CLASSIFIER() AS classy,
      FIRST(A.tradedate) AS startdate,
      FIRST(A.price) AS startprice,
      LAST(A.tradedate) AS enddate, 
      LAST(A.price) AS endprice
    ALL ROWS PER MATCH -- defaults to SHOW EMPTY MATCHES
    AFTER MATCH SKIP PAST LAST ROW
    PATTERN (A*)
    DEFINE
      A AS A.price < PREV(A.price)
  ) AS MR;

/*
symbol  tradedate   matchnum  classy  startdate   startprice enddate    endprice  price
------- ----------- --------- ------- ----------- ---------- ---------- --------- -------
STOCK1  2019-02-12  1         NULL    NULL        NULL       NULL       NULL      150.00
STOCK1  2019-02-13  2         NULL    NULL        NULL       NULL       NULL      151.00
STOCK1  2019-02-14  3         A       2019-02-14  148.00     2019-02-14 148       148.00
STOCK1  2019-02-15  3         A       2019-02-14  148.00     2019-02-15 146       146.00
STOCK1  2019-02-18  3         A       2019-02-14  148.00     2019-02-18 142       142.00
STOCK1  2019-02-19  4         NULL    NULL        NULL       NULL       NULL      144.00
STOCK1  2019-02-20  5         NULL    NULL        NULL       NULL       NULL      152.00
STOCK1  2019-02-21  6         NULL    NULL        NULL       NULL       NULL      152.00
STOCK1  2019-02-22  7         NULL    NULL        NULL       NULL       NULL      153.00
STOCK1  2019-02-25  8         NULL    NULL        NULL       NULL       NULL      154.00
STOCK1  2019-02-26  9         NULL    NULL        NULL       NULL       NULL      154.00
STOCK1  2019-02-27  10        NULL    NULL        NULL       NULL       NULL      154.00
STOCK1  2019-02-28  11        A       2019-02-28  153.00     2019-02-28 153       153.00
STOCK1  2019-03-01  11        A       2019-02-28  153.00     2019-03-01 145       145.00
STOCK1  2019-03-04  11        A       2019-02-28  153.00     2019-03-04 140       140.00
STOCK1  2019-03-05  12        NULL    NULL        NULL       NULL       NULL      142.00
STOCK1  2019-03-06  13        NULL    NULL        NULL       NULL       NULL      143.00
STOCK1  2019-03-07  14        A       2019-03-07  142.00     2019-03-07 142       142.00
STOCK1  2019-03-08  14        A       2019-03-07  142.00     2019-03-08 140       140.00
STOCK1  2019-03-11  14        A       2019-03-07  142.00     2019-03-11 138       138.00
STOCK2  2019-02-12  1         NULL    NULL        NULL       NULL       NULL      330.00
STOCK2  2019-02-13  2         A       2019-02-13  329.00     2019-02-13 329       329.00
STOCK2  2019-02-14  3         NULL    NULL        NULL       NULL       NULL      329.00
STOCK2  2019-02-15  4         A       2019-02-15  326.00     2019-02-15 326       326.00
STOCK2  2019-02-18  4         A       2019-02-15  326.00     2019-02-18 325       325.00
STOCK2  2019-02-19  5         NULL    NULL        NULL       NULL       NULL      326.00
STOCK2  2019-02-20  6         NULL    NULL        NULL       NULL       NULL      328.00
STOCK2  2019-02-21  7         A       2019-02-21  326.00     2019-02-21 326       326.00
STOCK2  2019-02-22  7         A       2019-02-21  326.00     2019-02-22 320       320.00
STOCK2  2019-02-25  7         A       2019-02-21  326.00     2019-02-25 317       317.00
STOCK2  2019-02-26  8         NULL    NULL        NULL       NULL       NULL      319.00
STOCK2  2019-02-27  9         NULL    NULL        NULL       NULL       NULL      325.00
STOCK2  2019-02-28  10        A       2019-02-28  322.00     2019-02-28 322       322.00
STOCK2  2019-03-01  11        NULL    NULL        NULL       NULL       NULL      324.00
STOCK2  2019-03-04  12        A       2019-03-04  321.00     2019-03-04 321       321.00
STOCK2  2019-03-05  12        A       2019-03-04  321.00     2019-03-05 319       319.00
STOCK2  2019-03-06  13        NULL    NULL        NULL       NULL       NULL      322.00
STOCK2  2019-03-07  14        NULL    NULL        NULL       NULL       NULL      326.00
STOCK2  2019-03-08  15        NULL    NULL        NULL       NULL       NULL      326.00
STOCK2  2019-03-11  16        A       2019-03-11  324.00     2019-03-11 324       324.00

(40 rows affected)
*/

-- ALL ROWS PER MATCH OMIT EMPTY MATCHES
-- Listing 4-10: Query Omitting Empty Matches
SELECT
  MR.symbol, MR.tradedate, MR.matchnum, MR.classy,
  MR.startdate, MR.startprice, MR.enddate, MR.endprice, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchnum,
      CLASSIFIER() AS classy,
      FIRST(A.tradedate) AS startdate,
      FIRST(A.price) AS startprice,
      LAST(A.tradedate) AS enddate, 
      LAST(A.price) AS endprice
    ALL ROWS PER MATCH OMIT EMPTY MATCHES
    AFTER MATCH SKIP PAST LAST ROW
    PATTERN (A*)
    DEFINE
      A AS A.price < PREV(A.price)
  ) AS MR;

/*
symbol  tradedate   matchnum  classy  startdate   startprice enddate    endprice  price
------- ----------- --------- ------- ----------- ---------- ---------- --------- -------
STOCK1  2019-02-14  3         A       2019-02-14  148.00     2019-02-14 148       148.00
STOCK1  2019-02-15  3         A       2019-02-14  148.00     2019-02-15 146       146.00
STOCK1  2019-02-18  3         A       2019-02-14  148.00     2019-02-18 142       142.00
STOCK1  2019-02-28  11        A       2019-02-28  153.00     2019-02-28 153       153.00
STOCK1  2019-03-01  11        A       2019-02-28  153.00     2019-03-01 145       145.00
STOCK1  2019-03-04  11        A       2019-02-28  153.00     2019-03-04 140       140.00
STOCK1  2019-03-07  14        A       2019-03-07  142.00     2019-03-07 142       142.00
STOCK1  2019-03-08  14        A       2019-03-07  142.00     2019-03-08 140       140.00
STOCK1  2019-03-11  14        A       2019-03-07  142.00     2019-03-11 138       138.00
STOCK2  2019-02-13  2         A       2019-02-13  329.00     2019-02-13 329       329.00
STOCK2  2019-02-15  4         A       2019-02-15  326.00     2019-02-15 326       326.00
STOCK2  2019-02-18  4         A       2019-02-15  326.00     2019-02-18 325       325.00
STOCK2  2019-02-21  7         A       2019-02-21  326.00     2019-02-21 326       326.00
STOCK2  2019-02-22  7         A       2019-02-21  326.00     2019-02-22 320       320.00
STOCK2  2019-02-25  7         A       2019-02-21  326.00     2019-02-25 317       317.00
STOCK2  2019-02-28  10        A       2019-02-28  322.00     2019-02-28 322       322.00
STOCK2  2019-03-04  12        A       2019-03-04  321.00     2019-03-04 321       321.00
STOCK2  2019-03-05  12        A       2019-03-04  321.00     2019-03-05 319       319.00
STOCK2  2019-03-11  16        A       2019-03-11  324.00     2019-03-11 324       324.00

(19 rows affected)
*/

---------------------------------------------------------------------
-- RUNNING versus FINAL semantics
---------------------------------------------------------------------

-- Runs of 3+ increasing values, generally with cur price >= prev price, and with last price > first price
-- Listing 4-11: Query Demonstrating Running Versus Final Semantics, Showing All Rows Per Match
SELECT
  MR.symbol, MR.tradedate, MR.matchno, MR.classy,
  MR.startdate, MR.startprice, MR.enddate, MR.endprice,
  MR.runcnt, MR.finalcnt, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchno,
      CLASSIFIER() AS classy,
      A.tradedate AS startdate,
      A.price AS startprice,
      FINAL LAST(tradedate) AS enddate,
      FINAL LAST(price) AS endprice,
      RUNNING COUNT(*) AS runcnt, -- default is running
      FINAL COUNT(*) AS finalcnt
    ALL ROWS PER MATCH
    PATTERN (A B* C+)
    DEFINE
      B AS B.price >= PREV(B.price),
      C AS C.price >= PREV(C.price)
           AND C.price > A.price
           AND COUNT(*) >= 3
  ) AS MR;

/*
symbol  tradedate   matchno  classy  startdate   startprice enddate     endprice  runcnt  finalcnt  price
------- ----------- -------- ------- ----------- ---------- ----------- --------- ------- --------- -------
STOCK1  2019-02-18  1        A       2019-02-18  142.00     2019-02-27  154.00    1       8         142.00
STOCK1  2019-02-19  1        B       2019-02-18  142.00     2019-02-27  154.00    2       8         144.00
STOCK1  2019-02-20  1        B       2019-02-18  142.00     2019-02-27  154.00    3       8         152.00
STOCK1  2019-02-21  1        B       2019-02-18  142.00     2019-02-27  154.00    4       8         152.00
STOCK1  2019-02-22  1        B       2019-02-18  142.00     2019-02-27  154.00    5       8         153.00
STOCK1  2019-02-25  1        B       2019-02-18  142.00     2019-02-27  154.00    6       8         154.00
STOCK1  2019-02-26  1        B       2019-02-18  142.00     2019-02-27  154.00    7       8         154.00
STOCK1  2019-02-27  1        C       2019-02-18  142.00     2019-02-27  154.00    8       8         154.00
STOCK1  2019-03-04  2        A       2019-03-04  140.00     2019-03-06  143.00    1       3         140.00
STOCK1  2019-03-05  2        B       2019-03-04  140.00     2019-03-06  143.00    2       3         142.00
STOCK1  2019-03-06  2        C       2019-03-04  140.00     2019-03-06  143.00    3       3         143.00
STOCK2  2019-02-18  1        A       2019-02-18  325.00     2019-02-20  328.00    1       3         325.00
STOCK2  2019-02-19  1        B       2019-02-18  325.00     2019-02-20  328.00    2       3         326.00
STOCK2  2019-02-20  1        C       2019-02-18  325.00     2019-02-20  328.00    3       3         328.00
STOCK2  2019-02-25  2        A       2019-02-25  317.00     2019-02-27  325.00    1       3         317.00
STOCK2  2019-02-26  2        B       2019-02-25  317.00     2019-02-27  325.00    2       3         319.00
STOCK2  2019-02-27  2        C       2019-02-25  317.00     2019-02-27  325.00    3       3         325.00
STOCK2  2019-03-05  3        A       2019-03-05  319.00     2019-03-08  326.00    1       4         319.00
STOCK2  2019-03-06  3        B       2019-03-05  319.00     2019-03-08  326.00    2       4         322.00
STOCK2  2019-03-07  3        B       2019-03-05  319.00     2019-03-08  326.00    3       4         326.00
STOCK2  2019-03-08  3        C       2019-03-05  319.00     2019-03-08  326.00    4       4         326.00

(21 rows affected)
*/

-- Listing 4-12: Query Demonstrating Running Versus Final Semantics, Showing One Row Per Match
ONE ROW PER MATCH
SELECT
  MR.symbol, MR.matchno, MR.startdate, MR.startprice,
  MR.enddate, MR.endprice, MR.cnt
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchno,
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(tradedate) AS enddate,
      LAST(price) AS endprice,
      COUNT(*) AS cnt
    PATTERN (A B* C+)
    DEFINE
      B AS B.price >= PREV(B.price),
      C AS C.price >= PREV(C.price)
           AND C.price > A.price
           AND COUNT(*) >= 3
  ) AS MR;

/*
symbol  matchno  startdate   startprice enddate     endprice  cnt
------- -------- ----------- ---------- ----------- --------- ----
STOCK1  1        2019-02-18  142.00     2019-02-27  154.00    8
STOCK1  2        2019-03-04  140.00     2019-03-06  143.00    3
STOCK2  1        2019-02-18  325.00     2019-02-20  328.00    3
STOCK2  2        2019-02-25  317.00     2019-02-27  325.00    3
STOCK2  3        2019-03-05  319.00     2019-03-08  326.00    4
*/

---------------------------------------------------------------------
-- Nesting FIRST | LAST within PREV | NEXT
---------------------------------------------------------------------

-- can nest FIRST | LAST within PREV | NEXT
-- here we're getting the post last date and price
-- LISTING 4-13: Query Nesting the LAST Function within the NEXT Function
SELECT
  MR.symbol, MR.tradedate, MR.matchno, MR.classy, 
  MR.startdate, MR.startprice, MR.postenddate, MR.postendprice,
  MR.cnt, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      MATCH_NUMBER() AS matchno,
      CLASSIFIER() AS classy,
      A.tradedate AS startdate,
      A.price AS startprice,
      NEXT(FINAL LAST(tradedate), 1) AS postenddate,
      NEXT(FINAL LAST(price), 1) AS postendprice,
      RUNNING COUNT(*) AS cnt
    ALL ROWS PER MATCH
    PATTERN (A B* C+)
    DEFINE
      B AS B.price >= PREV(B.price),
      C AS C.price >= PREV(C.price)
           AND C.price > A.price
           AND COUNT(*) >= 3
  ) AS MR;

/*
symbol  tradedate   matchno  classy  startdate   startprice postenddate postendprice cnt  price
------- ----------- -------- ------- ----------- ---------- ----------- ------------ ---- -------
STOCK1  2019-02-18  1        A       2019-02-18  142.00     2019-02-28  153.00       1    142.00
STOCK1  2019-02-19  1        B       2019-02-18  142.00     2019-02-28  153.00       2    144.00
STOCK1  2019-02-20  1        B       2019-02-18  142.00     2019-02-28  153.00       3    152.00
STOCK1  2019-02-21  1        B       2019-02-18  142.00     2019-02-28  153.00       4    152.00
STOCK1  2019-02-22  1        B       2019-02-18  142.00     2019-02-28  153.00       5    153.00
STOCK1  2019-02-25  1        B       2019-02-18  142.00     2019-02-28  153.00       6    154.00
STOCK1  2019-02-26  1        B       2019-02-18  142.00     2019-02-28  153.00       7    154.00
STOCK1  2019-02-27  1        C       2019-02-18  142.00     2019-02-28  153.00       8    154.00
STOCK1  2019-03-04  2        A       2019-03-04  140.00     2019-03-07  142.00       1    140.00
STOCK1  2019-03-05  2        B       2019-03-04  140.00     2019-03-07  142.00       2    142.00
STOCK1  2019-03-06  2        C       2019-03-04  140.00     2019-03-07  142.00       3    143.00
STOCK2  2019-02-18  1        A       2019-02-18  325.00     2019-02-21  326.00       1    325.00
STOCK2  2019-02-19  1        B       2019-02-18  325.00     2019-02-21  326.00       2    326.00
STOCK2  2019-02-20  1        C       2019-02-18  325.00     2019-02-21  326.00       3    328.00
STOCK2  2019-02-25  2        A       2019-02-25  317.00     2019-02-28  322.00       1    317.00
STOCK2  2019-02-26  2        B       2019-02-25  317.00     2019-02-28  322.00       2    319.00
STOCK2  2019-02-27  2        C       2019-02-25  317.00     2019-02-28  322.00       3    325.00
STOCK2  2019-03-05  3        A       2019-03-05  319.00     2019-03-11  324.00       1    319.00
STOCK2  2019-03-06  3        B       2019-03-05  319.00     2019-03-11  324.00       2    322.00
STOCK2  2019-03-07  3        B       2019-03-05  319.00     2019-03-11  324.00       3    326.00
STOCK2  2019-03-08  3        C       2019-03-05  319.00     2019-03-11  324.00       4    326.00

(21 rows affected)
*/

---------------------------------------------------------------------
-- Feature R020, “Row pattern recognition: WINDOW clause”
---------------------------------------------------------------------

-- applicable only to window frames that start at the current row
-- the full window frame is subsequently reduced to just the rows constituting a pattern match
-- only one row pattern match per full window frame is sought
-- Listing 4-14: Query Demonstrating RPR in WINDOW Clause
SELECT
  T.symbol, T.tradedate, T.price,
  startdate  OVER W, startprice  OVER W,
  bottomdate OVER W, bottomprice OVER W,
  enddate    OVER W, endprice    OVER W,
  maxprice   OVER W
FROM dbo.Ticker T
WINDOW W AS
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      A.tradedate AS startdate,
      A.price AS startprice,
      LAST(B.tradedate) AS bottomdate,
      LAST(B.price) AS bottomprice,
      LAST(C.tradedate) AS enddate,
      LAST(C.price) AS endprice,
      MAX(U.price) AS maxprice
    ROWS BETWEEN CURRENT ROW
             AND UNBOUNDED FOLLOWING
    AFTER MATCH SKIP PAST LAST ROW
    INITIAL -- match must start at first row of full window frame
    PATTERN (A B+ C+)
    SUBSET U = (A, B, C)
    DEFINE
      B AS B.price < PREV(B.price),
      C AS C.price > PREV(C.price)
  );

/*
symbol  tradedate   price   startdate   startprice bottomdate  bottomprice enddate     endprice   maxprice
------- ----------- ------- ----------- ---------- ----------- ----------- ----------- ---------- ----------
STOCK1  2019-02-12  150.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-13  151.00  2019-02-13  151.00     2019-02-18  142.00      2019-02-20  152.00     152.00
STOCK1  2019-02-14  148.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-15  146.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-18  142.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-19  144.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-20  152.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-21  152.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-22  153.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-25  154.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-26  154.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-02-27  154.00  2019-02-27  154.00     2019-03-04  140.00      2019-03-06  143.00     154.00
STOCK1  2019-02-28  153.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-01  145.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-04  140.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-05  142.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-06  143.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-07  142.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-08  140.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK1  2019-03-11  138.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-12  330.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-13  329.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-14  329.00  2019-02-14  329.00     2019-02-18  325.00      2019-02-20  328.00     329.00
STOCK2  2019-02-15  326.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-18  325.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-19  326.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-20  328.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-21  326.00  2019-02-21  326.00     2019-02-25  317.00      2019-02-27  325.00     326.00
STOCK2  2019-02-22  320.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-25  317.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-26  319.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-27  325.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-02-28  322.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-01  324.00  2019-03-01  324.00     2019-03-05  319.00      2019-03-07  326.00     326.00
STOCK2  2019-03-04  321.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-05  319.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-06  322.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-07  326.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-08  326.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL
STOCK2  2019-03-11  324.00  NULL        NULL       NULL        NULL        NULL        NULL       NULL

(40 rows affected)
*/

---------------------------------------------------------------------
-- Solutions using Row Pattern Recognition
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Top N Per Group
---------------------------------------------------------------------

-- first 3
-- ^, e.g., ^A{1, 3} — start of a row pattern partition
-- Listing 4-15: Query Returning First 3 Rows Per Symbol 
SELECT MR.symbol, MR.rn, MR.tradedate, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES COUNT(*) AS rn
    ALL ROWS PER MATCH
    PATTERN (^A{1, 3})
    DEFINE A AS 1 = 1
  ) AS MR;

/*
symbol  rn  tradedate   price
------- --- ----------- -------
STOCK1  1   2019-02-12  150.00
STOCK1  2   2019-02-13  151.00
STOCK1  3   2019-02-14  148.00
STOCK2  1   2019-02-12  330.00
STOCK2  2   2019-02-13  329.00
STOCK2  3   2019-02-14  329.00
*/

-- last three  
-- $, e.g., A{1, 3}$ — end of a row pattern partition
-- Listing 4-16: Query Returning Last 3 Rows Per Symbol 
SELECT MR.symbol, MR.rn, MR.tradedate, MR.price
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES COUNT(*) AS rn
    ALL ROWS PER MATCH
    PATTERN (A{1, 3}$)
    DEFINE A AS 1 = 1
  ) AS MR;  

/*
symbol  rn  tradedate   price
------- --- ----------- -------
STOCK1  1   2019-03-07  142.00
STOCK1  2   2019-03-08  140.00
STOCK1  3   2019-03-11  138.00
STOCK2  1   2019-03-07  326.00
STOCK2  2   2019-03-08  326.00
STOCK2  3   2019-03-11  324.00
*/

---------------------------------------------------------------------
-- Packing Intervals
---------------------------------------------------------------------

-- Listing 4-17: Code to Create and Populate dbo.Sessions in SQL Server
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.Sessions;

CREATE TABLE dbo.Sessions
(
  id        INT          NOT NULL,
  username  VARCHAR(14)  NOT NULL,
  starttime DATETIME2(3) NOT NULL,
  endtime   DATETIME2(3) NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(id),
  CONSTRAINT CHK_endtime_gteq_starttime
    CHECK (endtime >= starttime) 
);

INSERT INTO Sessions(id, username, starttime, endtime) VALUES
  (1,  'User1', '20191201 08:00:00', '20191201 08:30:00'),
  (2,  'User1', '20191201 08:30:00', '20191201 09:00:00'),
  (3,  'User1', '20191201 09:00:00', '20191201 09:30:00'),
  (4,  'User1', '20191201 10:00:00', '20191201 11:00:00'),
  (5,  'User1', '20191201 10:30:00', '20191201 12:00:00'),
  (6,  'User1', '20191201 11:30:00', '20191201 12:30:00'),
  (7,  'User2', '20191201 08:00:00', '20191201 10:30:00'),
  (8,  'User2', '20191201 08:30:00', '20191201 10:00:00'),
  (9,  'User2', '20191201 09:00:00', '20191201 09:30:00'),
  (10, 'User2', '20191201 11:00:00', '20191201 11:30:00'),
  (11, 'User2', '20191201 11:32:00', '20191201 12:00:00'),
  (12, 'User2', '20191201 12:04:00', '20191201 12:30:00'),
  (13, 'User3', '20191201 08:00:00', '20191201 09:00:00'),
  (14, 'User3', '20191201 08:00:00', '20191201 08:30:00'),
  (15, 'User3', '20191201 08:30:00', '20191201 09:00:00'),
  (16, 'User3', '20191201 09:30:00', '20191201 09:30:00');

-- Listing 4-18: Code to Create and Populate Sessions in Oracle
DROP TABLE Sessions;

CREATE TABLE Sessions
(
  id        INT           NOT NULL,
  username  VARCHAR2(14)  NOT NULL,
  starttime TIMESTAMP NOT NULL,
  endtime   TIMESTAMP NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(id),
  CONSTRAINT CHK_endtime_gteq_starttime
    CHECK (endtime >= starttime) 
);

INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(1,  'User1', '01-DEC-2019 08:00:00', '01-DEC-2019 08:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(2,  'User1', '01-DEC-2019 08:30:00', '01-DEC-2019 09:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(3,  'User1', '01-DEC-2019 09:00:00', '01-DEC-2019 09:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(4,  'User1', '01-DEC-2019 10:00:00', '01-DEC-2019 11:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(5,  'User1', '01-DEC-2019 10:30:00', '01-DEC-2019 12:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(6,  'User1', '01-DEC-2019 11:30:00', '01-DEC-2019 12:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(7,  'User2', '01-DEC-2019 08:00:00', '01-DEC-2019 10:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(8,  'User2', '01-DEC-2019 08:30:00', '01-DEC-2019 10:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(9,  'User2', '01-DEC-2019 09:00:00', '01-DEC-2019 09:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(10, 'User2', '01-DEC-2019 11:00:00', '01-DEC-2019 11:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(11, 'User2', '01-DEC-2019 11:32:00', '01-DEC-2019 12:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(12, 'User2', '01-DEC-2019 12:04:00', '01-DEC-2019 12:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(13, 'User3', '01-DEC-2019 08:00:00', '01-DEC-2019 09:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(14, 'User3', '01-DEC-2019 08:00:00', '01-DEC-2019 08:30:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(15, 'User3', '01-DEC-2019 08:30:00', '01-DEC-2019 09:00:00');
INSERT INTO Sessions(id, username, starttime, endtime)
  VALUES(16, 'User3', '01-DEC-2019 09:30:00', '01-DEC-2019 09:30:00');
COMMIT;

-- solution query
SELECT MR.username, MR.starttime, MR.endtime
FROM dbo.Sessions
  MATCH_RECOGNIZE
  (
    PARTITION BY username
    ORDER BY starttime, endtime, id
    MEASURES FIRST(starttime) AS starttime, MAX(endtime) AS endtime
    -- A* here means 0 or more matches for A
    -- B represents first item after last match in A
    PATTERN (A* B)
    DEFINE A AS MAX(A.endtime) >= NEXT(A.starttime)
  ) AS MR;

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

-- Listing 4-19: Looking at the Detail Rows in Packing Query
SELECT
  MR.id, MR.username, MR.starttime, MR.endtime, MR.matchno, MR.classy,
  MR.packedstarttime, MR.packedendtime
FROM dbo.Sessions
  MATCH_RECOGNIZE
  (
    PARTITION BY username
    ORDER BY starttime, endtime, id
    MEASURES 
      MATCH_NUMBER() AS matchno,
      CLASSIFIER() AS classy,
      FIRST(starttime) AS pstart,
      MAX(endtime) AS pend
    ALL ROWS PER MATCH
    PATTERN (A* B)
    DEFINE A AS MAX(A.endtime) >= NEXT(A.starttime)
  ) AS MR;

/*
id  username  starttime  endtime  matchno  classy  pstart  pend
--- --------- ---------- -------- -------- ------- ------- ------
1   User1     08:00      08:30    1        A       08:00   08:30
2   User1     08:30      09:00    1        A       08:00   09:00
3   User1     09:00      09:30    1        B       08:00   09:30
4   User1     10:00      11:00    2        A       10:00   11:00
5   User1     10:30      12:00    2        A       10:00   12:00
6   User1     11:30      12:30    2        B       10:00   12:30
7   User2     08:00      10:30    1        A       08:00   10:30
8   User2     08:30      10:00    1        A       08:00   10:30
9   User2     09:00      09:30    1        B       08:00   10:30
10  User2     11:00      11:30    2        B       11:00   11:30
11  User2     11:32      12:00    3        B       11:32   12:00
12  User2     12:04      12:30    4        B       12:04   12:30
13  User3     08:00      09:00    1        A       08:00   08:30
14  User3     08:00      08:30    1        A       08:00   09:00
15  User3     08:30      09:00    1        B       08:00   09:00
16  User3     09:30      09:30    2        B       09:30   09:30
*/

---------------------------------------------------------------------
-- Gaps and Islands
---------------------------------------------------------------------

-- gaps
-- note use of SKIP TO NEXT ROW option to capture case where
-- three consecutive dates have two gaps
-- Listing 4-20: Query Identifying Gaps
SELECT MR.symbol, MR.startdate, MR.enddate
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      DATEADD(day, 1, A.tradedate) AS startdate,
      DATEADD(day, -1, B.tradedate) AS enddate
    AFTER MATCH SKIP TO B
    PATTERN (A B)
    DEFINE A AS DATEADD(day, 1, A.tradedate) < NEXT(A.tradedate)
  ) AS MR;

/*
symbol  startdate   enddate  
------- ----------- -----------
STOCK1  2019-02-16  2019-02-17
STOCK1  2019-02-23  2019-02-24
STOCK1  2019-03-02  2019-03-03
STOCK1  2019-03-09  2019-03-10
STOCK2  2019-02-16  2019-02-17
STOCK2  2019-02-23  2019-02-24
STOCK2  2019-03-02  2019-03-03
STOCK2  2019-03-09  2019-03-10
*/

-- in Oracle instead of DATEADD(day, dt, 1) use dt + INTERVAL '1' DAY
-- and instead of DATEADD(day, dt, -1) use dt - INTERVAL '1' DAY
SELECT MR.symbol, MR.startdate, MR.enddate
FROM Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      A.tradedate + INTERVAL '1' DAY AS startdate,
      B.tradedate - INTERVAL '1' DAY AS enddate
    AFTER MATCH SKIP TO B
    PATTERN (A B)
    DEFINE A AS A.tradedate + INTERVAL '1' DAY < NEXT(A.tradedate)
  ) MR;

-- islands with 1 day interval
-- Listing 4-21: Query Identifying Islands
SELECT MR.symbol, MR.startdate, MR.enddate
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      FIRST(tradedate) AS startdate,
      LAST(tradedate) AS enddate
    PATTERN (A B*)
    DEFINE B AS B.tradedate = DATEADD(day, 1, PREV(B.tradedate))
  ) AS MR;

/*
symbol  startdate   enddate  
------- ----------- -----------
STOCK1  2019-02-12  2019-02-15
STOCK1  2019-02-18  2019-02-22
STOCK1  2019-02-25  2019-03-01
STOCK1  2019-03-04  2019-03-08
STOCK1  2019-03-11  2019-03-11
STOCK2  2019-02-12  2019-02-15
STOCK2  2019-02-18  2019-02-22
STOCK2  2019-02-25  2019-03-01
STOCK2  2019-03-04  2019-03-08
STOCK2  2019-03-11  2019-03-11
*/

-- islands with up to 3 day interval
SELECT MR.symbol, MR.startdate, MR.enddate
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES
      FIRST(tradedate) AS startdate,
      LAST(tradedate) AS enddate
    PATTERN (A B*)
    DEFINE B AS B.tradedate <= DATEADD(day, 3, PREV(B.tradedate))
  ) AS MR;

/*
symbol  startdate   enddate  
------- ----------- -----------
STOCK1  2019-02-12  2019-03-11
STOCK2  2019-02-12  2019-03-11
*/

-- Listing 4-22: Query Identifying Islands Where Price >= 150
SELECT MR.symbol, MR.startdate, MR.enddate, MR.numdays
FROM dbo.Ticker
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES 
      FIRST(tradedate) AS startdate,
      LAST(tradedate) AS enddate,
      COUNT(*) AS numdays
    PATTERN (A B*)
    DEFINE
      A AS A.price >= 150,
      B AS B.price >= 150 AND B.tradedate = DATEADD(day, 1, PREV(B.tradedate))
  ) AS MR;

/*
symbol  startdate   enddate     numdays
------- ----------- ----------- --------
STOCK1  2019-02-12  2019-02-13  2
STOCK1  2019-02-20  2019-02-22  3
STOCK1  2019-02-25  2019-02-28  4
STOCK2  2019-02-12  2019-02-15  4
STOCK2  2019-02-18  2019-02-22  5
STOCK2  2019-02-25  2019-03-01  5
STOCK2  2019-03-04  2019-03-08  5
STOCK2  2019-03-11  2019-03-11  1
*/

-- Listing 4-23: Query Identifying Islands of Consecutive Trading Days Where Price >= 150
WITH C AS
(
  SELECT T.*, ROW_NUMBER() OVER(PARTITION BY symbol ORDER BY tradedate) AS tradedateseq
  FROM dbo.Ticker AS T
)
SELECT MR.symbol, MR.startdate, MR.enddate, MR.numdays
FROM C
  MATCH_RECOGNIZE
  (
    PARTITION BY symbol
    ORDER BY tradedate
    MEASURES 
      FIRST(tradedate) AS startdate,
      LAST(tradedate) AS enddate,
      COUNT(*) AS numdays
    PATTERN (A B*)
    DEFINE
      A AS A.price >= 150,
      B AS B.price >= 150 AND B.tradedateseq = PREV(B.tradedateseq) + 1
  ) AS MR;

/*
symbol  startdate   enddate     numdays
------- ----------- ----------- --------
STOCK1  2019-02-12  2019-02-13  2
STOCK1  2019-02-20  2019-02-28  7
STOCK2  2019-02-12  2019-03-11  20
*/

----------------------------------------------------------------------
-- Specialized Running Sums
----------------------------------------------------------------------

-- nonnegative sum

-- Listing 4-24: Code to Create and Populate dbo.T1 in SQL Server
SET NOCOUNT ON;
USE TSQLV5;

DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
  ordcol  INT NOT NULL,
  datacol INT NOT NULL,
  CONSTRAINT PK_T1
    PRIMARY KEY(ordcol)
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

-- Listing 4-25: Code to Create and Populate T1 in Oracle
DROP TABLE T1;

CREATE TABLE T1
(
  ordcol  INT NOT NULL,
  datacol INT NOT NULL,
  CONSTRAINT PK_T1
    PRIMARY KEY(ordcol)
);

INSERT INTO T1 VALUES(1,   10);
INSERT INTO T1 VALUES(4,  -15);
INSERT INTO T1 VALUES(5,    5);
INSERT INTO T1 VALUES(6,  -10);
INSERT INTO T1 VALUES(8,  -15);
INSERT INTO T1 VALUES(10,  20);
INSERT INTO T1 VALUES(17,  10);
INSERT INTO T1 VALUES(18, -10);
INSERT INTO T1 VALUES(20, -30);
INSERT INTO T1 VALUES(31,  20); 
COMMIT;

-- Listing 4-26: Query Computing Nonnegative Running Sum
SELECT
  MR.ordcol, MR.matchno, MR.datacol,
  CASE WHEN MR.runsum < 0 THEN 0 ELSE MR.runsum END AS runsum,
  CASE WHEN MR.runsum < 0 THEN - MR.runsum ELSE 0 END AS replenish
FROM dbo.T1
  MATCH_RECOGNIZE
  (
    ORDER BY ordcol
    MEASURES 
      MATCH_NUMBER() AS matchno,
      SUM(datacol) AS runsum
    ALL ROWS PER MATCH
    PATTERN (A* B)
    DEFINE A AS SUM(datacol) >= 0
  ) AS MR;

/*
ordcol  matchno  datacol  runsum  replenish
------- -------- -------- ------- ----------
1       1        10       10      0
4       1        -15      0       5
5       2        5        5       0
6       2        -10      0       5
8       3        -15      0       15
10      4        20       20      0
17      4        10       30      0
18      4        -10      20      0
20      4        -30      0       10
31      5        20       20      0
*/

-- in Oracle can use GREATEST | LEAST
SELECT
  MR.ordcol, MR.matchno, MR.datacol,
  GREATEST(MR.runsum, 0) AS runsum,
  -LEAST(MR.runsum, 0) AS replenish
FROM T1
  MATCH_RECOGNIZE
  (
    ORDER BY ordcol
    MEASURES 
      MATCH_NUMBER() AS matchno,
      SUM(datacol) AS runsum
    ALL ROWS PER MATCH
    PATTERN (A* B)
    DEFINE A AS SUM(datacol) >= 0
  ) MR;

-- Listing 4-27: Code to Create and populate dbo.T2 in SQL Server
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

-- Listing 4-28: Code to Create and populate T2 in Oracle
DROP TABLE T2;

CREATE TABLE T2
(
  ordcol  INT NOT NULL,
  datacol INT NOT NULL,
  CONSTRAINT PK_T2
    PRIMARY KEY(ordcol)
);

INSERT INTO T2 VALUES(1,   10);
INSERT INTO T2 VALUES(4,   15);
INSERT INTO T2 VALUES(5,    5);
INSERT INTO T2 VALUES(6,   10);
INSERT INTO T2 VALUES(8,   15);
INSERT INTO T2 VALUES(10,  20);
INSERT INTO T2 VALUES(17,  10);
INSERT INTO T2 VALUES(18,  10);
INSERT INTO T2 VALUES(20,  30);
INSERT INTO T2 VALUES(31,  20); 
COMMIT;

-- Listing 4-29: Query Computing Capped Running Sum, Stopping when it Reaches or Exceeds 50
SELECT MR.ordcol, MR.matchno, MR.datacol, MR.runsum
FROM dbo.T2
  MATCH_RECOGNIZE
  (
    ORDER BY ordcol
    MEASURES 
      MATCH_NUMBER() AS matchno,
      SUM(datacol) AS runsum
    ALL ROWS PER MATCH
    PATTERN (A+)
    DEFINE A AS SUM(datacol) <= 50
  ) AS MR;

/*
ordcol  matchno  datacol  runsum
------- -------- -------- -------
1       1        10       10
4       1        15       25
5       1        5        30
6       1        10       40
8       2        15       15
10      2        20       35
17      2        10       45
18      3        10       10
20      3        30       40
31      4        20       20
*/

-- running sum, stop when capacity reaches or exceeds 50 for the first time
SELECT MR.ordcol, MR.matchno, MR.datacol, MR.runsum
FROM dbo.T2
  MATCH_RECOGNIZE
  (
    ORDER BY ordcol
    MEASURES 
      MATCH_NUMBER() AS matchno,
      SUM(datacol) AS runsum
    ALL ROWS PER MATCH
    PATTERN (A* B)
    DEFINE A AS SUM(datacol) < 50
  ) AS MR;

/*
ordcol  matchno  datacol  runsum
------- -------- -------- -------
1       1        10       10
4       1        15       25
5       1        5        30
6       1        10       40
8       1        15       55
10      2        20       20
17      2        10       30
18      2        10       40
20      2        30       70
31      3        20       20
*/