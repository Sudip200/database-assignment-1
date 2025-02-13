--Task 1: Advanced SQL Queries 
--Retrieve the top 3 customers with the highest total purchase amount.
SELECT C.Name ,C.CustomerId ,SUM(O.totalamount) AS TotalPurchase  FROM Customers C JOIN Orders O ON 
O.CustomerId = C.CustomerId GROUP BY C.CustomerId ORDER BY TotalPurchase DESC  LIMIT 3

--Show monthly sales revenue for the last 6 months using PIVOT.
-- as pivot is not supported in postgresql so using case when 
SELECT 
    P.ProductName,
    --sum function to calculate total amount for product name for each month by extracting month from order date 
    -- and comparing with current date by subtracting 5,4,3,2,1 and if month is current month then sum total amount
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) - 5 THEN O.TotalAmount ELSE 0 END) AS "Month_1",
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) - 4 THEN O.TotalAmount ELSE 0 END) AS "Month_2",
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) - 3 THEN O.TotalAmount ELSE 0 END) AS "Month_3",
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) - 2 THEN O.TotalAmount ELSE 0 END) AS "Month_4",
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) - 1 THEN O.TotalAmount ELSE 0 END) AS "Month_5",
    SUM(CASE WHEN EXTRACT(MONTH FROM O.OrderDate) = EXTRACT(MONTH FROM CURRENT_DATE) THEN O.TotalAmount ELSE 0 END) AS "Current_Month"
FROM 
    Products P 
JOIN 
    OrderDetails OD ON P.ProductId = OD.ProductId 
JOIN 
    Orders O ON O.OrderId = OD.OrderId
GROUP BY 
    P.ProductName;


--Find the second most expensive product in each category using window functions.

SELECT ProductName ,Price , Category FROM (SELECT ProductName ,Price , Category ,RANK() OVER (PARTITION BY Category ORDER BY Price DESC ) AS RankOfProduct FROM Products)
AS ranked_products WHERE ranked_products.RankOfProduct=2;



--Task 2: Stored Procedures and Functions

CREATE OR REPLACE FUNCTION create_order(customerId INT, productArray INT[], quantityArray INT[])
--create order function that takes customerId, productArray, quantityArray as input and returns orderID
RETURNS INT AS $$ --function body
DECLARE
    order_ID INT;--variable to store orderID
    i INT; --variable to iterate over productArray
BEGIN 
   --insert into orders table and store orderID in order_ID total amount is 0 initially for the order
    INSERT INTO Orders (CustomerId, TotalAmount) 
    VALUES (customerId, 0)
    RETURNING OrderID INTO order_ID;
    --iterate over productArray
    FOR i IN 1 .. array_length(productArray, 1) LOOP
        --insert into orderdetails table with orderID, productID, quantity and subtotal
        INSERT INTO OrderDetails (OrderID, Quantity, ProductId, Subtotal)
        VALUES (order_ID, quantityArray[i], productArray[i], 
                (SELECT Price FROM Products WHERE ProductId = productArray[i])*quantityArray[i]);
        --update stock in products table
        UPDATE Products 
        SET Stock = Stock - quantityArray[i]
        WHERE ProductId = productArray[i] 
        AND Stock >= quantityArray[i];
        --if stock is insufficient then raise exception
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'Insufficient Stock';
        END IF;
    END LOOP;
    --update total amount in orders table calculated from orderdetails table
    UPDATE Orders 
    SET TotalAmount = (SELECT SUM(Subtotal) FROM OrderDetails WHERE OrderID = order_ID)
    WHERE OrderID = order_ID;
    RETURN order_ID;
END;
--end of function body
$$ LANGUAGE plpgsql; --function language
--call the function with customerId=3, productArray=[1,2,3], quantityArray=[1,1,1]
SELECT create_order(3,ARRAY[1,2,3],ARRAY[1,1,1]);




--Function to get total amount spent by a customer
CREATE OR REPLACE FUNCTION getCustomerSpent(Customer_ID INT)
RETURNS INT AS $$
DECLARE 
total_spent INT; --variable to store total spent
BEGIN 
--select sum of total amount from orders table for a customer
  SELECT SUM(o.totalAmount) INTO total_spent FROM Orders o JOIN Customers c ON o.CustomerId= c.CustomerId WHERE c.CustomerId = Customer_Id;
  RETURN total_spent;
END;

$$ LANGUAGE plpgsql

SELECT getCustomerSpent(4); --call the function with CustomerId=4





-- Task 3: Transactions and Concurrency Control
/* 
    Write a transaction to ensure an order is placed only if all products are in stock. If any product is out of stock, rollback the transaction.
    Demonstrate how to handle deadlocks when updating order details.
    Use SAVEPOINT to allow partial updates in an order process where only some items might be out of stock.
*/

--Function to create order with transaction and retry mechanism
CREATE OR REPLACE FUNCTION create_order_with_transaction(customerId INT, productArray INT[], quantityArray INT[])
RETURNS INT AS $$
DECLARE
    order_ID INT; --variable to store orderID
    i INT; --variable to iterate over productArray
    _price DECIMAL(10,2); --variable to store price
    _stock INT; --variable to store stock
    totalAmt DECIMAL(10,2) := 0; --variable to store total amount
    is_transaction_successfull BOOLEAN := FALSE; --variable to store transaction status
    retry INT := 0; --variable to store retry count
BEGIN
   
           -- SAVEPOINT start_order;
           -- insert into orders table and store orderID in order_ID total amount is 0 initially for the order
            INSERT INTO Orders (CustomerId, TotalAmount)
            VALUES (customerId, 0)
            RETURNING OrderID INTO order_ID;
           -- iterate over productArray
            FOR i IN 1 .. array_length(productArray, 1) LOOP
                SELECT Stock, Price INTO _stock, _price FROM Products WHERE ProductId = productArray[i] FOR UPDATE;
            
                IF _stock < quantityArray[i] THEN --if stock is insufficient then raise exception
                    RAISE EXCEPTION 'Out of Stock for Product ID %', productArray[i];
                    ROLLBACK; --rollback transaction
                    CONTINUE; -- continue to next iteration
                END IF;
              -- insert into orderdetails table with orderID, productID, quantity and subtotal
                INSERT INTO OrderDetails (OrderID, Quantity, ProductId, Subtotal)
                VALUES (order_ID, quantityArray[i], productArray[i], _price * quantityArray[i]);
              -- update stock in products table
                UPDATE Products
                SET Stock = Stock - quantityArray[i]
                WHERE ProductId = productArray[i];
              -- update total amount
                totalAmt := totalAmt + (_price * quantityArray[i]);
              -- if reached last iteration then set transaction status to true
                is_transaction_successfull := TRUE;
            END LOOP;
            -- if transaction is successfull then update total amount in orders table
            IF NOT is_transaction_successfull THEN
                ROLLBACK;
                RAISE EXCEPTION 'Order cancelled due to stock issues';
            END IF;
            -- update total amount in orders table
            UPDATE Orders
            SET TotalAmount = totalAmt
            WHERE OrderID = order_ID;
            
            RETURN order_ID;

        EXCEPTION
         -- handle serialization failure (deadlock) means retry the transaction for 3 times
            WHEN serialization_failure THEN
                IF retry < 4 THEN
                    retry := retry + 1;
                    ROLLBACK;
                ELSE
                    RAISE EXCEPTION 'Transaction failed after 3 attempts';
                END IF;
        END;

$$ LANGUAGE plpgsql;

SELECT create_order_with_transaction(3,ARRAY[1,2,3],ARRAY[1,1,1000]); --result will be out of stock for product 3





--Task 4: SQL for Reporting and Analytics

--Generate a customer purchase report using ROLLUP that includes:

-- customer purchase report using ROLLUP that includes:
-- CustomerName, ProductName, Quantity, Subtotal, GrandTotal
-- GrandTotal is the total amount spent by the customer
-- Subtotal is the total amount spent on a specific product
-- Quantity is the total quantity of a specific product purchased by the customer

SELECT C.Name AS CustomerName,P.ProductName, SUM(OD.Quantity) AS Quantity,SUM(OD.Subtotal) AS Subtotal,SUM(O.totalamount) AS GrandTotal 
FROM Orders O
JOIN Customers C ON O.CustomerId = C.CustomerId
JOIN OrderDetails OD ON OD.OrderId = O.OrderId
JOIN Products P ON OD.ProductId = P.ProductId
GROUP BY  ROLLUP (c.Name,P.ProductName) HAVING (C.Name IS NOT NULL AND P.ProductName IS NOT NULL) 
ORDER BY (C.Name,P.ProductName);

-- Use window functions (LEAD, LAG) to show how a customer's order amount compares to their previous order amount.

--customer's order amount compares to their previous order amount using LEAD and LAG
--CustomerName, OrderDate, CurrentAmount, PreviousAmount, NextAmount
--CurrentAmount is the total amount of the current order
--PreviousAmount is the total amount of the previous order
--NextAmount is the total amount of the next order

SELECT C.Name AS CustomerName,  O.OrderDate,O.TotalAmount AS CurrentAmount ,LAG(O.TotalAmount) OVER (
PARTITION BY O.CustomerID ORDER BY O.OrderDate) AS PreviousAmount,
LAG(O.TotalAmount) OVER (
PARTITION BY O.CustomerID ORDER BY O.OrderDate) AS NextAmount
FROM Orders O
JOIN Customers C ON O.CustomerId = C.CustomerId ORDER BY C.CustomerId ,O.OrderDate;



