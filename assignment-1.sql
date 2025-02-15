-- 1. Create the database
CREATE DATABASE EcommerceDB;
-- 2. Switch to the newly created database
--\c EcommerceDB;
-- 3. Create Customers table
CREATE TABLE Customers (
    CustomerId SERIAL PRIMARY KEY,  
    Name VARCHAR(100) NOT NULL,  
    Email VARCHAR(100) UNIQUE NOT NULL,  
    Address TEXT,  
    Phone VARCHAR(15) ,  
    RegistrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
    CHECK (Phone ~ '^[0-9]{10,15}$') 
    CHECK (Email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
);
-- 4. Create Products table
CREATE TABLE Products (
    ProductID SERIAL PRIMARY KEY,  
    ProductName VARCHAR(100) NOT NULL,  
    Category VARCHAR(50),  
    Price DECIMAL(10,2) NOT NULL,  
    Stock INT NOT NULL 
    CHECK (Stock >= 0)
    CHECK (Price >=0)
);
-- 5. Create Orders table
CREATE TABLE Orders (
    OrderId SERIAL PRIMARY KEY,  
    CustomerId INT NOT NULL,  
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    TotalAmount DECIMAL(10,2), 
    CONSTRAINT FK_customerid FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId) ON DELETE CASCADE
);
-- 6. Create OrderDetails table
CREATE TABLE OrderDetails (
    OrderDetailId SERIAL PRIMARY KEY,  
    OrderID INT NOT NULL,  
    ProductID INT NOT NULL,  
    Quantity INT NOT NULL,  
    SubTotal DECIMAL(10,2), 
    CONSTRAINT FK_orderid FOREIGN KEY (OrderID) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_productid FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE
);
-- 7. Insert sample data into Customers table
INSERT INTO Customers (Name, Email, Address, Phone) VALUES
('Sudipto Das', 'sudi@gmail.com', 'West Bengal', '9342388900'),
('Susovon Mondol', 'susoe@gmail.com', 'West Bengal', '8772378300'),
('Jaydeep', 'jay@gmail.com', 'Gujrat', '9834793440'),
('Rohit', 'rohit@gmail..com', 'West Bengal', '7737123790'),
('Rishav', 'rish@gmail.com', 'Bihar', '9937883960');
-- 8. Insert sample data into Products table
INSERT INTO Products (ProductName, Category, Price, Stock) VALUES
('Laptop', 'Electronics', 9999.90, 10),
('Smartphone', 'Electronics', 6999.90, 25),
('Desk Chair', 'Furniture', 1499.90, 30),
('Bluetooth Headphones', 'Accessories', 1999.90, 15),
('Coffee Maker', 'Appliances', 899.90, 20);
-- 9. Insert sample data into Orders table
INSERT INTO Orders (CustomerId, OrderDate, TotalAmount) VALUES
(1, '2025-02-07 10:00:00', 16999.80),
(2, '2025-02-08 11:30:00', 2999.80),
(3, '2025-02-09 14:15:00', 899.90),
(4, '2025-02-10 15:00:00', 11999.80),
(5, '2025-02-11 16:45:00', 13999.80);
-- 10. Insert sample data into OrderDetails table
--subtotals are calculated as Price * Quantity
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, SubTotal) VALUES
(1, 1, 1, 9999.90),
(1, 2, 1, 6999.90),
(2, 3, 2, 2999.80),
(3, 5, 1, 899.90),
(4, 1, 1, 9999.90),
(4, 4, 1, 1999.90),
(5, 2, 2, 13999.80);

-- 11. Retrieve orders for a specific customer (CustomerID = 1)

SELECT C.Name AS CustomerName, P.ProductName, O.OrderDate, OD.Quantity
FROM Orders O
JOIN Customers C ON O.CustomerId = C.CustomerId
JOIN OrderDetails OD ON OD.OrderId = O.OrderId
JOIN Products P ON OD.ProductId = P.ProductId
WHERE C.CustomerId = 1;
/*
customername | productname |      orderdate      | quantity 
--------------+-------------+---------------------+----------
 Sudipto Das  | Laptop      | 2025-02-07 10:00:00 |        1
 Sudipto Das  | Smartphone  | 2025-02-07 10:00:00 |        1
(2 rows)
*/

-- 12. Find the most purchased product based on total quantity sold

SELECT P.ProductName, SUM(OD.Quantity) AS TotalQuantitySold
FROM OrderDetails OD
JOIN Products P ON P.ProductId = OD.ProductId 
GROUP BY P.ProductId
ORDER BY TotalQuantitySold DESC
LIMIT 1; 
/*
productname | totalquantitysold 
-------------+-------------------
 Smartphone  |                 3
(1 row)
*/


-- 13. Update stock quantity after an order is placed for a specific product (ProductID = 1)

UPDATE Products 
SET Stock = Stock - (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductId = 1) --this will update the stock quantity after an order is placed
WHERE ProductId = 1;

-- 14. Delete a customer record (CustomerID = 5) while maintaining referential integrity
DELETE FROM Customers WHERE CustomerID = 5; --this will delete the customer record with CustomerID = 5 without violating referential integrity
