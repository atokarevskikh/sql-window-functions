CREATE FUNCTION getNthHighestSalary(@N INT) RETURNS INT AS
BEGIN
    declare @Result int;
	with T (salary, dense_rnk) as (
		select
			salary
			,DENSE_RANK() OVER(order by salary desc) as dense_rnk
		from
			T3
	)
	select top 1 @Result = salary
	from T
	where dense_rnk = @N;
	
	RETURN @Result;
END