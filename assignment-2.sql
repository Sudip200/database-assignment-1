--Task 1: Advanced SQL Queries 
--Retrieve the top 3 customers with the highest total purchase amount.
SELECT C.Name ,C.CustomerId ,SUM(O.totalamount) AS TotalPurchase  FROM Customers C JOIN Orders O ON 
O.CustomerId = C.CustomerId GROUP BY C.CustomerId ORDER BY TotalPurchase DESC  LIMIT 3

--Show monthly sales revenue for the last 6 months using PIVOT.
SELECT 
    P.ProductName,
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
RETURNS INT AS $$
DECLARE
    order_ID INT;
    i INT;
BEGIN 
    INSERT INTO Orders (CustomerId, TotalAmount) 
    VALUES (customerId, 0)
    RETURNING OrderID INTO order_ID;

    FOR i IN 1 .. array_length(productArray, 1) LOOP
        INSERT INTO OrderDetails (OrderID, Quantity, ProductId, Subtotal)
        VALUES (order_ID, quantityArray[i], productArray[i], 
                (SELECT Price FROM Products WHERE ProductId = productArray[i]));
        UPDATE Products 
        SET Stock = Stock - quantityArray[i]
        WHERE ProductId = productArray[i] 
        AND Stock >= quantityArray[i];
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'Insufficient Stock';
        END IF;
    END LOOP;
    UPDATE Orders 
    SET TotalAmount = (SELECT SUM(Subtotal) FROM OrderDetails WHERE OrderID = order_ID)
    WHERE OrderID = order_ID;
    RETURN order_ID;
END;
$$ LANGUAGE plpgsql;
SELECT create_order(3,ARRAY[1,2,3],ARRAY[1,1,1]);


CREATE OR REPLACE FUNCTION getCustomerSpent(Customer_ID INT)
RETURNS INT AS $$
DECLARE 
total_spent INT;
BEGIN 
  SELECT SUM(o.totalAmount) INTO total_spent FROM Orders o JOIN Customers c ON o.CustomerId= c.CustomerId WHERE c.CustomerId = Customer_Id;
  RETURN total_spent;
END;

$$ LANGUAGE plpgsql

SELECT getCustomerSpent(4);

-- Task 3: Transactions and Concurrency Control


CREATE OR REPLACE FUNCTION create_order_with_transaction(customerId INT, productArray INT[], quantityArray INT[])
RETURNS INT AS $$
DECLARE
    order_ID INT;
    i INT;
    _price DECIMAL(10,2);
    _stock INT;
    totalAmt DECIMAL(10,2) := 0;
    is_transaction_successfull BOOLEAN := FALSE;
    retry INT := 0;
BEGIN
   
           -- SAVEPOINT start_order;

            INSERT INTO Orders (CustomerId, TotalAmount)
            VALUES (customerId, 0)
            RETURNING OrderID INTO order_ID;

            FOR i IN 1 .. array_length(productArray, 1) LOOP
                SELECT Stock, Price INTO _stock, _price FROM Products WHERE ProductId = productArray[i] FOR UPDATE;

                IF _stock < quantityArray[i] THEN
                    RAISE EXCEPTION 'Out of Stock for Product ID %', productArray[i];
                    ROLLBACK;
                    CONTINUE;
                END IF;

                INSERT INTO OrderDetails (OrderID, Quantity, ProductId, Subtotal)
                VALUES (order_ID, quantityArray[i], productArray[i], _price * quantityArray[i]);

                UPDATE Products
                SET Stock = Stock - quantityArray[i]
                WHERE ProductId = productArray[i];

                totalAmt := totalAmt + (_price * quantityArray[i]);

                is_transaction_successfull := TRUE;
            END LOOP;

            IF NOT is_transaction_successfull THEN
                ROLLBACK;
                RAISE EXCEPTION 'Order cancelled due to stock issues';
            END IF;

            UPDATE Orders
            SET TotalAmount = totalAmt
            WHERE OrderID = order_ID;

            RETURN order_ID;

        EXCEPTION
            WHEN serialization_failure THEN
                IF retry < 3 THEN
                    retry := retry + 1;
                    ROLLBACK;
                ELSE
                    RAISE EXCEPTION 'Transaction failed after 3 attempts';
                END IF;
        END;

$$ LANGUAGE plpgsql;

SELECT create_order_with_transaction(3,ARRAY[1,2,3],ARRAY[1,1,1000]);

--Task 4: SQL for Reporting and Analytics

--Generate a customer purchase report using ROLLUP that includes:

SELECT C.Name AS CustomerName,P.ProductName, SUM(OD.Quantity) AS Quantity,SUM(OD.Subtotal) AS Subtotal,SUM(O.totalamount) AS GrandTotal 
FROM Orders O
JOIN Customers C ON O.CustomerId = C.CustomerId
JOIN OrderDetails OD ON OD.OrderId = O.OrderId
JOIN Products P ON OD.ProductId = P.ProductId
GROUP BY  ROLLUP (c.Name,P.ProductName) HAVING (C.Name IS NOT NULL AND P.ProductName IS NOT NULL) 
ORDER BY (C.Name,P.ProductName);

-- Use window functions (LEAD, LAG) to show how a customer's order amount compares to their previous order amount.

SELECT C.Name AS CustomerName,  O.OrderDate,O.TotalAmount AS CurrentAmount ,LAG(O.TotalAmount) OVER (
PARTITION BY O.CustomerID ORDER BY O.OrderDate) AS PreviousAmount,
LAG(O.TotalAmount) OVER (
PARTITION BY O.CustomerID ORDER BY O.OrderDate) AS NextAmount
FROM Orders O
JOIN Customers C ON O.CustomerId = C.CustomerId ORDER BY C.CustomerId ,O.OrderDate;


