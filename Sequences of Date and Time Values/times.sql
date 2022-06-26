-- 3-х часовой интервал
declare 
	@start datetime2 = '20220601 00:00:00.0000000',
	@end datetime2 = '20220610 00:00:00.0000000',
	@interval int = 3;
select DATEADD(hh, n * @interval, @start)
from dbo.GetNums(0, DATEDIFF(hh, @start, @end) / @interval);