--
--  Program Name: HelloWorld4.sql


-- Create a PL/SQL wrapper object type to a Java class file.
CREATE OR REPLACE TYPE hello_world4 AS OBJECT
( whom  VARCHAR2(100)
, MEMBER FUNCTION get_sql_type_name
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.getSQLTypeName()
        return java.lang.String'
, MEMBER FUNCTION to_string
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.toString()
        return java.lang.String' )
INSTANTIABLE FINAL;
/

SHOW ERRORS

SELECT   hello_world4('Bilbo').to_string AS "Output"
FROM     dual;

SELECT *
FROM   TABLE(
         SELECT CAST(COLLECT(hello_world4('Bilbo')) AS hello_tab)
         FROM   dual)
/


DECLARE
  /* Declare and instantiate an instance. */
  lv_hello  hello_world4 := hello_world4('Bilbo');
BEGIN
  /* Parse any string longer than 80 characters. */
  parse_rows(lv_hello.to_string());

  -- Test metadata repository with DBMS_JAVA.
  dbms_output.put_line(
    'Item #5: ['||user||'.'||dbms_java.longname('HELLO_WORLD4')||']');
END;
/

CREATE OR REPLACE TYPE hello_world4 AS OBJECT
( whom  VARCHAR2(100)
, CONSTRUCTOR FUNCTION hello_world4
  RETURN SELF AS RESULT
, CONSTRUCTOR FUNCTION hello_world4
  ( whom  VARCHAR2 )
  RETURN SELF AS RESULT
, MEMBER FUNCTION get_sql_type_name
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.getSQLTypeName()
        return java.lang.String'
, MEMBER FUNCTION to_string
  RETURN VARCHAR2 AS LANGUAGE JAVA
  NAME 'HelloWorld4.toString()
        return java.lang.String' )
INSTANTIABLE FINAL;
/

DECLARE
  /* Declare and instantiate an instance. */
  lv_hello  hello_world4 := hello_world4('Bilbo');
BEGIN
  /* Parse any string longer than 80 characters. */
  parse_rows(lv_hello.to_string());

  -- Test metadata repository with DBMS_JAVA.
  dbms_output.put_line(
    'Item #5: ['||user||'.'||dbms_java.longname('HELLO_WORLD4')||']');
END;
/
