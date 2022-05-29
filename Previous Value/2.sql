select
	a.Id
	,a.RecordDate
	,a.Temperature
	,b.Temperature as PreviousDayTemperature
from
	T2 a, T2 b
where
	a.Temperature > b.Temperature
	and DATEDIFF(d, b.RecordDate, a.RecordDate) = 1