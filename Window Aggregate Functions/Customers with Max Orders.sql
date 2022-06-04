with T (customer_number, number_of_orders, max_orders) as (
    select
        customer_number,
        count(*) as number_of_orders,
        max(count(*)) over () as max_orders
    from Orders
    group by customer_number
)
select customer_number
from T
where number_of_orders = max_orders;