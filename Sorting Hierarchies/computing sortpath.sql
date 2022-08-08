with EmpsRN as (
	select 
		empid,
		mgrid,
		empname,
		salary,
		ROW_NUMBER() over(partition by mgrid order by empname, empid) as n
	from dbo.Employees
),
EmpsPath as (
	select 
		empid, 
		empname, 
		salary, 
		0 as lvl,
		CAST(0x as varbinary(MAX)) as sortpath
	from dbo.Employees
	where mgrid is null

	UNION ALL

	select 
		C.empid, 
		C.empname, 
		C.salary, 
		P.lvl + 1,
		P.sortpath + CAST(n as binary(2)) as sortpath
	from 
		EmpsPath as P join 
		EmpsRN as C on C.mgrid = P.empid
)
select 
	empid, 
	empname, 
	salary, 
	lvl,
	sortpath
from EmpsPath;