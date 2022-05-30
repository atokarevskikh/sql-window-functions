-- ROWS BETWEEN <n> PRECEDING AND <n> FOLLOWING
-- Альтернатива LAG и LEAD функции (OFFSET)
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