select distinct 
	testid,
	percentile_cont(0.5) 
		within group (order by score)
		over (partition by testid) 
		as median
from Stats.Scores;