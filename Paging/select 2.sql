DECLARE
	@pagenum AS INT = 3,
	@pagesize AS INT = 25;
SELECT 
	orderid, 
	orderdate, 
	custid, 
	empid
FROM Sales.Orders
ORDER BY 
	orderdate, 
	orderid
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;