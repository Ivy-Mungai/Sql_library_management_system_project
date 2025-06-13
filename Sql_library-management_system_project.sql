CREATE DATABASE library_db;


DROP TABLE IF EXISTS branch;
CREATE TABLE branch(
             branch_id VARCHAR(10) PRIMARY KEY,
             manager_id VARCHAR(10),
             branch_address VARCHAR(55),
             contact_no VARCHAR(20)
             );

ALTER TABLE branch
MODIFY contact_no VARCHAR(20);

DROP TABLE IF EXISTS employee;
CREATE TABLE employee(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(25),
            position VARCHAR(15),
            salary INT,
            branch_id VARCHAR(10)
            );
            
 DROP TABLE IF EXISTS books;
 CREATE TABLE books(
              isbn VARCHAR(20) PRIMARY KEY,
              book_title VARCHAR(75),
              category VARCHAR(20),
              rental_price FLOAT,
              status VARCHAR(15),
              author VARCHAR(35),
              publisher VARCHAR(10)
              );
              
  ALTER TABLE books
  MODIFY category VARCHAR(20);
              
 DROP TABLE IF EXISTS members;
 CREATE TABLE members(
              member_id VARCHAR(10) PRIMARY KEY,
              member_name VARCHAR(25),
              member_address VARCHAR(75),
              reg_date DATE 
              );
              
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status(
             issued_id VARCHAR(10) PRIMARY KEY,
             issued_member_id VARCHAR(10),
             issued_book_name VARCHAR(75),
             issued_date DATE,
             issued_book_isbn VARCHAR(25),
             issued_emp_id VARCHAR(10)
             );
	
    
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status(
                 return_id VARCHAR(10) PRIMARY KEY,
                 issued_id VARCHAR(10),
                 return_book_name VARCHAR(75),
                 return_date DATE,
                 return_book_isbn VARCHAR(25)
                 );
              
              
--- FOREIGN KEY ;
  
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);
              
ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);
			
ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employee(emp_id);             

ALTER TABLE employee
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);              
              
ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

--- Confirming all the tables have been imported correctly;
   
SELECT *
FROM books;

SELECT *
FROM branch;

SELECT *
FROM employee;

SELECT *
FROM issued_status;

SELECT *
FROM members;

SELECT *
FROM return_status;

--- PROJECT TASKS;

--- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.') 
   
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT *
FROM books;   

--- Task 2: Update an Existing Member address ;

UPDATE members
SET member_address = '125 Main st'
WHERE member_id = 'C101' ;

 --- Task 3: Delete a Record from the Issued Status Table ;
 -- Objective: Delete the record with issued_id = 'IS1' from the issued_status tabLe ;
 
DELETE FROM issued_status
WHERE issued_id = 'IS121' ;
   
--- Task 4: Retrieve All Books Issued by a Specific Employee ;
-- Objective: Select all books issued by the employee with emp_id = 'E101'. ;   
   
SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101' ;

--- Task 5: List Members Who Have Issued More Than One Book ;
-- Objective: Use GROUP BY to find members who have issued more than one book. ;

SELECT
     issued_emp_id,
     COUNT(issued_id) AS total_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(issued_id) > 1;
   
--- CTAS (CREATE TABLE AS SELECT)   ;
   
--- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_count ;


CREATE TABLE book_cnts
AS
SELECT 
      b.isbn,
      b.book_title,
      COUNT(ist.issued_id) AS no_issued
FROM books as b
JOIN
issued_status as ist
ON ist.issued_book_isbn = b.isbn 
GROUP BY 1,2 ;
   
   
-- DATA ANALYSIS & FINDINGS ;

-- Task 7. Retrieve All Books in a classic Category ;
   
SELECT *
FROM books
WHERE category = 'classic' ;
   
--- Task 8: Find Total Rental Income by each Category;

SELECT 
     b.category,
     SUM(b.rental_price),
     COUNT(*)
FROM books as b
JOIN
issued_status as ist
ON ist.issued_book_isbn = b.isbn 
GROUP BY 1 ;

--- Task 9: Add the 2 recent records to the mebers table and the List Members Who Registered in the Last 180 days ;

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES 
     ('C122', 'Sam', '130 Main st', '2025-01-02'),
     ('C123', 'John', '170 Nanh st', '2025-04-04')
;

SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL 180 DAY ;

--- Task 10: List Employees with Their Branch Manager'S' Name and their branch details ;

SELECT 
     e1.*,
     b.manager_id,
     e2.emp_name as manager
FROM employee as e1
JOIN
branch as b
ON b.branch_id = e1.branch_id
JOIN 
employee as e2
ON b.manager_id = e2.emp_id ;

--- Task 11:  Create a Table of Books with Rental Price Above a Certain Threshold 7 usd ;

CREATE TABLE books_price_greater_than_seven
AS
SELECT *
FROM books
WHERE rental_price > 7;

--- Task 12: Retrieve the List of Books Not Yet Returned ;

SELECT 
     DISTINCT ist.issued_book_name
FROM issued_status as ist
LEFT JOIN
return_status as rst
ON ist.issued_id = rst.issued_id
WHERE return_id IS NULL ;


--- Task 13: Identify Members with Overdue Books ;
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue ;


SELECT 
     ist.issued_member_id,
     m.member_name,
     bk.book_title,
     ist.issued_date,
     rs.return_date,
     CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN  members as m
    ON m.member_id = ist.issued_member_id
JOIN books as bk
    ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status as rs
    ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND 
    (CURRENT_DATE - ist.issued_date) > 30 
ORDER BY 1 ;
  

-- Task 14: Update Book Status on Return using Sql store procedures;
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table) ;

DELIMITER //

CREATE PROCEDURE UpdateBookStatusOnReturn()
BEGIN
    -- Update the 'available' status to 'Yes' for books that are marked as returned
    UPDATE books
    SET available = 'Yes'
    WHERE book_id IN (
        SELECT book_id
        FROM return_status
        WHERE returned = 'Yes'
    );
END //

DELIMITER ;

CALL UpdateBookStatusOnReturn();



-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.;


CREATE TABLE branch_performance_report
AS
SELECT 
      b.branch_id,
      COUNT(ist.issued_id) as number_book_issued,
      COUNT(rs.return_id) as number_book_returned,
      SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN
employee as e
ON e.emp_id = ist.issued_emp_id
JOIN 
branch as b
ON b.branch_id = e.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN
books as bk
ON bk.isbn = ist.issued_book_isbn

GROUP BY 1 ;

--- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 12 months;

CREATE TABLE active_members
AS
SELECT *
FROM members
WHERE member_id IN ( SELECT
                     DISTINCT issued_member_id
                     FROM issued_status
                   WHERE issued_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
);


--- Task 17: Find Employees with the Most Book Issues Processed ;
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.;

SELECT 
      e.emp_name,
      b.*,
      COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employee as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON b.branch_id = e.branch_id
GROUP BY 1,2 
ORDER BY no_book_issued DESC ;


-- Task 18: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
-- Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days.
-- The table should include: The number of overdue books.
-- The total fines, with each days fine calculated at $0.50. The number of books issued by each member. 
-- The resulting table should show: Member ID Number of overdue booksTotal fines

SELECT 
     m.member_id,
     COUNT(rs.return_id IS NULL),
     (DATEDIFF(CURRENT_DATE,ist.issued_date)-30) as over_due_days,
     (DATEDIFF(CURRENT_DATE,ist.issued_date)-30) * 0.50 as fine
FROM members as m
JOIN 
issued_status as ist
ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL
AND 
(DATEDIFF(CURRENT_DATE,ist.issued_date)-30) > 0
GROUP BY 1,3,4 ;

--- END OF PROJECT.



    

    
    
    
    
    
    




























   
   
   
   
   
   
   
   
   
   
   
   
   
              