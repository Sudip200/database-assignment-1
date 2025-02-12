--CREATE DATABASE EcommerceDB;

CREATE TABLE Customers(
CustomerId SERIAL PRIMARY KEY,
Name VARCHAR(100) NOT NULL,
Email VARCHAR(100) UNIQUE NOT NULL,
Address TEXT,
Phone VARCHAR(15),
RegistrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Products(
ProductID SERIAL PRIMARY KEY,
ProductName VARCHAR(100) NOT NULL,
Category VARCHAR(50),
Price DECIMAL(10,2) NOT NULL,
Stock INT NOT NULL
);

CREATE TABLE Orders (
    OrderId SERIAL PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10,2),
    CONSTRAINT FK_customerid FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId) ON DELETE CASCADE 
);

CREATE TABLE OrderDetails(
OrderDetailId SERIAL PRIMARY KEY,
OrderID INT NOT NULL,
ProductID INT NOT NULL,
Quantity INT NOT NULL ,
SubTotal DECIMAL(10,2),
CONSTRAINT Fk_orderid FOREIGN KEY(OrderID) REFERENCES Orders(OrderId) ON DELETE CASCADE,
CONSTRAINT FK_productid FOREIGN KEY(ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE 
);

INSERT INTO Customers (Name, Email, Address, Phone) VALUES
('Sudipto Das', 'sudi@example.com', '123 Elm Street', '934238890'),
('Susovon Mondol', 'susoe@example.com', '456 Maple Avenue', '87723783'),
('Jaydeep', 'jay@example.com', '789 Oak Lane', '983479344'),
('Rohit', 'rohit@example.com', '321 Pine Road', '773712379'),
('Rishav', 'rish@example.com', '654 Cedar Street', '99378839');

INSERT INTO Products (ProductName, Category, Price, Stock) VALUES
('Laptop', 'Electronics', 999.99, 10),
('Smartphone', 'Electronics', 699.99, 25),
('Desk Chair', 'Furniture', 149.99, 30),
('Bluetooth Headphones', 'Accessories', 199.99, 15),
('Coffee Maker', 'Appliances', 89.99, 20);

INSERT INTO Orders (CustomerId, OrderDate, TotalAmount) VALUES
(1, '2025-02-12 10:00:00', 1699.98), 
(2, '2025-02-12 11:30:00', 299.98),  
(3, '2025-02-12 14:15:00', 89.99),   
(4, '2025-02-12 15:00:00', 1199.98), 
(5, '2025-02-12 16:45:00', 1399.98);

INSERT INTO OrderDetails (OrderID, ProductID, Quantity, SubTotal) VALUES
(1, 1, 1, 999.99), 
(1, 2, 1, 699.99),
(2, 3, 2, 299.98), 
(3, 5, 1, 89.99), 
(4, 1, 1, 999.99),
(4, 4, 1, 199.99), 
(5, 2, 2, 1399.98); 

SELECT C.Name AS CustomerName ,P.ProductName,O.OrderDate,OD.Quantity FROM Orders O 
JOIN Customers C ON O.CustomerId = C.CustomerId JOIN OrderDetails OD ON OD.OrderId = O.OrderId 
JOIN Products p ON OD.ProductId = p.ProductId WHERE C.CustomerId = 1;

SELECT P.ProductName ,SUM(OD.Quantity) AS TotalQuantitySold FROM OrderDetails OD JOIN 
Products P ON P.ProductId = OD.ProductId  GROUP BY P.ProductId ORDER BY TotalQuantitySold DESC LIMIT 1;

UPDATE Products  SET Stock = Stock -  (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductId=1) WHERE ProductId =1;

DELETE FROM Customers WHERE CustomerID=5;



