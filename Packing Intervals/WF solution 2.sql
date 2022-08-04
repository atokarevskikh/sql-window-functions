WITH C1 as (
	select 
		*,
		CASE
			WHEN starttime <= MAX(endtime) OVER(
				PARTITION BY username
				ORDER BY starttime, endtime, id
				ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
			THEN 0
			ELSE 1 -- Начала пересекающихся интервалов
		END as isstart
	from dbo.Sessions
),
C2 as (
	select 
		*,
		SUM(isstart) OVER(
			PARTITION BY username
            ORDER BY starttime, endtime, id
            ROWS UNBOUNDED PRECEDING) as grp
	from C1
)
select 
	username, 
	min(starttime) as starttime, 
	max(endtime) as endtime
from C2
group by 
	username, 
	grp;