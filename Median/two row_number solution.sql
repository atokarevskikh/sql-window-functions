with C as (
	select 
		testid, 
		score,
		ROW_NUMBER() over(partition by testid order by score, studentid) as rna,
		ROW_NUMBER() over(partition by testid order by score desc, studentid desc) as rnd
	FROM Stats.Scores
)
select 
	testid, 
	AVG(1. * score) as median
from C
where ABS(rna - rnd) <= 1
group by testid;