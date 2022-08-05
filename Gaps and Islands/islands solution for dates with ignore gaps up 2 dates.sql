with 
C1 as (
	select 
		col1,
		case
			when DATEDIFF(day, LAG(col1) over(order by col1), col1) <= 2
			then 0
			else 1
		end as isstart
	from dbo.T2
),
C2 as (
	select 
		col1,
		isstart,
		SUM(isstart) over(order by col1 rows unbounded preceding) as grp
	from C1
)
select 
	MIN(col1) as rangestart, 
	MAX(col1) as rangeend
from C2
group by grp;