-- Lesson 04: Setup
-- Create a simple accounts table for the transfer demo

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250

 

 

-- Lesson 04: Class Exercises
-- Students: work through these in order. Don't skip the verify steps.

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:
SELECT * FROM accounts WHERE account_id IN (1, 3);

BEGIN
    UPDATE accounts
    SET balance = balance - 50
    WHERE account_id = 3;

    UPDATE accounts
    SET balance = balance + 50
    WHERE account_id = 1;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Transfer successful and committed.');
    EXCEPTION
        WHEN OTHERS THEN
            -- If anything goes wrong, undo everything
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Transfer failed. Changes rolled back.');
END;
 

-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:

SELECT * FROM accounts WHERE account_id IN (2, 3);
BEGIN 
    UPDATE accounts 
    SET balance = balance - 10000
    WHERE account_id = 2;
    
    UPDATE accounts 
    SET balance = balance + 10000
    WHERE account_id = 3;

    SELECT * FROM accounts WHERE account_id IN (2, 3);
    

    ROLLBACK
END;
 

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:
SELECT * FROM accounts WHERE account_id IN (1, 2, 3);

BEGIN
    UPDATE accounts
    SET balance = balance + 25
    WHERE account_id = 1;

    savepoint alice_balance

    UPDATE accounts
    SET balance= = balance -25
    WHERE account_id = 2;

    ROLLBACK
    
    UPDATE accounts
    SET balance= = balance -25
    WHERE account_id = 3;

    Commit

END




 
-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) AS
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Deposit amount must be greater than zero.');
    END IF;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deposit of $' || p_amount || ' to account ' || p_account_id || ' successful.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transaction failed. Rolling back...');
        RAISE;
END;

 

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?
    -- Inside: Reserving the slot and creating the record must be together so you don't have one without the other.
    -- Outside: Sending the notification happens last; otherwise, you might email a confirmation for a booking that fails and rolls back.

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?
    -- COMMIT forces the entire transaction to save, preventing the developer from rolling back their own earlier steps if a later step fails. 
    -- It strips the "caller" of their power to treat the whole process as one "all-or-nothing" unit.

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?
    -- calculate_copay(): Yes, functions return a value and can be used like a column in a query.
    -- post_payment(): No, procedures perform actions and are not allowed in SELECT statements because queries are for reading data, not changing it.
