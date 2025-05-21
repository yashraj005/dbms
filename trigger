3: write a trigger for Library (bid, bname, doi, status) to update the number of copies (noc) according to ISSUE & RETURN status on update or insert query. Increase the noc if status is RETURN, Decrease noc if status is ISSUE in Library_Audit table(bid,bname,noc,timestampofquery). Write a trigger after update on Library such that if doi is more than 20 days ago then status should be FINE and in the Library_Audit table fine should be equal to no. of days * 10.

-- Create Library table
DROP TABLE IF EXISTS Library;
CREATE TABLE Library (
  bid INT,
  bname VARCHAR(100),
  doi DATE,
  status VARCHAR(10)
);

-- Create Library_Audit table
DROP TABLE IF EXISTS Library_Audit;
CREATE TABLE Library_Audit (
  bid INT,
  bname VARCHAR(100),
  noc INT,
  fine INT DEFAULT 0,
  timestampofquery TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger AFTER INSERT
DELIMITER //

CREATE TRIGGER trg_library_after_insert
AFTER INSERT ON Library
FOR EACH ROW
BEGIN
  DECLARE new_noc INT DEFAULT 0;
  DECLARE days_diff INT DEFAULT 0;
  DECLARE calculated_fine INT DEFAULT 0;

  -- Get last noc from Library_Audit if exists
  SELECT noc INTO new_noc
  FROM Library_Audit
  WHERE bid = NEW.bid
  ORDER BY timestampofquery DESC
  LIMIT 1;

  -- Adjust noc
  IF NEW.status = 'ISSUE' THEN
    SET new_noc = new_noc - 1;
  ELSEIF NEW.status = 'RETURN' THEN
    SET new_noc = new_noc + 1;
  END IF;

  -- Check if doi is more than 20 days ago
  SET days_diff = DATEDIFF(CURDATE(), NEW.doi);

  IF days_diff > 20 THEN
    SET calculated_fine = days_diff * 10;
    INSERT INTO Library_Audit(bid, bname, noc, fine)
    VALUES (NEW.bid, NEW.bname, new_noc, calculated_fine);
  ELSE
    INSERT INTO Library_Audit(bid, bname, noc)
    VALUES (NEW.bid, NEW.bname, new_noc);
  END IF;
END;
//

DELIMITER ;

-- Trigger AFTER UPDATE
DELIMITER //

CREATE TRIGGER trg_library_after_update
AFTER UPDATE ON Library
FOR EACH ROW
BEGIN
  DECLARE new_noc INT DEFAULT 0;
  DECLARE days_diff INT DEFAULT 0;
  DECLARE calculated_fine INT DEFAULT 0;

  -- Get last noc from Library_Audit if exists
  SELECT noc INTO new_noc
  FROM Library_Audit
  WHERE bid = NEW.bid
  ORDER BY timestampofquery DESC
  LIMIT 1;

  -- Adjust noc
  IF NEW.status = 'ISSUE' THEN
    SET new_noc = new_noc - 1;
  ELSEIF NEW.status = 'RETURN' THEN
    SET new_noc = new_noc + 1;
  END IF;

  -- Check if doi is more than 20 days ago
  SET days_diff = DATEDIFF(CURDATE(), NEW.doi);

  IF days_diff > 20 THEN
    SET calculated_fine = days_diff * 10;
    INSERT INTO Library_Audit(bid, bname, noc, fine)
    VALUES (NEW.bid, NEW.bname, new_noc, calculated_fine);
  ELSE
    INSERT INTO Library_Audit(bid, bname, noc)
    VALUES (NEW.bid, NEW.bname, new_noc);
  END IF;
END;
//

DELIMITER ;

-- Sample INSERTs to test triggers
INSERT INTO Library (bid, bname, doi, status)
VALUES (1, 'DBMS Book', CURDATE(), 'RETURN');

INSERT INTO Library (bid, bname, doi, status)
VALUES (1, 'DBMS Book', CURDATE(), 'ISSUE');

INSERT INTO Library (bid, bname, doi, status)
VALUES (1, 'DBMS Book', DATE_SUB(CURDATE(), INTERVAL 35 DAY), 'RETURN');

-- Final Output

SELECT * FROM Library_Audit;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



4: Write a database trigger on Library table. The System should keep track of the records that are being updated or deleted. The old value of updated or deleted records should be added in Library_Audit table. 

-- Drop and recreate Library table
DROP TABLE IF EXISTS Library;
CREATE TABLE Library (
  bid INT,
  bname VARCHAR(100),
  doi DATE,
  status VARCHAR(10)
);

-- Drop and recreate Library_Audit table
DROP TABLE IF EXISTS Library_Audit;
CREATE TABLE Library_Audit (
  bid INT,
  bname VARCHAR(100),
  doi DATE,
  status VARCHAR(10),
  action_type VARCHAR(10),
  timestampofquery TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger AFTER UPDATE to log old values
DELIMITER //

CREATE TRIGGER trg_library_after_update_log
AFTER UPDATE ON Library
FOR EACH ROW
BEGIN
  INSERT INTO Library_Audit (bid, bname, doi, status, action_type)
  VALUES (OLD.bid, OLD.bname, OLD.doi, OLD.status, 'UPDATE');
END;
//

DELIMITER ;

-- Trigger AFTER DELETE to log deleted values
DELIMITER //

CREATE TRIGGER trg_library_after_delete_log
AFTER DELETE ON Library
FOR EACH ROW
BEGIN
  INSERT INTO Library_Audit (bid, bname, doi, status, action_type)
  VALUES (OLD.bid, OLD.bname, OLD.doi, OLD.status, 'DELETE');
END;
//

DELIMITER ;

-- Sample INSERT into Library
INSERT INTO Library (bid, bname, doi, status)
VALUES (101, 'C Programming', '2025-05-01', 'ISSUE');

-- Sample UPDATE
UPDATE Library
SET status = 'RETURN'
WHERE bid = 101;

-- Sample DELETE
DELETE FROM Library
WHERE bid = 101;

-- Final Output
SELECT * FROM Library_Audit;


