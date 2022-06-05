with T as (
	select
		id,
		visit_date,
		people,
		id - RANK() over(order by id) as grp
	from Stadium
	where people >= 100
),
G as (
	select 
		id,
		visit_date,
		people,
		COUNT(*) over (partition by grp) as cnt
	from T
)
select
	id,
	visit_date,
	people
from G
where cnt > 2
order by visit_date;