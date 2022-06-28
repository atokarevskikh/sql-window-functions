with C as (
	select
		orderid,
		ROW_NUMBER() over (partition by orderid order by (select null)) as n
	from Sales.MyOrders
)
delete from C
where n > 1;