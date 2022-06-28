with C as (
	select
		orderid,
		ROW_NUMBER() over (order by orderid) as rownum,
		RANK() over (order by orderid) as rnk
	from Sales.MyOrders
)
delete from C
where rownum <> rnk;