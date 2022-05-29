;with T (orderid, productid, unitprice, sort)
as (
	select 
		orderid
		,productid
		,unitprice
		,DENSE_RANK() over(partition by orderid order by unitprice desc) sort
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