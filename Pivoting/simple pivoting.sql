with C as
(
  select 
	YEAR(orderdate) as orderyear, 
	MONTH(orderdate) as ordermonth, 
	val
  from Sales.OrderValues
)
select *
from C
pivot (
	SUM(val)
    for ordermonth 
	in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) as P
order by orderyear;