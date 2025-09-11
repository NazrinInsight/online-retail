

# 🛒 Online Retail Data Analysis (MS SQL Server)

This project is based on the **Online Retail dataset** and demonstrates how to perform **business analytics using SQL Server**.
The goal is to extract actionable insights about **sales, customers, and products** directly from transactional data.

---

## 📂 Project Structure

1. **Key Performance Indicators (KPIs)**
2. **Market Share by Country**
3. **Pareto Analysis (Top Customers)**
4. **Product Analysis (Cash Cow & Dead Stock)**
5. **Time-Series Trend Analysis**
6. **Repeat Customer Analysis**
7. **RFM Analysis (Customer Segmentation)**
8. **ABC Analysis (Product Segmentation)**

---

## 🔹 1. Key Performance Indicators (KPIs)

```sql
SELECT 
    COUNT(DISTINCT Invoice) AS TotalOrders,       -- number of orders
    COUNT(DISTINCT Customer_ID) AS TotalCustomers,-- number of customers
    SUM(Quantity) AS TotalUnits,                  -- number of items sold
    SUM(Quantity * Price) AS TotalRevenue         -- total revenue
FROM onlineretail;
```

📊 **Explanation:** This query extracts the most important KPIs: total orders, total customers, units sold, and revenue.

---

## 🔹 2. Market Share by Country

```sql
SELECT 
    Country,
    SUM(Quantity * Price) AS TotalRevenue,
    CAST(SUM(Quantity * Price) * 100.0 / 
         SUM(SUM(Quantity * Price)) OVER() AS DECIMAL(5,2)) AS MarketSharePct
FROM onlineretail
GROUP BY Country
ORDER BY TotalRevenue DESC;
```

📊 **Explanation:** Shows which countries contribute the most revenue and their market share in percentage terms.

---

## 🔹 3. Top 10 Customers

```sql
SELECT TOP 10
    Customer_ID,
    SUM(Quantity * Price) AS CustomerRevenue,
    CAST(SUM(Quantity * Price) * 100.0 /
         SUM(SUM(Quantity * Price)) OVER() AS DECIMAL(5,2)) AS ShareOfRevenue
FROM onlineretail
GROUP BY Customer_ID
ORDER BY CustomerRevenue DESC;
```

📊 **Explanation:** According to the **Pareto principle (80/20 rule)**, 20% of customers usually generate 80% of revenue. This query identifies the top 10 customers.

---

## 🔹 4. Product Analysis – Cash Cow vs Dead Stock

**Top 10 Revenue-Generating Products**

```sql
SELECT TOP 10
    Description,
    SUM(Quantity) AS UnitsSold,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY Description
ORDER BY Revenue DESC;
```

**Bottom 10 Revenue-Generating Products**

```sql
SELECT TOP 10
    Description,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY Description
ORDER BY Revenue ASC;
```

📊 **Explanation:** Identifies **Cash Cow products** (high revenue generators) and **Dead Stock** (low revenue generators).

---

## 🔹 5. Time-Series Trend Analysis

**Yearly Sales**

```sql
SELECT 
    YEAR(InvoiceDate) AS SalesYear,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY YEAR(InvoiceDate)
ORDER BY SalesYear;
```

**Monthly Sales**

```sql
SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS SalesMonth,
    SUM(Quantity * Price) AS Revenue
FROM onlineretail
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY SalesMonth;
```

📊 **Explanation:** Displays sales trends over time, useful for identifying **seasonality and yearly growth/decline patterns**.

---

## 🔹 6. Repeat Customer Analysis

```sql
SELECT 
    Customer_ID,
    COUNT(DISTINCT Invoice) AS OrdersCount,
    SUM(Quantity * Price) AS TotalSpent
FROM onlineretail
GROUP BY Customer_ID
HAVING COUNT(DISTINCT Invoice) > 1
ORDER BY OrdersCount DESC;
```

📊 **Explanation:** Identifies loyal customers who made repeat purchases.

---

## 🔹 7. RFM Analysis (Customer Segmentation)

### 📖 What is RFM Analysis?

**RFM (Recency, Frequency, Monetary)** is a customer segmentation technique:

* **Recency (R):** How recently a customer purchased.
* **Frequency (F):** How often a customer purchases.
* **Monetary (M):** How much money a customer spends.

It helps businesses classify customers into groups like **Gold, Silver, Bronze, or Churned** for targeted marketing.

```sql
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
```

📊 **Explanation:**

* **Gold:** Recent, frequent, and high-spending customers.
* **Silver:** Valuable but not as engaged as Gold.
* **Bronze:** Medium-value customers.
* **Churned:** Lost customers with low engagement.

---

## 🔹 8. ABC Analysis (Product Segmentation)

### 📖 What is ABC Analysis?

**ABC Analysis** is an inventory categorization method:

* **A:** Top 20% of products that generate \~80% of revenue.
* **B:** Next 30% of products that generate \~15% of revenue.
* **C:** Remaining 50% of products that generate \~5% of revenue.

It helps businesses focus on high-value products.

```sql
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
```

📊 **Explanation:**

* **Category A:** High-value products (focus on availability & stock).
* **Category B:** Medium-value products (optimize inventory).
* **Category C:** Low-value products (minimize stock).

---

## 🚀 Key Insights

From this analysis, we can derive:
✔ Core KPIs (orders, customers, revenue, units sold)
✔ Market share by country
✔ Top customers and Pareto distribution
✔ Best-selling vs. underperforming products
✔ Sales trends by year and month
✔ Customer loyalty patterns
✔ RFM-based customer segmentation
✔ ABC product categorization

