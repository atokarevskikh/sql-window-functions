select * from Sales.MyOrders;

with C as (
	SELECT orderid, ROW_NUMBER() OVER(ORDER BY orderdate, custid) AS rownum
	FROM Sales.MyOrders
)
UPDATE C
SET orderid = rownum;