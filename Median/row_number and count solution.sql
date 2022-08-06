with C as (
	select 
		testid, 
		score,
		ROW_NUMBER() over(partition by testid order by score) as pos,
		COUNT(*) over(partition by testid) AS cnt
	from Stats.Scores
)
select 
	testid,
	AVG(1. * score) as median
from C
where pos in ((cnt + 1) / 2, (cnt + 2) / 2 )
group by testid;
