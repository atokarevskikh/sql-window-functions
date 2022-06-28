with C as (
	select 
		custid, 
		val,
		ROW_NUMBER() over(partition by custid order by orderdate desc, orderid desc) AS rownum
	from Sales.OrderValues
)
select *
from C
pivot(
	MAX(val) 
	for rownum 
	in ([1],[2],[3],[4],[5])
) as P;