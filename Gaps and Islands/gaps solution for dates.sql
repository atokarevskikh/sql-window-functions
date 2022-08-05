with
C as (
	select 
		col1 as cur,
		LEAD(col1) over (order by col1) as nxt
	from T2
)
select
	DATEADD(d, 1, cur) as rangestart,
	DATEADD(d, -1, nxt) as rangeend
from C
where DATEDIFF(d, cur, nxt) > 1;