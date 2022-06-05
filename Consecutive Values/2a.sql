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
	select grp
	from T
	group by grp
	having count(*) > 2
)
select
	id,
	visit_date,
	people
from T
where grp in (select G.grp from G)
order by visit_date;