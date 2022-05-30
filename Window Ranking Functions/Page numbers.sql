-- Query Computing Page Numbers
SELECT orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  (ROW_NUMBER() OVER(ORDER BY val) - 1) / 10 + 1 AS pagenum
FROM Sales.OrderValues;