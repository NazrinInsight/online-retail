CREATE DATABASE OnlineRetail;
GO
USE OnlineRetail;
GO

CREATE TABLE RetailSales (
    Invoice NVARCHAR(50),
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID INT,
    Country NVARCHAR(100)
);

select * from OnlineRetail;

