with C as (
	select 
		testid, 
		(COUNT(*) - 1) / 2 as ov, 
		2 - COUNT(*) % 2 AS fv
	from Stats.Scores
	group by testid
)
select 
	C.testid, 
	AVG(1. * A.score) as median
from 
	C cross apply (
		select S.score
		from Stats.Scores as S
		where S.testid = C.testid
		order by S.score
		offset C.ov rows fetch next C.fv rows only
	) as A
group by C.testid;