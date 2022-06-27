CREATE UNIQUE INDEX idx_od_oid_i_cid_eid
ON Sales.Orders(orderdate, orderid)
INCLUDE(custid, empid);