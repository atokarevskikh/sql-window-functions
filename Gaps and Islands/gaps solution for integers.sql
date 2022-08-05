with 
C as (
	select 
		col1 as cur, 
		LEAD(col1) over(order by col1) as nxt
	from dbo.T1
)
select 
	cur + 1 as rangestart, 
	nxt - 1 as rangeend
from C
WHERE nxt - cur > 1;