
6 Create tables CitiesIndia(pincode,nameofcity,earliername,area,population,avgrainfall) 
Categories(Type,pincode) Note:- Enter data only in CitiesIndia
Write PL/SQL Procedure & function to find the population density of the cities. If the population density is above 3000 then Type of city must be entered as High Density in Category table. Between 2999 to 1000 as Moderate and below 999 as Low Density. Error must be displayed for population less than 10 or greater than 25718.
--------------------------------------------------------------------------------------------------------------------

-- Step 1: Create tables
CREATE TABLE CitiesIndia (
pincode INT PRIMARY KEY,
nameofcity VARCHAR(50),
earliername VARCHAR(50),
area FLOAT,
population INT,
avgrainfall FLOAT
);
CREATE TABLE Categories (
Type VARCHAR(20),
pincode INT,
FOREIGN KEY (pincode) REFERENCES CitiesIndia(pincode)
);
-- Step 2: Insert sample data into CitiesIndia
INSERT INTO CitiesIndia VALUES
(110001, 'Delhi', 'Dilli', 1484, 25000, 800),
(400001, 'Mumbai', 'Bombay', 603.4, 18000, 2200),
(560001, 'Bangalore', 'Bengaluru', 741, 800, 950),
(700001, 'Kolkata', 'Calcutta', 206, 5, 1200); -- This will be skipped
-- Step 3: Create stored procedure to calculate and categorize
DELIMITER //
CREATE PROCEDURE InsertCategory()
BEGIN
DECLARE done INT DEFAULT 0;
DECLARE v_pincode INT;
DECLARE v_population INT;
DECLARE v_area FLOAT;
DECLARE v_density FLOAT;
DECLARE city_cursor CURSOR FOR
SELECT pincode, population, area FROM CitiesIndia;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
OPEN city_cursor;
read_loop: LOOP
FETCH city_cursor INTO v_pincode, v_population, v_area;
IF done THEN
LEAVE read_loop;
END IF;
-- Skip cities with population < 10 or > 25718
IF v_population < 10 OR v_population > 25718 THEN
ITERATE read_loop;
END IF;
SET v_density = v_population / v_area;
IF v_density > 3000 THEN
INSERT INTO Categories VALUES ('High Density', v_pincode);
ELSEIF v_density BETWEEN 1000 AND 2999 THEN
INSERT INTO Categories VALUES ('Moderate', v_pincode);
ELSE
INSERT INTO Categories VALUES ('Low Density', v_pincode);
END IF;
END LOOP;
CLOSE city_cursor;
END //
DELIMITER ;
-- Step 4: Call the procedure
CALL InsertCategory();
-- Step 5: View the result
SELECT * FROM Categories;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

7 Write PL/SQL Procedure & function to find class [Distinction (Total marks from 1499 to 990) ,First Class( 899 to 900) Higher Second (899 to 825) ,Second,Pass (824 to 750) ] of a student based on total marks from table Student (rollno, name, Marks1, Marks2, Marks3, Marks4, Marks5). 
Use exception handling when negative marks are entered by user(Marks<0) or Marks more than 100 are entered by user.. Store the result into Result table recording  RollNo,total marks, and class for each student .
DELIMITER //
---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS StudentDB;
USE StudentDB;

-- 1. Create Student table
DROP TABLE IF EXISTS Student;
CREATE TABLE Student (
    rollno INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    Marks1 INT,
    Marks2 INT,
    Marks3 INT,
    Marks4 INT,
    Marks5 INT
);

-- 2. Create Result table
DROP TABLE IF EXISTS Result;
CREATE TABLE Result (
    rollno INT PRIMARY KEY,
    total_marks INT,
    class VARCHAR(20),
    FOREIGN KEY (rollno) REFERENCES Student(rollno)
);

-- 3. Insert sample data
INSERT INTO Student VALUES
(1, 'Rahul Sharma', 95, 98, 92, 88, 94),
(2, 'Neha Gupta', 78, 85, 80, 75, 82),
(3, 'Amit Singh', 65, 70, 60, 55, 68),
(4, 'Pooja Patel', 102, 90, 85, 88, 91), -- invalid marks (102)
(5, 'Karan Verma', -5, 88, 90, 84, 87); -- invalid marks (-5)

-- 4. Function to calculate total marks with validation
DELIMITER //
CREATE FUNCTION calculate_total(roll INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    DECLARE m1, m2, m3, m4, m5 INT;

    SELECT Marks1, Marks2, Marks3, Marks4, Marks5 
    INTO m1, m2, m3, m4, m5 
    FROM Student WHERE rollno = roll;

    IF m1 < 0 OR m1 > 100 OR m2 < 0 OR m2 > 100 OR m3 < 0 OR m3 > 100 
       OR m4 < 0 OR m4 > 100 OR m5 < 0 OR m5 > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid marks found (negative or greater than 100)';
    END IF;

    SET total = m1 + m2 + m3 + m4 + m5;
    RETURN total;
END //
DELIMITER ;

-- 5. Procedure to calculate and insert class
DELIMITER //
CREATE PROCEDURE Calculate_Class()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE c_roll INT;
    DECLARE total_marks INT;
    DECLARE class_result VARCHAR(20);

    DECLARE cur CURSOR FOR SELECT rollno FROM Student;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET total_marks = -1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO c_roll;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET total_marks = NULL;

        -- Try to calculate total (will set total_marks = -1 if invalid)
        SET total_marks = calculate_total(c_roll);

        IF total_marks = -1 THEN
            ITERATE read_loop;
        END IF;

        -- Assign class based on total
        IF total_marks BETWEEN 450 AND 500 THEN
            SET class_result = 'Distinction';
        ELSEIF total_marks BETWEEN 400 AND 449 THEN
            SET class_result = 'First Class';
        ELSEIF total_marks BETWEEN 375 AND 399 THEN
            SET class_result = 'Higher Second';
        ELSEIF total_marks BETWEEN 330 AND 374 THEN
            SET class_result = 'Second';
        ELSE
            SET class_result = 'Pass';
        END IF;

        -- Insert or update result
        INSERT INTO Result (rollno, total_marks, class)
        VALUES (c_roll, total_marks, class_result)
        ON DUPLICATE KEY UPDATE total_marks = VALUES(total_marks), class = VALUES(class);
    END LOOP;

    CLOSE cur;
END //
DELIMITER ;

-- 6. Call procedure
CALL Calculate_Class();

-- 7. View results
SELECT * FROM Result;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

29  Writ a PL/SQL procedure to find the number of students ranging from 100-70%, 69-60%, 59-50% & below 49% in each course from the student_course table given by the procedure as parameter.
Schema: Student (ROLL_NO ,COURSE, COURSE_COD ,SEM ,TOTAL_MARKS, PERCENTAGE)
------------------------------------------------------------------------------

-- 1. Create database and use it
CREATE DATABASE IF NOT EXISTS StudentDB;
USE StudentDB;

-- 2. Drop table if it exists
DROP TABLE IF EXISTS student_course;

-- 3. Create student_course table
CREATE TABLE student_course (
    roll_no INT PRIMARY KEY,
    course VARCHAR(100),
    course_cod VARCHAR(20),
    sem INT,
    total_marks INT,
    percentage DECIMAL(5,2)
);

-- 4. Insert sample data
INSERT INTO student_course VALUES
(1, 'Math', 'MTH101', 1, 450, 75.00),
(2, 'Math', 'MTH101', 1, 420, 70.00),
(3, 'Math', 'MTH101', 1, 390, 65.00),
(4, 'Physics', 'PHY101', 1, 350, 55.00),
(5, 'Physics', 'PHY101', 1, 300, 48.00),
(6, 'Chemistry', 'CHM101', 1, 280, 62.00),
(7, 'Chemistry', 'CHM101', 1, 200, 40.00);

-- 5. Create stored procedure to count students in percentage ranges by course code
DELIMITER //

CREATE PROCEDURE Count_Students_By_Percentage(IN p_course_cod VARCHAR(20))
BEGIN
    DECLARE v_100_70 INT DEFAULT 0;
    DECLARE v_69_60 INT DEFAULT 0;
    DECLARE v_59_50 INT DEFAULT 0;
    DECLARE v_below_49 INT DEFAULT 0;

    -- Calculate each range
    SELECT COUNT(*) INTO v_100_70
    FROM student_course
    WHERE course_cod = p_course_cod AND percentage BETWEEN 70 AND 100;

    SELECT COUNT(*) INTO v_69_60
    FROM student_course
    WHERE course_cod = p_course_cod AND percentage BETWEEN 60 AND 69.99;

    SELECT COUNT(*) INTO v_59_50
    FROM student_course
    WHERE course_cod = p_course_cod AND percentage BETWEEN 50 AND 59.99;

    SELECT COUNT(*) INTO v_below_49
    FROM student_course
    WHERE course_cod = p_course_cod AND percentage < 50;

    -- Output results
    SELECT 
        p_course_cod AS Course_Code,
        v_100_70 AS '70-100%',
        v_69_60 AS '60-69%',
        v_59_50 AS '50-59%',
        v_below_49 AS 'Below 50%';
END //

DELIMITER ;

-- 6. Call the procedure with a course code
CALL Count_Students_By_Percentage('MTH101');


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
30  Write a Stored Procedure namely proc_Grade for the categorization of student. If marks scored by students in examination is <=1500 and marks>=990 then student will be placed in distinction category if marks scored are between 989 and900 category is first class, if marks 899 and 825 category is Higher Second Class .

Consider Schema as Stud_Marks(name, total_marks) and Result(Roll,Name, Class) 
-------------------------------------------------------------------------------

-- 1. Create and select database
CREATE DATABASE IF NOT EXISTS StudentDB;
USE StudentDB;

-- 2. Drop existing tables if they exist
DROP TABLE IF EXISTS Result;
DROP TABLE IF EXISTS Stud_Marks;

-- 3. Create Stud_Marks table
CREATE TABLE Stud_Marks (
    name VARCHAR(100),
    total_marks INT
);

-- 4. Create Result table
CREATE TABLE Result (
    roll INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    class VARCHAR(30)
);

-- 5. Insert sample data into Stud_Marks
INSERT INTO Stud_Marks VALUES
('Rahul Sharma', 1450),
('Neha Gupta', 980),
('Amit Singh', 860),
('Pooja Patel', 905),
('Karan Verma', 810),
('Nikita Mehta', 1510), -- Above 1500, should be ignored
('Suresh Rana', 700);   -- Below 825, should be ignored

-- 6. Create stored procedure to classify students and insert into Result
DELIMITER //

CREATE PROCEDURE proc_Grade()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE s_name VARCHAR(100);
    DECLARE s_total INT;
    DECLARE s_class VARCHAR(30);

    -- Cursor for looping over Stud_Marks
    DECLARE cur CURSOR FOR SELECT name, total_marks FROM Stud_Marks;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO s_name, s_total;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Initialize class
        SET s_class = NULL;

        -- Assign class based on marks
        IF s_total BETWEEN 990 AND 1500 THEN
            SET s_class = 'Distinction';
        ELSEIF s_total BETWEEN 900 AND 989 THEN
            SET s_class = 'First Class';
        ELSEIF s_total BETWEEN 825 AND 899 THEN
            SET s_class = 'Higher Second Class';
        ELSE
            ITERATE read_loop; -- Skip if below 825 or above 1500
        END IF;

        -- Insert into Result
        INSERT INTO Result (name, class) VALUES (s_name, s_class);
    END LOOP;

    CLOSE cur;
END //

DELIMITER ;

-- 7. Call the procedure to populate Result table
CALL proc_Grade();

-- 8. View result
SELECT * FROM Result;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
9.PL/SQL code block: Use of Control structure and Exception handling is mandatory. Write a PL/SQL block of code for the following requirements:- 
Schema: 
1. Borrower(Rollin, Name, DateofIssue, NameofBook, Status) 
2. Fine(Roll_no,Date,Amt) 
3. Library (bid, bname, doi, status,noc)
4. transaction (tid,bid, bname, status)
Accept roll_no & name of book from user. 
Check the number of days (from date of issue), if days are between 15 to 30 then fine amount will be Rs 5per day. 
If no. of days>30, per day fine will be Rs 50 per day & for days less than 30, Rs. 5 per day. 
After submitting the book, status will change from I to R.
Update the noc in library according to the transaction made.  Increase the noc if status is RETURN, Decrease noc if status is ISSUE.
If condition of fine is true, then details will be stored into fine table. 

---------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE ReturnBook (
    IN in_rollno VARCHAR(10),         -- Step 1: Input parameters for roll no & book name
    IN in_bookname VARCHAR(100)
)
BEGIN
    -- Step 2: Declare variables
    DECLARE v_doi DATE;
    DECLARE v_days INT;
    DECLARE v_fine_amt INT DEFAULT 0;
    DECLARE v_status CHAR(1);
    DECLARE v_bid INT;
    DECLARE v_noc INT;
    DECLARE v_tid CHAR(36); -- UUID for transaction

    -- Step 3: Exception handler for errors
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'An error occurred while processing the return.' AS ErrorMessage;
    END;

    -- Step 4: Start transaction
    START TRANSACTION;

    -- Step 5: Fetch Date of Issue and Status
    SELECT DateofIssue, Status
    INTO v_doi, v_status
    FROM Borrower
    WHERE Rollin = in_rollno AND NameofBook = in_bookname
    LIMIT 1;

    -- Step 6: Check if already returned
    IF v_status = 'R' THEN
        SELECT 'Book already returned.' AS Message;
        ROLLBACK;
        -- LEAVE proc; -- Removed because no label defined
    ELSE
        -- Step 7: Calculate number of days
        SET v_days = DATEDIFF(CURDATE(), v_doi);

        -- Step 8: Calculate fine
        IF v_days > 30 THEN
            SET v_fine_amt = (15 * 5) + ((v_days - 30) * 50);
        ELSEIF v_days > 15 THEN
            SET v_fine_amt = (v_days - 15) * 5;
        END IF;

        -- Step 9: Update Borrower status
        UPDATE Borrower
        SET Status = 'R'
        WHERE Rollin = in_rollno AND NameofBook = in_bookname;

        -- Step 10: Get book id and number of copies
        SELECT bid, noc INTO v_bid, v_noc
        FROM Library
        WHERE bname = in_bookname
        LIMIT 1;

        -- Step 11: Insert transaction record
        SET v_tid = UUID();
        INSERT INTO transaction (tid, bid, bname, status)
        VALUES (v_tid, v_bid, in_bookname, 'R');

        -- Step 12: Update noc (increase since RETURN)
        UPDATE Library
        SET noc = v_noc + 1
        WHERE bid = v_bid;

        -- Step 13: Insert fine if applicable
        IF v_fine_amt > 0 THEN
            INSERT INTO Fine (Roll_no, Date, Amt)
            VALUES (in_rollno, CURDATE(), v_fine_amt);
        END IF;

        -- Step 14: Commit transaction
        COMMIT;

        -- Step 15: Output messages to user
        SELECT 'Book returned successfully.' AS Message;
        IF v_fine_amt > 0 THEN
            SELECT CONCAT('Fine of Rs. ', v_fine_amt) AS FineMessage;
        ELSE
            SELECT 'No fine applicable.' AS FineMessage;
        END IF;
    END IF;

END$$

DELIMITER ;

CALL ReturnBook('S101', 'Database Systems');

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


26  Write a PL/SQL code to calculate tax for an employee of an organization ABC and to display his/her name & tax, by creating a table under employee database as below:
Employee_salary(emp_no,basic,HRA,DA,Total_deduction,net_salary,gross_Salary)

--------------------------------------------------------

-- Drop tables if they exist (for clean slate)
DROP TABLE IF EXISTS Employee_salary;
DROP TABLE IF EXISTS Employee;

-- Create Employee table
CREATE TABLE Employee (
    emp_no VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL
);

-- Create Employee_salary table
CREATE TABLE Employee_salary (
    emp_no VARCHAR(10) PRIMARY KEY,
    basic DECIMAL(10,2),
    HRA DECIMAL(10,2),
    DA DECIMAL(10,2),
    Total_deduction DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    gross_salary DECIMAL(10,2),
    FOREIGN KEY (emp_no) REFERENCES Employee(emp_no)
);

-- Insert sample employees
INSERT INTO Employee (emp_no, emp_name) VALUES
('E101', 'John Doe'),
('E102', 'Jane Smith');

-- Insert sample salaries
INSERT INTO Employee_salary (emp_no, basic, HRA, DA, Total_deduction, net_salary, gross_salary) VALUES
('E101', 200000, 50000, 30000, 20000, 260000, 280000),
('E102', 400000, 100000, 60000, 40000, 520000, 560000);

-- Create stored procedure to calculate tax
DELIMITER $$

CREATE PROCEDURE CalculateTax (
    IN in_emp_no VARCHAR(10)
)
BEGIN
    DECLARE v_emp_name VARCHAR(100);
    DECLARE v_gross_salary DECIMAL(10,2);
    DECLARE v_tax DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Error occurred while calculating tax.' AS Message;
    END;

    SELECT e.emp_name, s.gross_salary
    INTO v_emp_name, v_gross_salary
    FROM Employee e
    JOIN Employee_salary s ON e.emp_no = s.emp_no
    WHERE e.emp_no = in_emp_no;

    IF v_gross_salary <= 250000 THEN
        SET v_tax = 0;
    ELSEIF v_gross_salary <= 500000 THEN
        SET v_tax = v_gross_salary * 0.05;
    ELSEIF v_gross_salary <= 1000000 THEN
        SET v_tax = v_gross_salary * 0.20;
    ELSE
        SET v_tax = v_gross_salary * 0.30;
    END IF;

    SELECT v_emp_name AS Employee_Name, v_tax AS Tax_Amount;
END$$

DELIMITER ;

-- Call the procedure for an employee
CALL CalculateTax('E101');

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


28  Write a PL/SQL block of code using parameterized Cursor, that will merge the data available in the newly created table N_RollCall with the data available in the table O_RollCall. If the data in the first table already exist in the second table then that data should be skipped. 

-----------------------------------------

CREATE TABLE O_RollCall (
roll_no INT PRIMARY KEY,
name VARCHAR(50)
);
CREATE TABLE N_RollCall (
roll_no INT PRIMARY KEY,
name VARCHAR(50)
);
-- Old table has roll 1 and 2
INSERT INTO O_RollCall VALUES (1, 'Alice'), (2, 'Bob');
-- New table has roll 2 (duplicate), 3 and 4 (new)
INSERT INTO N_RollCall VALUES (2, 'Bob'), (3, 'Charlie'), (4, 'David');
DELIMITER $$
CREATE PROCEDURE MergeRollCall()
BEGIN
DECLARE done INT DEFAULT 0;
DECLARE v_roll INT;
DECLARE v_name VARCHAR(50);
DECLARE cur CURSOR FOR
SELECT roll_no, name FROM N_RollCall;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
OPEN cur;
read_loop: LOOP
FETCH cur INTO v_roll, v_name;
IF done THEN
LEAVE read_loop;
END IF;
-- Insert if roll_no does not exist in O_RollCall
IF NOT EXISTS (SELECT 1 FROM O_RollCall WHERE roll_no = v_roll) THEN
INSERT INTO O_RollCall (roll_no, name) VALUES (v_roll, v_name);
END IF;
END LOOP;
CLOSE cur;
END$$
DELIMITER ;
CALL MergeRollCall();
SELECT * FROM O_RollCall;

