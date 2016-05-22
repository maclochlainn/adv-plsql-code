/*
 * HelloWorld4.sql
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

-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE TYPE hello_world4 AS OBJECT
EXTERNAL NAME 'HelloWorld4' LANGUAGE JAVA
USING SQLData
( instanceName VARCHAR2(100) EXTERNAL NAME 'java.lang.String'
, CONSTRUCTOR FUNCTION hello_world4
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
  
BEGIN

  -- Test class instance.
  dbms_output.put_line('Item #1: ['||my_obj1.getQualifiedName||']');
  dbms_output.put_line('Item #2: ['||my_obj2.getQualifiedName||']');
  dbms_output.put_line('Item #3: ['||my_obj1.getSQLTypeName||']');
  dbms_output.put_line('Item #4: ['||my_obj1.getSQLTypeName||']');
  
  -- Test metadata repository with DBMS_JAVA.
  dbms_output.put_line(
    'Item #5: ['||user||'.'||dbms_java.longname('HELLO_WORLD4')||']');

END;
/