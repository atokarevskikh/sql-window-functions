with C1 as
(
	select 
		app, 
		starttime as ts, 
		+1 as [type], 
		keycol,
		ROW_NUMBER() over(partition by app order by starttime, keycol) as start_ordinal
	from dbo.[Sessions]
	union ALL
	select 
		app, 
		endtime as ts, 
		-1 as [type], 
		keycol, 
		NULL as start_ordinal
	from dbo.[Sessions]
),
C2 as (
	select 
		app, 
		ts,
		[type],
		keycol,
		start_ordinal,
		ROW_NUMBER() over (partition by app order by ts, [type], keycol) as start_or_end_ordinal
	from C1
)
select 
	app,
	MAX(start_ordinal - (start_or_end_ordinal - start_ordinal)) as mx
from C2
group by app;