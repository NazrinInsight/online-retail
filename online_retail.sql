CREATE DATABASE OnlineRetail;
GO
USE OnlineRetail;
GO


select * from onlineretail;

--KPI
SELECT 
    COUNT(DISTINCT Invoice) AS TotalOrders,       -- neçə sifariş
    COUNT(DISTINCT Customer_ID) AS TotalCustomers,-- neçə müştəri
    SUM(Quantity) AS TotalUnits,                  -- neçə məhsul satılıb
    SUM(Quantity * Price) AS TotalRevenue         -- ümumi gəlir
FROM onlineretail;


--Retail share by country
SELECT 
    Country,
    SUM(Quantity * Price) AS TotalRevenue,
    CAST(SUM(Quantity * Price) * 100.0 / 
         SUM(SUM(Quantity * Price)) OVER() AS DECIMAL(5,2)) AS MarketSharePct
FROM onlineretail
GROUP BY Country
ORDER BY TotalRevenue DESC;

--TOP 10 customers and their share (often 20% of customers generate 80% of revenue → Pareto analysis).
SELECT TOP 10
    Customer_ID,
    SUM(Quantity * Price) AS CustomerRevenue,
    CAST(SUM(Quantity * Price) * 100.0 /
         SUM(SUM(Quantity * Price)) OVER() AS DECIMAL(5,2)) AS ShareOfRevenue
FROM onlineretail
GROUP BY Customer_ID
ORDER BY CustomerRevenue DESC;

--Product Analysis – “cash cow” and “dead stock”

--Top revenue generating products:

SELECT TOP 10
    Description,
    SUM(Quantity) AS UnitsSold,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY Description
ORDER BY Revenue DESC;

--The least profitable products:

SELECT TOP 10
    Description,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY Description
ORDER BY Revenue ASC;

--Trend over time → seasonal analysis of sales

--By year:

SELECT 
    YEAR(InvoiceDate) AS SalesYear,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY YEAR(InvoiceDate)
ORDER BY SalesYear;

--By months:

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS SalesMonth,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY SalesMonth;

--Repeat Customer Analysis 

SELECT 
    Customer_ID,
    COUNT(DISTINCT Invoice) AS OrdersCount,
    SUM(Quantity * Price) AS TotalSpent
FROM onlineretail
GROUP BY Customer_ID
HAVING COUNT(DISTINCT Invoice) > 1
ORDER BY OrdersCount DESC;


--Customer Segmentation (RFM Analysis)


WITH MaxDate AS (
    SELECT MAX(InvoiceDate) AS LastDate FROM onlineRetail
),
CustomerStats AS (
    SELECT 
        Customer_ID,
        MAX(InvoiceDate) AS LastPurchase,
        COUNT(DISTINCT Invoice) AS Frequency,
        SUM(Quantity * Price) AS Monetary
    FROM onlineRetail
    GROUP BY Customer_ID
),
RFM AS (
    SELECT
        c.Customer_ID,
        DATEDIFF(DAY, c.LastPurchase, m.LastDate) AS Recency,
        c.Frequency,
        c.Monetary
    FROM CustomerStats c
    CROSS JOIN MaxDate m
)
SELECT
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    CASE 
        WHEN Recency <= 30 AND Frequency >= 5 AND Monetary >= 1000 THEN 'Gold'
        WHEN Recency <= 90 AND Frequency >= 3 AND Monetary >= 500 THEN 'Silver'
        WHEN Recency <= 180 AND Frequency >= 2 AND Monetary >= 200 THEN 'Bronze'
        ELSE 'Churned'
    END AS Segment
FROM RFM
ORDER BY Segment, Monetary DESC;


--ABC Analysis
WITH ProductSales AS (
    SELECT
        StockCode,
        Description,
        SUM(Quantity * Price) AS TotalSales
    FROM onlineRetail
    GROUP BY StockCode, Description
),
OrderedSales AS (
    SELECT
        StockCode,
        Description,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS RankBySales,
        SUM(TotalSales) OVER () AS GrandTotal,
        SUM(TotalSales) OVER (ORDER BY TotalSales DESC) AS RunningTotal
    FROM ProductSales
),
ABC AS (
    SELECT
        StockCode,
        Description,
        TotalSales,
        RunningTotal,
        GrandTotal,
        CAST(RunningTotal * 100.0 / GrandTotal AS DECIMAL(5,2)) AS CumPercent,
        CASE
            WHEN RunningTotal * 100.0 / GrandTotal <= 80 THEN 'A'
            WHEN RunningTotal * 100.0 / GrandTotal <= 95 THEN 'B'
            ELSE 'C'
        END AS Category
    FROM OrderedSales
)
SELECT *
FROM ABC
ORDER BY Category, TotalSales DESC;