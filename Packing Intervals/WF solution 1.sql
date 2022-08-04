WITH 
C1 as (
	select 
		id, 
		username, 
		starttime as ts, 
		+1 as type
	from dbo.Sessions

	UNION ALL

	select 
		id, 
		username, 
		endtime as ts, 
		-1 as type
	from dbo.Sessions
),
C2 as (
	select 
		username, 
		ts, 
		type,
		SUM(type) OVER(
			PARTITION BY username
			ORDER BY ts, type DESC, id
			ROWS UNBOUNDED PRECEDING) as cnt
	from C1
),
C3 as (
	select 
		username, 
		ts, 
		(ROW_NUMBER() OVER(PARTITION BY username ORDER BY ts) - 1) / 2 + 1 as grp -- Группировка по парам
	from C2
	where 
		(type = 1 AND cnt = 1) -- Начала пересекающихся интервалов
		OR (type = -1 AND cnt = 0) -- Окончания пересекающихся интервалов
)
select 
	username, 
	min(ts) as starttime, 
	max(ts) as endtime
from C3
group by 
	username, 
	grp;