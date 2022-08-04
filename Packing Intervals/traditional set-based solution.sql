with 
-- Начала пересекающихся интервалов
StartTimes as (
	select distinct 
		username, 
		starttime
	from 
		dbo.Sessions as S1
	where not exists (
		select * 
		from dbo.Sessions as S2
		where 
			S2.username = S1.username and 
			S2.starttime < S1.starttime and 
			S2.endtime >= S1.starttime
	)
),
-- Окончания пересекающихся интервалов
EndTimes as
(
	select distinct 
		username, 
		endtime
	from 
		dbo.Sessions as S1
	where not exists (
		select * 
		from dbo.Sessions as S2
		where 
			S2.username = S1.username and 
			S2.endtime > S1.endtime and 
			S2.starttime <= S1.endtime
	)
)
select 
	username, 
	starttime,
	(
		select MIN(endtime) 
		from EndTimes as E
		where 
			E.username = S.username and 
			endtime >= starttime
	) as endtime
from 
	StartTimes as S;