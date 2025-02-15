#  E-Commerce Database Schema
##  Overview 
This project defines a **PostgreSQL database schema** for an **E-Commerce Store**, handling **Customers, Products, Orders, and OrderDetails** with proper normalization (3NF).
---
## **Entities and Attributes** 
### **Customers** 
- **Primary Key:** `CustomerId`
- **Attributes:** `Name`, `Email`, `Address`, `Phone`, `RegistrationDate`
### **Products** 
- **Primary Key:** `ProductID`
- **Attributes:** `ProductName`, `Category`, `Price`, `Stock`
### **Orders** 
- **Primary Key:** `OrderId`
- **Foreign Key:** `CustomerId` (References `Customers`)
- **Attributes:** `OrderDate`, `TotalAmount`
### **OrderDetails** 
- **Primary Key:** `OrderDetailId`
- **Foreign Keys:** `OrderId` (References `Orders`), `ProductID` (References `Products`)
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
- `assignment-1.sql` → Contains SQL queries for assignment-1.
- `assignment-2.sql` - Contains SQL queries for assignment-2.
- `erdiagram.png` → Entity-Relationship Diagram. 
- `README.md` → Explanation of database design.
- **This database ensures data integrity, eliminates redundancy, and optimizes performance!**