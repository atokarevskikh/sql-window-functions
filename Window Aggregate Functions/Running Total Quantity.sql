-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runqty
FROM Sales.EmpOrders;


-- more concise alternative
SELECT empid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS UNBOUNDED PRECEDING) AS runqty
FROM Sales.EmpOrders;