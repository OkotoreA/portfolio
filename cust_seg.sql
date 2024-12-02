-- creating database
create database cust_seg;
--  making the database active
use cust_seg;
-- importing the csv files into the database

-- selecting all information in the table 
select * from list_of_orders;
select * from order_details;
select * from sales_target;

-- counting of rows in the table 
select count(*) from sales_target;
select count(*) from order_details;
select count(*) from list_of_orders;

-- Create a deduplicated version of Order Details
CREATE TABLE Deduplicated_Order_Details AS
SELECT 
    `OrderID`,
    sum(`Amount`) AS TotalAmount,
    sum(`Profit`) AS TotalProfit,
    SUM(`Quantity`) AS TotalQuantity,
    GROUP_CONCAT(DISTINCT `Category` SEPARATOR ', ') AS Categories,
    GROUP_CONCAT(DISTINCT `Sub_Category` SEPARATOR ', ') AS SubCategories
FROM 
    `Order_Details`
GROUP BY 
    `OrderID`;
select * from Deduplicated_Order_Details;

-- Create Order Details Table with Primary Key
CREATE TABLE Order_Details_Clean (
    `OrderID` VARCHAR(30) PRIMARY KEY,
    `TotalAmount` DECIMAL(10, 2),
    `TotalProfit` DECIMAL(10, 2),
    `TotalQuantity` INT,
    `Categories` VARCHAR(255),
    `SubCategories` VARCHAR(255)
);

-- Create List of Orders Table with Foreign Key
CREATE TABLE List_of_Orders_Clean (
    `OrderID` VARCHAR(30),
    `OrderDate` TEXT,
    `CustomerName` VARCHAR(255),
    `State` VARCHAR(100),
    `City` VARCHAR(100),
    FOREIGN KEY (`OrderID`) REFERENCES Order_Details_Clean(`OrderID`)
);


-- Insert data into Order Details Clean Table
INSERT INTO Order_Details_Clean
SELECT * FROM Deduplicated_Order_Details;

-- Insert data into List of Orders Clean Table
INSERT INTO List_of_Orders_Clean
SELECT * FROM `List_of_Orders`;
    
-- joining the two tables together, export it and re-import it as merged data 
SELECT 
    l.orderID,
    l.orderDate,
    l.CustomerName,
    l.state,
    l.city,
    o.TotalAmount,
    o.TotalProfit,
    o.Totalquantity,
    o.Categories,
    o.subcategories
FROM
    order_details_clean AS o
        INNER JOIN
    list_of_orders_clean AS l ON l.OrderID = o.OrderID;
    select count(*) from merged_data;

 select * from merged_data;  
 
 
 -- perform data transformation by changing the orderdate to normal date format 
-- add a new column for date to serve as replicate 
alter table merged_data add column neworderdate text;
-- inserting the changed date values into the new column
update merged_data set neworderdate = orderDate;
UPDATE merged_data
SET `neworderdate` = CASE
    WHEN `neworderdate` LIKE '%/%/%' THEN STR_TO_DATE(`neworderdate`, '%m/%d/%Y') -- For dates like 2/10/2022
    WHEN `neworderdate` LIKE '%-%-%' THEN STR_TO_DATE(`neworderdate`, '%d-%m-%Y') -- For dates like 02-10-2022
    ELSE NULL
END;
update merged_data set neworderdate = date_format(str_to_date(neworderdate, '%m/%d/%Y'), '%Y/%m/%d');
-- change the data type to date format 
alter table merged_data modify column neworderdate date;

   
-- •	Identify customer purchase patterns
SELECT 
    customername,
    COUNT(DISTINCT orderID) AS Totalorders,
    SUM(TotalAmount) as Totalamount,
    SUM(TotalQuantity) as Totalquantity,
    SUM(TotalProfit) as Totalprofit,
    MAX(neworderdate) as last_purchased_date,
    MIN(neworderdate) as first_purchased_date
FROM
    merged_data
GROUP BY CustomerName order by TotalAmount desc;

-- extracting categories with highest sales and order quantity
SELECT 
    categories,
    SUM(TotalAmount) AS Totalamount,
    SUM(TotalProfit) AS TotalProfit
FROM
    merged_data
group by
	categories;
    
-- 2.	Group customers into segments 
SELECT 
    CustomerName,
    SUM(TotalAmount) AS TotalAmount,
    CASE 
        WHEN SUM(TotalAmount) < 5000 THEN 'Low Sales'
        WHEN SUM(TotalAmount) >= 5000 THEN 'High Sales'
    END AS SalesCategory
FROM 
    merged_data
GROUP BY 
    CustomerName
ORDER BY 
    CustomerName;
-- product category with the highest profit
SELECT 
    Categories, SUM(TotalProfit) AS TotalProfit
FROM
    merged_data
GROUP BY Categories
ORDER BY TotalProfit DESC;

-- •	Extract actionable customer groups for targeted marketing strategies.
-- Step 1: Segment Customers by Total Spending
SELECT 
    CustomerName,
    SUM(TotalAmount) AS TotalAmount,
    CASE 
        WHEN SUM(TotalAmount) < 5000 THEN 'Low Spender'
        WHEN SUM(TotalAmount) BETWEEN 5000 AND 15000 THEN 'Medium Spender'
        WHEN SUM(TotalAmount) > 15000 THEN 'High Spender'
    END AS SpendingCategory
FROM 
    merged_data
GROUP BY 
    CustomerName
ORDER BY 
    TotalAmount DESC;

-- Step 2: Segment Customers by Frequency of Purchases
SELECT 
    CustomerName,
    COUNT(DISTINCT OrderID) AS PurchaseFrequency,
    CASE 
        WHEN COUNT(DISTINCT OrderID) <= 2 THEN 'Infrequent Buyer'
        WHEN COUNT(DISTINCT OrderID) BETWEEN 3 AND 5 THEN 'Moderate Buyer'
        WHEN COUNT(DISTINCT OrderID) > 5 THEN 'Frequent Buyer'
    END AS FrequencyCategory
FROM 
    merged_data
GROUP BY 
    CustomerName
ORDER BY 
    PurchaseFrequency DESC;

-- Step 3: Segment Customers by Product Categories Purchased
SELECT 
    CustomerName,
    GROUP_CONCAT(DISTINCT Categories) AS PurchasedCategories,
    COUNT(DISTINCT Categories) AS CategoryCount
FROM 
    merged_data
GROUP BY 
    CustomerName
ORDER BY 
    CategoryCount DESC;
 


