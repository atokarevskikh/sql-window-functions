with 
C as (
	select
		col1,
		col1 - DENSE_RANK() over (order by col1) as grp
	from T1
)
select
	min(col1) as start_range,
	max(col1) as end_range
from C
group by grp;