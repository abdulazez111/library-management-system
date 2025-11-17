# Library Management System - SQL Database Project

## 📚 Project Overview
A complete library management database system built with MySQL. Handles books, authors, members, and borrowing operations.

## 🗂️ Database Structure
- **Books** - Book information and inventory
- **Authors** - Author details and biographies  
- **Members** - Library members and profiles
- **Borrowings** - Book lending operations
- **Book_Authors** - Many-to-many relationship

## 🛠️ Features
- Book catalog management
- Member registration system
- Borrowing and return operations
- Available books tracking
- Advanced search functionality

## 📊 ER Diagram
![ER Diagram](er_diagram.png)

## 🚀 Quick Start
```sql
-- Run database script
SOURCE library_database.sql;

-- Add new borrowing
CALL AddBorrowing(1, 1, 14);

-- Return book
CALL ReturnBook(1);

-- Search books
CALL SearchBooks('history');
```


## 👨‍💻 Author
- Abdulaziz - GitHub Profile

## 📄 License
- MIT License

