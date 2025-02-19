-- I. Data Cleaning

-- 1. Check overview dataset
SELECT TOP 10 *
FROM Global_Superstore

-- 2. Check Null data
SELECT 
	COUNT(*) AS All_Data_Count,
    SUM(CASE WHEN Row_ID IS NULL THEN 1 ELSE 0 END) AS Row_ID_Null_Count,
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS Order_ID_Null_Count,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS Order_Date_Null_Count,
    SUM(CASE WHEN Ship_Date IS NULL THEN 1 ELSE 0 END) AS Ship_Date_Null_Count,
    SUM(CASE WHEN Ship_Mode IS NULL THEN 1 ELSE 0 END) AS Ship_Mode_Null_Count,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Customer_ID_Null_Count,
    SUM(CASE WHEN Customer_Name IS NULL THEN 1 ELSE 0 END) AS Customer_Name_Null_Count,
    SUM(CASE WHEN Segment IS NULL THEN 1 ELSE 0 END) AS Segment_Null_Count,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS City_Null_Count,
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS State_Null_Count,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Country_Null_Count,
    SUM(CASE WHEN Postal_Code IS NULL THEN 1 ELSE 0 END) AS Postal_Code_Null_Count,
    SUM(CASE WHEN Market IS NULL THEN 1 ELSE 0 END) AS Market_Null_Count,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS Region_Null_Count,
    SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS Product_ID_Null_Count,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Category_Null_Count,
    SUM(CASE WHEN Sub_Category IS NULL THEN 1 ELSE 0 END) AS Sub_Category_Null_Count,
    SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END) AS Product_Name_Null_Count,
	SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Sales_Null_Count,
	SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_Null_Count,
	SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Discount_Null_Count,
	SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS Profit_Null_Count,
	SUM(CASE WHEN Shipping_Cost IS NULL THEN 1 ELSE 0 END) AS Shipping_Cost_Null_Count,
	SUM(CASE WHEN Order_Priority IS NULL THEN 1 ELSE 0 END) AS Order_Priority_Null_Count
FROM Global_Superstore;
---> There are 41296 null data in Postal_Code column, we will delete this column without dataset.


-- 3. Check duplicate data
SELECT 
    Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode, 
    Customer_ID, Customer_Name, Segment, City, State, 
    Country, Postal_Code, Market, Region, Product_ID, 
    Category, Sub_Category, Product_Name, Sales, Quantity, Discount, Profit, Shipping_Cost, Order_Priority, COUNT(*) AS Duplicate_Count
FROM 
    Global_Superstore
GROUP BY 
    Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode, 
    Customer_ID, Customer_Name, Segment, City, State, 
    Country, Postal_Code, Market, Region, Product_ID, 
    Category, Sub_Category, Product_Name, Sales, Quantity, Discount, Profit, Shipping_Cost, Order_Priority
HAVING 
    COUNT(*) > 1;
---> No duplicate value with all columns
---> I need to check duplicate value between Order_ID and Order_Date, Product_ID and Product_Name

--- 3.1. Order_ID and Order_Date
WITH OrderNumber 
AS(
SELECT Order_ID, Order_Date, ROW_NUMBER() OVER(PARTITION BY Order_ID ORDER BY Order_Date) as Order_Number
FROM Global_Superstore
GROUP BY Order_ID, Order_Date)

SELECT *
FROM Global_Superstore
WHERE Order_ID in (SELECT O.Order_ID
				   FROM OrderNumber AS O
				   WHERE O.Order_Number = 2)
ORDER BY Order_ID, Order_Date
---> Some Transactions have same Order_ID but has other Order_Date. This is an error in entry-data processing.
---> I will change a little detail of Order_ID to remove this duplicates.

--- 3.2. Product_ID and Product_Name
WITH ProductID 
AS(
SELECT Product_ID, Product_Name, ROW_NUMBER() OVER(PARTITION BY Product_ID ORDER BY Product_Name) as Product_Number
FROM Global_Superstore
GROUP BY Product_ID, Product_Name)

SELECT *
FROM Global_Superstore
WHERE Product_ID in (SELECT P.Product_ID
				   FROM ProductID AS P
				   WHERE P.Product_Number = 2)
ORDER BY Product_ID
---> Some Product_Name have same Product_ID. This is an error in entry-data processing.
---> I will change a little detail of Product_ID to remove this duplicates.

--- 3.3. Customer_ID and Customer_Name
select TOP 10 * from Global_Superstore
SELECT Customer_ID, Customer_Name, MIN(Order_Date) AS First_Buy, COUNT(DISTINCT(Order_ID)) AS Cnt_Orders
FROM Global_Superstore
GROUP BY Customer_Name, Customer_ID 
ORDER BY Customer_Name
---> There are difference in First tim buy and Frequency between Customers have same name, so they have difference Customer_ID.
---> I think Customer_Name has an error in entry-data processing. I will keep Customer_Name and use Customer_ID for typical of each customers.


-- 4. Check logical numeric data
SELECT 
		SUM(CASE WHEN Sales <= 0 THEN 1 ELSE 0 END) AS Sales_Zero_Count,
		SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS Quantity_Zero_Count,
		SUM(CASE WHEN Discount < 0 THEN 1 ELSE 0 END) AS Discount_Zero_Count,
		SUM(CASE WHEN Profit <= 0 THEN 1 ELSE 0 END) AS Profit_Zero_Count,
		SUM(CASE WHEN Shipping_Cost <= 0 THEN 1 ELSE 0 END) AS Shipping_Cost_Zero_Count
FROM Global_Superstore
---> There are 13212 values in Profit and 2 values in Shipping_Cost less than zero value.
---> Đây là một vấn đề kinh doanh bình thường khi các hạng mục với mức chi phí cao hơn so với doanh thu gây từ đó tác động đến lợi nhuận âm
---> Các giá trị trong các cột còn lại không mang giá trị bé hơn hoặc bằng 0 là hoàn toàn phù hợp


-- 5. Check overview datatype
EXEC sp_help 'Global_Superstore';
-- Datatype of all columns are correct

-- 6. Defind data clean to analysis:
---> We will drop some features unnecessary likes: ROW_ID, Postal_Code.
---> Change duplicate Order_ID data.
---> Create VIEW Data_Cleaned to analysis.

CREATE VIEW Data_Cleaned AS
--- Step 1: Defind same Order_ID but there are different Order_Date
WITH CTE
AS (
SELECT 
        Order_ID,
        Order_Date, 
		Customer_Name,
        DENSE_RANK() OVER (PARTITION BY Order_ID ORDER BY Order_Date) AS rank1,
		Product_ID,
		Product_Name,
		DENSE_RANK() OVER (PARTITION BY Product_ID ORDER BY Product_Name) AS rank2
FROM 
        Global_Superstore)
--- Step 2: Select necessaries column
SELECT DISTINCT
	   CONCAT(CTE.Order_ID,'-',CTE.rank1) AS OrderID,
	   GS.Order_Date, 
	   GS.Ship_Date, 
	   GS.Ship_Mode, 
	   GS.Customer_ID, 
	   GS.Customer_Name, 
	   GS.Segment, 
	   GS.City, 
	   GS.State, 
	   GS.Country, 
	   GS.Market, 
	   GS.Region, 
	   CONCAT(CTE.Product_ID,'-',CTE.rank2) AS Product_ID,
	   GS.Product_Name,
	   GS.Category, 
	   GS.Sub_Category,
	   ROUND((GS.Sales / GS.Quantity),2) AS Unit_Price,
	   GS.Quantity,
	   GS.Sales,
	   GS.Discount,
	   GS.Profit,
	   GS.Shipping_Cost,
	   GS.Order_Priority
FROM Global_Superstore GS 
	 JOIN CTE 
	 ON 
	 GS.Order_ID = CTE.Order_ID 
	 AND GS.Order_Date = CTE.Order_Date
	 AND GS.Product_ID = CTE.Product_ID
	 AND GS.Product_Name = CTE.Product_Name;



-- II. Analysis

-- Check overview cleaned dataset
SELECT TOP 10 *
FROM Data_Cleaned


-- Dimension: Order
-- Question 1: How many Orders in this dataset?
SELECT COUNT(*) AS All_row, COUNT(DISTINCT OrderID) AS Unique_Orders
FROM Data_Cleaned


-- Question 2: How many Orders for each year?
SELECT OY.Year_Number, COUNT(DISTINCT(OY.OrderID)) AS Orders
FROM (
	SELECT OrderID, YEAR(Order_Date) AS Year_Number
	FROM Data_Cleaned) AS OY
GROUP BY OY.Year_Number
ORDER BY OY.Year_Number


-- Question 3: How many Orders for each Ship Mode?
SELECT Ship_Mode, COUNT(DISTINCT(OrderID)) AS Orders 
FROM Data_Cleaned
GROUP BY Ship_Mode
ORDER BY COUNT(DISTINCT(OrderID))


-- Question 4: Order Prionity phổ biến?
WITH Order_Prionity
AS
(
SELECT OrderID, Order_Priority, COUNT(DISTINCT(Order_Priority)) AS Cnt
FROM Data_Cleaned
GROUP BY OrderID, Order_Priority
)
SELECT Order_Priority, COUNT(Order_Priority) AS Cnt_OrderPriority
FROM Order_Prionity
GROUP BY Order_Priority
ORDER BY COUNT(Order_Priority)


-- Question 5: Thời gian giao hàng phổ biến nhất
WITH Time_Ship
AS (
SELECT OrderID, DATEDIFF(DAY, Order_Date, Ship_Date) AS Time_Ship_Days
FROM Data_Cleaned
GROUP BY OrderID, Order_Date, Ship_Date ),
Total_TimeShip
AS (
SELECT COUNT(*) AS Total
FROM Time_Ship)

SELECT Time_Ship.Time_Ship_Days AS TimeShipDays,
	   COUNT(Time_Ship.Time_Ship_Days) AS Orders, 
	   CONCAT(COUNT(Time_Ship.Time_Ship_Days) * 100/ (SELECT Total_TimeShip.Total FROM Total_TimeShip),'%') AS Percentage
FROM Time_Ship
GROUP BY Time_Ship.Time_Ship_Days
ORDER BY COUNT(Time_Ship.Time_Ship_Days)




-- Dimension: Customer
-- Question 6: How many customer?
SELECT COUNT(DISTINCT Customer_ID) AS CNT_Customer
FROM Data_Cleaned


-- Question 7: How many new customers for each year?
WITH Customer_Info
AS
(
SELECT Customer_ID, 
	   Customer_Name, 
	   YEAR(Order_Date) AS FirstBuy_Year,
	   DENSE_RANK() OVER(PARTITION BY Customer_ID ORDER BY Order_Date) AS FirstTime_Customer
FROM Data_Cleaned)

SELECT Customer_Info.FirstBuy_Year AS 'Year',
	   COUNT(DISTINCT(Customer_Info.Customer_ID)) AS New_Customers
FROM Customer_Info
WHERE Customer_Info.FirstTime_Customer = 1
GROUP BY Customer_Info.FirstBuy_Year
ORDER BY Customer_Info.FirstBuy_Year


-- Question 8: Có bao nhiêu Phân loại (Segment) khách hàng, số lượng khách hàng, doanh thu và tỷ trọng trong mỗi Segment như thế nào?
WITH Total_Segment
AS
(
	SELECT COUNT(DISTINCT(Customer_ID)) AS Cnt_Customer,
		   SUM(Sales) AS Total_Sales
	FROM Data_Cleaned
)
SELECT Segment, 
	   COUNT(DISTINCT(Customer_ID)) AS Customer_of_Segment,
	   CONCAT(COUNT(DISTINCT(Customer_ID)) *100 / (SELECT Cnt_Customer FROM Total_Segment),'%') AS Customer_Percentage,
	   SUM(Sales) AS Sales_of_Segment,
	   CONCAT(ROUND(SUM(Sales) * 100 / (SELECT Total_Sales FROM Total_Segment),2), '%') AS Sales_Percentage
FROM Data_Cleaned
GROUP BY Segment
ORDER BY COUNT(Segment)



-- Dimension: Place
-- Question 9: Công ty hoạt động ở những thị trường nào, số quốc gia ở mỗi trị và doanh thu mang lại của từng thị trường đó?
WITH Total_Sales
AS
(
	SELECT SUM(Sales) AS Total_Sales
	FROM Data_Cleaned
)
SELECT Market,
	   COUNT(DISTINCT(Country)) AS Cnt_Country,
	   SUM(Sales) AS Sum_Sales,
	   CONCAT(ROUND(SUM(Sales) * 100 / (SELECT Total_Sales FROM Total_Sales),2), '%') AS Sales_Percentage
FROM Data_Cleaned
GROUP BY Market
ORDER BY COUNT(DISTINCT(Country))



-- Dimension: Product
-- Question 10: How many distinct Products?
SELECT COUNT(DISTINCT(Product_ID)) AS Cnt_Distinct_Product
FROM Data_Cleaned

-- Top 5 best seller product
SELECT TOP 5 Product_ID, Product_Name, SUM(Quantity) AS Sum_Quantity, SUM(Sales) AS Sum_Sales
FROM Data_Cleaned
GROUP BY Product_ID, Product_Name
ORDER BY SUM(Quantity) DESC


-- Question 11: Nhóm ngành hàng chủ đạo của công ty? (Doanh thu và tỷ trọng của từng Category)
WITH Summaries
AS 
(
	SELECT SUM(Sales) AS Sum_Sales,
		   SUM(Quantity) AS Sum_Quantity
	FROM Data_Cleaned
)

SELECT Category, 
	   COUNT(DISTINCT(Product_ID)) AS Cnt_Distinct_Product,
	   SUM(Quantity) AS Total_Quantity,
	   CONCAT(ROUND(SUM(Quantity) * 100 / (SELECT Sum_Quantity FROM Summaries),2), '%') AS Quantity_Percentage,
	   SUM(Sales) AS Total_Sales,
	   CONCAT(ROUND(SUM(Sales) * 100 / (SELECT Sum_Sales FROM Summaries),2), '%') AS Sales_Percentage
FROM Data_Cleaned
GROUP BY Category 
ORDER BY SUM(Quantity)


-- Question 12: 
-- Top 5 sản phẩm có giá bán cao nhất?
SELECT TOP 5 Product_ID,
	   Product_Name,
	   Category,
	   AVG(Unit_Price) AS Avg_UnitPrice
FROM Data_Cleaned
GROUP BY Product_ID, Product_Name, Category
ORDER BY AVG(Unit_Price) DESC

-- Top 5 sản phẩm có giá bán thấp nhất
SELECT TOP 5 Product_ID,
	   Product_Name,
	   Category,
	   AVG(Unit_Price) AS Avg_UnitPrice
FROM Data_Cleaned
GROUP BY Product_ID, Product_Name, Category
ORDER BY AVG(Unit_Price) ASC



-- Dimension: Sales
-- Question 13: Số lượng sản phẩm bán ra, Chi phí ship, Doanh thu và lợi nhuận qua từng năm
SELECT YEAR(Order_Date) AS 'Year',
	   SUM(Quantity) AS Total_Quantity,
	   SUM(Shipping_Cost) AS Total_ShippingCost,
	   SUM(Sales) AS Total_Sales,
	   SUM(Profit) AS Total_Profit
FROM Data_Cleaned
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date)


-- Question 14: Doanh thu theo ngày trong tuần?
SELECT DATENAME(WEEKDAY, Order_Date) AS WeekDayName,
	   SUM(Sales) AS Total_Sales
FROM Data_Cleaned
GROUP BY DATENAME(WEEKDAY, Order_Date)
ORDER BY SUM(Sales) DESC


-- Question 15: Tỷ lệ Discount phổ biến?
SELECT Discount, COUNT(Discount) AS Cnt_Discount
FROM Data_Cleaned
GROUP BY Discount
ORDER BY COUNT(Discount) DESC



-- III. Create Data Modeling

-- Step 1: Create Tables:

--- 1.Create Table Sales
CREATE TABLE Sales (
    OrderID VARCHAR(50),
    OrderDate DATE,
    ShipDate DATE,
    ShipModeID INT,
    CustomerID VARCHAR(50),
    ProductID VARCHAR(50),
    RegionID INT,
    Sales FLOAT,
	UnitPrice FLOAT,
    Quantity INT,
    Discount FLOAT,
    Profit FLOAT,
    ShippingCost FLOAT,
    OrderPriorityID INT
);

--- 2. Create Table Product
CREATE TABLE Product (
    ProductID VARCHAR(50),
    CategoryID INT,
    SubCategoryID INT,
    ProductName NVARCHAR(255)
);

--- 3. Create Table Category
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(50)
);

--- 4. Create Table Sub_Category
CREATE TABLE Sub_Category (
    SubCategoryID INT PRIMARY KEY IDENTITY(1,1),
    SubCategoryName NVARCHAR(50)
);

--- 5. Create Table Region
CREATE TABLE Region (
    RegionID INT PRIMARY KEY IDENTITY(1,1),
    City NVARCHAR(100),
    State NVARCHAR(100),
    CountryID INT,
    MarketID INT
);

--- 6. Create Table Market
CREATE TABLE Market (
    MarketID INT PRIMARY KEY IDENTITY(1,1),
    MarketName NVARCHAR(100)
);

--- 7. Create Table Country
CREATE TABLE Country (
    CountryID INT PRIMARY KEY IDENTITY(1,1),
    CountryName NVARCHAR(100)
);

--- 8. Create Table Customer
CREATE TABLE Customer (
    CustomerID VARCHAR(50) PRIMARY KEY,
    CustomerName NVARCHAR(255),
    SegmentID INT
);

--- 9. Create Table Cusomter_Segment
CREATE TABLE Customer_Segment (
    SegmentID INT PRIMARY KEY IDENTITY(1,1),
    SegmentName NVARCHAR(100)
);

--- 10. Create Table Ship_Mode
CREATE TABLE Ship_Mode (
    ShipModeID INT PRIMARY KEY IDENTITY(1,1),
    ShipMode NVARCHAR(50)
);

--- 11. Create Table Order_Priority
CREATE TABLE Order_Priority (
    OrderPriorityID INT PRIMARY KEY IDENTITY(1,1),
    OrderPriority NVARCHAR(50)
);



-- Step 2: Insert Data in Tables

--- 1. Insert Data in Category Table
INSERT INTO [dbo].[Category] (CategoryName)
SELECT DISTINCT
    Category
FROM [dbo].[Data_Cleaned];

--- 2. Insert Data in Sub_Category Table
INSERT INTO [dbo].[Sub_Category] (SubCategoryName)
SELECT DISTINCT
    Sub_Category
FROM [dbo].[Data_Cleaned];

--- 3. Insert Data in Market Table
INSERT INTO [dbo].[Market] (MarketName)
SELECT DISTINCT
    Market
FROM [dbo].[Data_Cleaned];

--- 4. Insert Data in Country Table
INSERT INTO [dbo].[Country] (CountryName)
SELECT DISTINCT
    Country
FROM [dbo].[Data_Cleaned];

--- 5. Insert Data in Customer Segment Table
INSERT INTO [dbo].[Customer_Segment] (SegmentName)
SELECT DISTINCT
    Segment
FROM [dbo].[Data_Cleaned];

--- 6. Insert Data in Ship Mode
INSERT INTO [dbo].[Ship_Mode] (ShipMode)
SELECT DISTINCT
    Ship_Mode
FROM [dbo].[Data_Cleaned];

--- 7. Insert Data in Product Table
INSERT INTO [dbo].[Product] (ProductID, CategoryID, SubCategoryID, ProductName)
SELECT DISTINCT
    Product_ID,
    (SELECT CategoryID FROM [dbo].[Category] WHERE CategoryName = [dbo].[Data_Cleaned].Category),
    (SELECT SubCategoryID FROM [dbo].[Sub_Category] WHERE SubCategoryName = [dbo].[Data_Cleaned].Sub_Category),
    Product_Name
FROM [dbo].[Data_Cleaned];

--- 8. Insert Data in Region Table
INSERT INTO [dbo].[Region] (City, State, CountryID, MarketID)
SELECT DISTINCT
    City,
    State,
    (SELECT CountryID FROM Country WHERE CountryName = [dbo].[Data_Cleaned].Country),
    (SELECT MarketID FROM Market WHERE MarketName = [dbo].[Data_Cleaned].Market)
FROM [dbo].[Data_Cleaned];

--- 9. Insert Data in Customer Table
INSERT INTO [dbo].[Customer] (CustomerID, CustomerName, SegmentID)
SELECT DISTINCT
    Customer_ID,
    Customer_Name,
    (SELECT SegmentID FROM Customer_Segment WHERE SegmentName = [dbo].[Data_Cleaned].Segment)
FROM [dbo].[Data_Cleaned];

--- 10. Insert Data in Order Priority Table
INSERT INTO [dbo].[Order_Priority] (OrderPriority)
SELECT DISTINCT
    Order_Priority
FROM [dbo].[Data_Cleaned];

--- 11. Insert Data in Sales Table
INSERT INTO Sales (OrderID, OrderDate, ShipDate, ShipModeID, CustomerID, ProductID, RegionID, Sales, UnitPrice, Quantity, Discount, Profit, ShippingCost, OrderPriorityID)
SELECT
    dc.OrderID,
    dc.Order_Date,
    dc.Ship_Date,
    sm.ShipModeID,
    dc.Customer_ID,
    dc.Product_ID,
    r.RegionID,
    dc.Sales,
	dc.Unit_Price,
    dc.Quantity,
    dc.Discount,
    dc.Profit,
    dc.Shipping_Cost,
    op.OrderPriorityID
FROM [dbo].[Data_Cleaned] dc
LEFT JOIN [dbo].[Ship_Mode] sm ON dc.Ship_Mode = sm.ShipMode
LEFT JOIN [dbo].[Region] r ON dc.City = r.City
    AND dc.State = r.State
    AND r.CountryID = (SELECT CountryID FROM [dbo].[Country] WHERE CountryName = dc.Country)
    AND r.MarketID = (SELECT MarketID FROM [dbo].[Market] WHERE MarketName = dc.Market)
LEFT JOIN [dbo].[Order_Priority] op ON dc.Order_Priority = op.OrderPriority;



-- Step 3: Create Forgein Keys

--- 1. Sales Table
ALTER TABLE [dbo].[Sales]
ADD CONSTRAINT FK_OrderPriority FOREIGN KEY (OrderPriorityID)
REFERENCES [dbo].[Order_Priority](OrderPriorityID);

ALTER TABLE [dbo].[Sales]
ADD CONSTRAINT FK_ShipMode FOREIGN KEY (ShipModeID)
REFERENCES [dbo].[Ship_Mode](ShipModeID);

ALTER TABLE [dbo].[Sales]
ADD CONSTRAINT FK_Customer FOREIGN KEY (CustomerID)
REFERENCES [dbo].[Customer](CustomerID);

ALTER TABLE [dbo].[Sales]
ADD CONSTRAINT FK_Region FOREIGN KEY (RegionID)
REFERENCES [dbo].[Region](RegionID);

--- 2. Product Table
ALTER TABLE [dbo].[Product]
ADD CONSTRAINT FK_Category FOREIGN KEY (CategoryID)
REFERENCES [dbo].[Category](CategoryID);

ALTER TABLE [dbo].[Product]
ADD CONSTRAINT FK_SubCategory FOREIGN KEY (SubCategoryID)
REFERENCES [dbo].[Sub_Category](SubCategoryID);

--- 3. Region Table
ALTER TABLE [dbo].[Region]
ADD CONSTRAINT FK_Country FOREIGN KEY (CountryID)
REFERENCES [dbo].[Country](CountryID);

ALTER TABLE [dbo].[Region]
ADD CONSTRAINT FK_Market FOREIGN KEY (MarketID)
REFERENCES [dbo].[Market](MarketID);

--- 4. Customer Table
ALTER TABLE [dbo].[Customer]
ADD CONSTRAINT FK_Segment FOREIGN KEY (SegmentID)
REFERENCES [dbo].[Customer_Segment](SegmentID);




