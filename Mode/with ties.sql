with C as (
	select 
		custid, 
		empid, 
		COUNT(*) as cnt,
		ROW_NUMBER() over (partition by custid order by count(*) desc, empid desc) as rn
	from 
		Sales.Orders
	group by 
		custid, 
		empid
)
select
	custid,
	empid,
	cnt
from C
where rn = 1;