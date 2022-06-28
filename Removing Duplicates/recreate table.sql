with C as (
	select
		orderid, 
		custid, 
		empid, 
		orderdate, 
		requireddate, 
		shippeddate,
		shipperid, 
		freight, 
		shipname, 
		shipaddress, 
		shipcity, 
		shipregion,
		shippostalcode, 
		shipcountry,
		ROW_NUMBER() over (partition by orderid order by (select null)) as n
	from Sales.MyOrders
)
select 
	orderid, 
	custid, 
	empid, 
	orderdate, 
	requireddate, 
	shippeddate,
	shipperid, 
	freight, 
	shipname, 
	shipaddress, 
	shipcity, 
	shipregion,
	shippostalcode, 
	shipcountry
into Sales.MyOrdersTmp
from C
where n = 1;

-- Here re-create indexes, constraints

truncate table Sales.MyOrders;
alter table Sales.MyOrdersTmp switch to Sales.MyOrders;
drop table Sales.MyOrdersTmp;