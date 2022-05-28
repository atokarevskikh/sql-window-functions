;with T (orderid, productid, unitprice, sort)
as (
	select 
		orderid
		,productid
		,unitprice
		,row_number() over(partition by orderid order by unitprice desc) sort
	from
		Sales.OrderDetails
)
select
	orderid
	,productid
	,unitprice
from
	T
where
	sort = 2