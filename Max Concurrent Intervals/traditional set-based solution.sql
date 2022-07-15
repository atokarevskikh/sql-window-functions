with TimePoints as (
	select
		app,
		starttime as ts
	from dbo.[Sessions]
),
Counts as (
	select 
		app,
		ts,
		(
			select count(*)
			from dbo.[Sessions] as S
			where 
				S.app = P.app and
				P.ts >= S.starttime and
				P.ts < S.endtime
		) as concurrent
	from TimePoints as P
)
select 
	app,
	max(concurrent) as mx
from Counts
group by app;