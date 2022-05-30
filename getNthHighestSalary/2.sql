CREATE FUNCTION getNthHighestSalary(@N INT) RETURNS INT AS
BEGIN
    return (
		select distinct(salary)
        from T3
        order by salary desc
			offset @N - 1 rows
			fetch next 1 rows only
	);
END