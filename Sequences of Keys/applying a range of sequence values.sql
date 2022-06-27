/*
Suppose that you need a sequencing mechanism that guarantees no gaps. You can’t rely on the identity
column property or the sequence object because both mechanisms will have gaps when the operation
that generates the sequence value fails or just doesn’t commit. One of the common alternatives
that guarantees no gaps is to store the last-used value in a table, and whenever you need a new value,
you increment the stored value and use the new one.
*/

DROP TABLE IF EXISTS dbo.MySequence;
CREATE TABLE dbo.MySequence(val INT);
INSERT INTO dbo.MySequence VALUES(0);
go

create or alter proc dbo.GetSequence
	@val int output
as
update dbo.MySequence
set @val = val += 1;
go

declare @key int;
exec dbo.GetSequence @val = @key output;
select @key;
go

CREATE OR ALTER PROC dbo.GetSequence
	@val AS INT OUTPUT,
	@n AS INT = 1
AS
UPDATE dbo.MySequence
SET 
	@val = val + 1,
	val += @n;
GO

DECLARE @firstkey AS INT, @rc AS INT;
DECLARE @CustsStage AS TABLE (
	custid INT,
	rownum INT
);
INSERT INTO @CustsStage (
	custid, 
	rownum
)
SELECT 
	custid, 
	ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
FROM Sales.Customers
WHERE country = N'UK';
SET @rc = @@rowcount;
EXEC dbo.GetSequence @val = @firstkey OUTPUT, @n = @rc;
SELECT 
	custid, 
	@firstkey + rownum - 1 AS keycol
FROM @CustsStage;
go