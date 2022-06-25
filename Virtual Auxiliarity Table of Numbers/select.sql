declare 
	@low int = 1,
	@high int = 100000;

with 
	L0 as (
		select c 
		from (
			values (1), (1)
		) as D(c)
	),
	L1 as (
		select 1 as c
		from
			L0 as A cross join
			L0 as B
	),
	L2 as (
		select 1 as c
		from
			L1 as A cross join
			L1 as B
	),
	L3 as (
		select 1 as c
		from
			L2 as A cross join
			L2 as B
	),
	L4 as (
		select 1 as c
		from
			L3 as A cross join
			L3 as B
	),
	L5 as (
		select 1 as c
		from
			L4 as A cross join
			L4 as B
	),
	Nums as (
		select ROW_NUMBER() over (order by (select null)) as rownum
		from L5
	)
select @low + rownum -1 as n
from Nums
order by rownum
offset 0 rows fetch next @high - @low + 1 rows only;