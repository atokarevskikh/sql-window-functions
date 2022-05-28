;with T (orderid, productid, unitprice, qty, allsum, sort) as (
	select 
		orderid
		,productid
		,unitprice
		,qty
		,unitprice * qty as allsum
		,row_number() over(partition by orderid order by unitprice * qty desc) sort
	from
		Sales.OrderDetails
),
S (orderid, productid, unitprice, qty, allsum, sort) as (
	select
		orderid
		,productid
		,unitprice
		,qty
		,allsum
		,sort
	from
		T
	where
		sort = 2
)
select
	T.orderid
	,S.productid
	,S.unitprice
	,S.qty
	,S.allsum
from
	T
	left join S on T.orderid = S.orderid
where
	T.sort = 1
order by 
	T.orderid

