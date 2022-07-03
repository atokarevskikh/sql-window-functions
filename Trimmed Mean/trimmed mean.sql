/*
Среднее значение за исключением нижних и верхних 5 %
*/
with C as (
	select 
		empid,
		val,
		NTILE(20) over (partition by empid order by val) as ntile20
	from Sales.OrderValues
)
select
	empid,
	avg(val) as AvgVal
from C
where ntile20 between 2 and 19
group by empid;