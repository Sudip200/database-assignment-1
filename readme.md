#  E-Commerce Database Schema
##  Overview 
This project defines a **PostgreSQL database schema** for an **E-Commerce Store**, handling **Customers, Products, Orders, and OrderDetails** with proper normalization (3NF).
---
## **Entities and Attributes** 
### **Customers** 
<<<<<<< HEAD
- **Primary Key:** `CustomerID`
- **Attributes:** `Name`, `Email`, `Address`, `Phone`, `Registration Date`
=======
- **Primary Key:** `CustomerId`
- **Attributes:** `Name`, `Email`, `Address`, `Phone`, `RegistrationDate`
>>>>>>> 5529b65d85e14b3fc0e0be6f050e53e1b959d176
### **Products** 
- **Primary Key:** `ProductID`
- **Attributes:** `ProductName`, `Category`, `Price`, `Stock`
### **Orders** 
<<<<<<< HEAD
- **Primary Key:** `OrderID`
- **Foreign Key:** `CustomerID` (References `Customers`)
- **Attributes:** `OrderDate`, `TotalAmount`
### **OrderDetails** 
- **Primary Key:** `OrderDetailID`
- **Foreign Keys:** `OrderID` (References `Orders`), `ProductID` (References `Products`)
=======
- **Primary Key:** `OrderId`
- **Foreign Key:** `CustomerId` (References `Customers`)
- **Attributes:** `OrderDate`, `TotalAmount`
### **OrderDetails** 
- **Primary Key:** `OrderDetailId`
- **Foreign Keys:** `OrderId` (References `Orders`), `ProductID` (References `Products`)
>>>>>>> 5529b65d85e14b3fc0e0be6f050e53e1b959d176
- **Attributes:** `Quantity`, `SubTotal`
---
## **Relationships**
1. **Customers --> Orders** (1:M) → A customer can place multiple orders.
2. **Orders --> OrderDetails** (1:M) → Each order contains multiple products.
3. **Products --> OrderDetails** (1:M) → A product can appear in multiple orders.
---
## **Normalization (3NF)**
This database is in **Third Normal Form (3NF)** because:
- **1NF**: No repeating groups; all attributes contain atomic values. 
- **2NF**: No partial dependencies; every non-key attribute depends on the full primary key. 
- **3NF**: No transitive dependencies; all attributes depend only on the primary key.
---
## **Files Included**
<<<<<<< HEAD
- `ecom.sql` → Contains SQL queries for database setup, insertion, and triggers. 
=======
- `ecom.sql` → Contains SQL queries for database setup, insertion.
>>>>>>> 5529b65d85e14b3fc0e0be6f050e53e1b959d176
- `erdiagram.png` → Entity-Relationship Diagram. 
- `README.md` → Explanation of database design.
- **This database ensures data integrity, eliminates redundancy, and optimizes performance!**