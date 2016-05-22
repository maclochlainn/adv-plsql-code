/*
 * HelloWorld4e.sql
 * Chapter 15, Oracle Database 11g PL/SQL Programming
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script builds a PL/SQL wrapper to a Java class file.
 */

-- Unremark for debugging script.
SET ECHO ON
SET FEEDBACK ON
SET PAGESIZE 49999
SET SERVEROUTPUT ON SIZE 1000000

-- Drop any objects to make script re-runnable.
BEGIN

  FOR i IN (SELECT   table_name
            FROM     user_tables
            WHERE    table_name = 'JAVA_DEBUG' ) LOOP
            
    -- Use NDS to drop the dependent object type.
    EXECUTE IMMEDIATE 'DROP TABLE java_debug';
    
  END LOOP;
  
END;
/

-- Create table to support script.
CREATE TABLE java_debug
( debug_id    NUMBER
, debug_value VARCHAR2(2000));


-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE TYPE hello_world4 AS OBJECT
EXTERNAL NAME 'HelloWorld4' LANGUAGE JAVA
USING SQLData
( instanceName VARCHAR2(100) EXTERNAL NAME 'java.lang.String'
, CONSTRUCTOR FUNCTION hello_world4
  RETURN SELF AS RESULT
, CONSTRUCTOR FUNCTION hello_world4
  ( instanceName VARCHAR2 )
  RETURN SELF AS RESULT
, MEMBER FUNCTION getQualifiedName
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.getQualifiedName() return java.lang.String'
, MEMBER FUNCTION getSQLTypeName
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.getSQLTypeName() return java.lang.String' )
INSTANTIABLE FINAL;
/

-- Anonymous block program to test type.
DECLARE

  -- Define and instantiate an object instance.
  my_obj1 hello_world4 := hello_world4('Adam');
  my_obj2 hello_world4 := hello_world4('Eve');
  
  PROCEDURE write_debug
  ( number_in NUMBER
  , value_in  VARCHAR2 ) IS
  
  BEGIN
  
    INSERT INTO java_debug VALUES (number_in,value_in);
    
  END write_debug;
  
BEGIN

  -- Test class instance.
  dbms_output.put_line('Item #1: ['||my_obj1.getQualifiedName||']');
  write_debug(101,'Item #1 Completed');
  dbms_output.put_line('Item #2: ['||my_obj2.getQualifiedName||']');
  write_debug(102,'Item #2 Completed');
  dbms_output.put_line('Item #3: ['||my_obj1.getSQLTypeName||']');
  write_debug(103,'Item #3 Completed');
  dbms_output.put_line('Item #4: ['||my_obj1.getSQLTypeName||']');
  write_debug(104,'Item #4 Completed');
  
  -- Test metadata repository with DBMS_JAVA.
  dbms_output.put_line(
    'Item #5: ['||user||'.'||dbms_java.longname('HELLO_WORLD4')||']');

END;
/