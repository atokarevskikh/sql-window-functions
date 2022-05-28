select
	*
from
	Sales.OrderDetails
where
	orderid = 10260
order by
	unitprice desc
offset 1 rows fetch next 1 rows only