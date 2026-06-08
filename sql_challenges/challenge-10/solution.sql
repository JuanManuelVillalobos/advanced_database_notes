SET DEFINE OFF;
SET LONG 100000;
SET PAGESIZE 0;

-- Lesson 05: Schema Backup & Restore
-- File 08: Class Exercises (self-contained)
-- ============================================
-- EXERCISE 1: Explore your schema
-- ============================================
-- List all the objects in your schema using user_objects
-- Group by object_type and count them
-- Which object types do you have?
-- Sample solution:
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- Also get details:
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

-- Additional verification query to identify invalid objects:
SELECT object_name, object_type, status 
FROM user_objects 
WHERE status = 'INVALID';

-- ============================================
-- EXERCISE 2: Basic GET_DDL
-- ============================================
-- First, set transform params for clean output:
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Get DDL for one of your tables
-- Dynamically selects the first table found in your schema instead of an input placeholder
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) 
FROM user_tables 
WHERE ROWNUM = 1;

-- Or get all tables at once:
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;

-- Identify the key parts in the output:
--   - Column definitions (NAME, TYPE, NULL/NOT NULL)
--   - Constraints (PRIMARY KEY, FK, CHECK)
--   - Storage parameters (if included)

-- ============================================
-- EXERCISE 3: Clean DDL for portability
-- ============================================
-- Remove schema names from DDL so it works in any schema
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Compare the output with and without EMIT_SCHEMA:
-- With EMIT_SCHEMA (default):   CREATE TABLE "SALES"."ORDERS" ...
-- Without EMIT_SCHEMA:          CREATE TABLE "ORDERS" ...
-- Try it yourself:
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

-- ============================================
-- EXERCISE 4: Plan a migration
-- ============================================
-- You're moving to a new schema with a different name.
-- What changes would you need to make to your exported DDL?
-- Scenario: Migrating from SCHEMA_OLD to SCHEMA_NEW

-- 1. First, identify schema names embedded in your DDL:
-- Dynamically selects the first table that actually contains a Foreign Key constraint
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE table_name = (
  SELECT MIN(table_name) 
  FROM user_constraints 
  WHERE constraint_type = 'R'
);

-- 2. Check for schema-qualified references:
-- Upgraded to look up referenced owner to spot cross-schema references:
SELECT a.constraint_name, a.table_name, b.owner AS referenced_schema, b.table_name AS referenced_table
FROM user_constraints a
JOIN all_constraints b ON a.r_constraint_name = b.constraint_name
WHERE a.constraint_type = 'R';

-- 3. If you find FK constraints pointing to other schemas, you need to:
--    - Update the REFERENCES clause to point to new schema name
--    - Or make sure target table exists in same schema

-- 4. Write a migration checklist:
--    [X] Export all DDL with EMIT_SCHEMA = false
--    [X] Review FK constraints for external schema references
--    [X] Separate table creation from foreign key activation scripts
--    [X] Reload in order: tables, sequences, indexes, constraints, views, PL/SQL code

-- ============================================
-- EXERCISE 5: Dependency order
-- ============================================
-- Look at user_dependencies to understand object relationships
-- See all dependencies in your schema:
SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

-- Find objects that depend on TABLES (to know what needs tables first):
SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY referencing_type, referencing_name;

-- Find direct dependencies for a specific object (replace PROC_NAME):
-- Dynamically returns dependencies for the first found programmable object (Procedure/Function/Package)
SELECT referenced_name, referenced_type
FROM user_dependencies
WHERE referencing_name = (
  SELECT MIN(object_name) 
  FROM user_objects 
  WHERE object_type IN ('PROCEDURE','FUNCTION','PACKAGE')
);

-- Build a dependency tree for PL/SQL objects:
SELECT referencing_name, referencing_type,
        LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;

-- ============================================
-- EXERCISE 6: Design your own backup strategy
-- ============================================
-- Given:
--   - No expdp access (no directory privileges)
--   - Need to move your schema to another database
--   - Only have SQL access
--
-- Design the steps you would take:

-- STEP 1: Document your current schema structure
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;

-- STEP 2: Extract all DDL (run all these)
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Extract sequences:
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) FROM user_sequences;

-- Extract tables (spool to file or copy output):
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) FROM user_tables;

-- Extract indexes (Excluding primary/unique keys which get generated implicitly with tables):
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) 
FROM user_indexes 
WHERE index_name NOT IN (SELECT constraint_name FROM user_constraints WHERE constraint_type IN ('P', 'U'));

-- Extract views:
SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) FROM user_views;

-- Extract constraints (If separate constraint scripts are preferred for FK handling):
SELECT DBMS_METADATA.GET_DDL('REF_CONSTRAINT', constraint_name) 
FROM user_constraints 
WHERE constraint_type = 'R';

-- Extract code:
SELECT DBMS_METADATA.GET_DDL(object_type, object_name) 
FROM user_objects 
WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'TRIGGER');

-- STEP 3: Reload in new schema (use proper order)
-- 1. Create tables (no foreign keys inline)
-- 2. Create sequences
-- 3. Create indexes
-- 4. Add constraints (enable FKs via ALTER statements)
-- 5. Create views
-- 6. Create package specifications, procedures, and functions
-- 7. Create package bodies and triggers

-- STEP 4: Verify everything transferred
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY table_name;
SELECT index_name, table_name FROM user_indexes ORDER BY index_name;

-- ============================================
-- DISCUSSION QUESTIONS
-- ============================================
-- Q1: What are the limitations of DBMS_METADATA vs expdp?
-- A:  DBMS_METADATA only exports DDL (no data), requires manual spool/cursor,
--     and can't handle very large schemas easily.
--     expdp is faster, can export data, handles large schemas, but needs directory access.
--     Choose DBMS_METADATA when you have no DBA access or need educational visibility.
--     Choose expdp when you have proper access and need speed/completeness.

-- Q2: If you have circular dependencies (A depends on B, B depends on A),
--     how would you handle the reload?
-- A:  Oracle handles most circular dependencies automatically if you create
--     objects first and enable constraints later.
--     For PL/SQL circular dependencies, create the package/spec first,
--     then the package/body second.
--     DBMS_METADATA returns objects in a valid order - trust the dependency analysis.

-- Q3: Your company is migrating from one Oracle database to another.
--     They give you read-only access to the old database and want you
--     to recreate the schema on the new database.
--     What's your plan?
-- A:  1. Document source schema structure (user_objects, user_tables, etc.)
--     2. Set EMIT_SCHEMA=false and extract clean DDL
--     3. Check for dependencies and schema-qualified references
--     4. Review and clean up the DDL (remove storage, fix schema names)
--     5. Create new schema user on target
--     6. Run DDL in proper order (tables, constraints, indexes, views, code)
--     7. Verify with object counts and sample queries
--     8. If possible, export sample data via INSERT statements or CSV