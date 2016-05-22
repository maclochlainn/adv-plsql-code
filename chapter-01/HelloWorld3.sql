/*
 * HelloWorld3.sql
 * Chapter 1, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script tests Java  and the JDBC library.
 */

-- Unremark for debugging script.
SET ECHO ON
SET FEEDBACK ON
SET PAGESIZE 49999
SET SERVEROUTPUT ON SIZE 1000000

-- Create a nested table of strings.
CREATE OR REPLACE TYPE varchar2_type AS TABLE OF NUMBER;
/

-- Drop any objects to make script re-runnable.
BEGIN
  FOR i IN (SELECT   table_name
            FROM     user_tables
            WHERE    table_name = 'EXAMPLE' ) LOOP
            
    -- Use NDS to drop the dependent object type.
    EXECUTE IMMEDIATE 'DROP TABLE example';  
  END LOOP;
END;
/

-- Create table to support script.
CREATE TABLE example
( character VARCHAR2(100));

-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE PACKAGE hello_world3 AS

  -- Define a single argument procedure.
  PROCEDURE doDML
  ( dml   VARCHAR2
  , input VARCHAR2 );
  
  -- Define a single argument function.
  FUNCTION doDQL
  ( dql   VARCHAR2 )
  RETURN  VARCHAR2;
  
END hello_world3;
/

-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE PACKAGE BODY hello_world3 AS

  -- Define a single argument procedure.
  PROCEDURE doDML
  ( dml   VARCHAR2
  , input VARCHAR2 ) IS
  LANGUAGE JAVA
  NAME 'HelloWorld3.doDML(java.lang.String,java.lang.String)';
  
  -- Define a single argument function.
  FUNCTION doDQL
  ( dql   VARCHAR2 )
  RETURN  VARCHAR2 IS
  LANGUAGE JAVA
  NAME 'HelloWorld3.doDQL(java.lang.String) return String';
  
END hello_world3;
/

COL object_name   FORMAT A30
COL object_type   FORMAT A12
COL object_status FORMAT A7

-- Query for objects.
SELECT   object_name
,        object_type
,        status
FROM     user_objects
WHERE    object_name IN ('HelloWorld3','HELLO_WORLD3');


BEGIN
  -- Insert records.
  hello_world3.doDML('INSERT INTO example VALUES (?)','Bobby McGee');
  -- Query records.
  DBMS_OUTPUT.PUT_LINE(hello_world3.doDQL('SELECT character FROM example'));
END;
/

-- Test the Java class file through the PL/SQL wrapper.
SELECT   hello_world3.doDQL('SELECT character FROM example')
FROM     dual;