;with T (Id, RecordDate, Temperature, PreviousDayTemperature) as (
	select
		Id
		,RecordDate
		,Temperature
		,LAG(Temperature) over(order by RecordDate) as PreviousDayTemperature
	from
		T2
)
select
	Id
	,RecordDate
	,Temperature
	,PreviousDayTemperature
from
	T
where
	Temperature > PreviousDayTemperature

