/*
Mode is a statistical calculation that returns 
the most frequently occurring value in the population.
Suppose you want to know, for each customer, which
employee handled the most orders.
*/
create index idx_custid_empid ON Sales.Orders(custid, empid);

drop index if exists idx_custid_empid ON Sales.Orders;