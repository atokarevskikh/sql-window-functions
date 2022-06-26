declare 
	@start date = '2022 jun 1',
	@end date = '2022 jun 30';
select DATEADD(d, n, @start)
from dbo.GetNums(0, DATEDIFF(d, @start, @end));