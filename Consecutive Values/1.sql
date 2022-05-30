/*
Write an SQL query to find all numbers that appear at least three times consecutively.
Return the result table in any order.
*/
with T (num, previous, [next]) as (
	select
		num
		,LAG(num) over(order by id) as previous
		,LEAD(num) over(order by id) as [next]
	from Logs
)
select distinct num as ConsecutiveNums
from T
where 
	num = previous
	and num = [next];