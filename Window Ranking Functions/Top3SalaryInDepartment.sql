with T (Department, Employee, Salary, salaryDenseRank) as (
    select
        D.[name] as Department,
        E.[name] as Employee,
        E.salary as Salary,
        dense_rank() over (partition by E.departmentId order by E.salary desc) as salaryDenseRank
    from 
        Employee E join
        Department D on E.departmentId = D.id
)
select
    Department,
    Employee,
    Salary
from T
where T.salaryDenseRank < 4;