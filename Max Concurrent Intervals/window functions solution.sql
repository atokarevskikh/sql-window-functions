with C1 as (
	select 
		keycol, 
		app, 
		starttime AS ts, 
		+1 AS [type]
	from dbo.[Sessions]
	union ALL
	select 
		keycol, 
		app, 
		endtime AS ts, 
		-1 AS [type]
	from dbo.[Sessions]
),
C2 as (
	select 
		keycol,
		app,
		ts,
		[type],
		sum(type) over (
			partition by app 
			order by ts, [type], keycol
			rows unbounded preceding
		) as cnt
	from C1
)
select 
	app,
	max(cnt) as mx
from C2
group by app
OPTION(MAXDOP 1);