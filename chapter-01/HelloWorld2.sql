/*
 * HelloWorld2.sql
 * Chapter 1, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script test Java compilation.
 */

-- Unremark for debugging script.
SET ECHO ON
SET FEEDBACK ON
SET PAGESIZE 49999
SET SERVEROUTPUT ON SIZE 1000000

-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE PACKAGE hello_world2 AS
  -- Define a null argument function.
  FUNCTION hello
  RETURN VARCHAR2;
  
  -- Define a one argument function.
  FUNCTION hello
  ( who  VARCHAR2 )
  RETURN VARCHAR2;
END hello_world2;
/

-- Create a PL/SQL wrapper package to a Java class file.
CREATE OR REPLACE PACKAGE BODY hello_world2 AS
  -- Define a null argument function.
  FUNCTION hello
  RETURN VARCHAR2 IS
  LANGUAGE JAVA
  NAME 'HelloWorld2.hello() return String';
  
  -- Define a null argument function.
  FUNCTION hello
  ( who  VARCHAR2 )
  RETURN VARCHAR2 IS
  LANGUAGE JAVA
  NAME 'HelloWorld2.hello(java.lang.String) return String';
END hello_world2;
/

COL object_name   FORMAT A30
COL object_type   FORMAT A12
COL object_status FORMAT A7

SELECT   object_name
,        object_type
,        status
FROM     user_objects
WHERE    object_name IN ('HelloWorld2','HELLO_WORLD2')
ORDER BY CASE
           WHEN object_type = 'JAVA CLASS' THEN 1
           WHEN object_type = 'PACKAGE'    THEN 2
           ELSE 3
         END;

-- Test the Java class file through the PL/SQL wrapper.
SELECT   hello_world2.hello('Paul McCartney')
FROM     dual;