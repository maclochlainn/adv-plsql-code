/*
 * create_library1.sql
 * Chapter 11, Oracle Database 12c PL/SQL Advanced Programming Technique
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script demonstrates how to create a library for
 * an external procedure. There are some caveats that
 * you should understand:
 *  - You can create the library without the shared
 *    library and no error will be raised. The
 *    database assumes you will put the file there
 *    before attempting to execute it.
 *  - You need to compile this as a shared library in
 *    UNIX, which has an *.so extension and as a
 *    Dynamic Link Library (*.DLL) on the Windows
 *    platforms.
 *  - On UNIX, there are two different ways to compile
 *    a shared library. They are noted below for 
 *    reference:
 *    - Solaris: gcc -G -o sample.so sample.c
 *    - GNU:     gcc -shared -o sample.so sample.c
 *  - It is assumed Microsoft's IDE is well designed
 *    and provides help messages to compile a DLL.
 */

SET ECHO ON
SET SERVEROUTPUT ON SIZE 1000000

ACCEPT filedir PROMPT "Enter the library directory: "

-- Define a session bind variable.
VARIABLE directory VARCHAR2(255)

-- An anonymous block program to ensure the primary key is not violated.
BEGIN
  -- Loop if a row is found and delete it.
  FOR i IN (SELECT   null
            FROM     user_libraries
            WHERE    library_name = 'library_write_string') LOOP

    EXECUTE IMMEDIATE 'DROP LIBRARY library_write_string';

  END LOOP;

END;
/

DECLARE

  -- Define variables to build command.
  cmd  VARCHAR2(255)  := 'CREATE OR REPLACE LIBRARY ';
  int  VARCHAR2(5)    := ' AS ''';
  dir  VARCHAR2(100)  := '/tmp'; -- Windows default 'C:\TEMP'
  ext  VARCHAR2(4)    := '.so''';
  file VARCHAR2(30)   := 'writestr1';
  lib  VARCHAR2(30)   := 'library_write_string';
  
BEGIN

  -- Check if an argument was passed.
  IF '&filedir' IS NOT NULL OR
      dir IS NOT NULL THEN

    -- Assign the argument as the directory.
    IF '&filedir' IS NOT NULL THEN
      IF INSTR('&filedir','$') = 0 THEN
        dir := '&filedir';
      ELSE
        dbms_output.put_line('Hey');
      END IF;
    END IF;

    -- Assign session bind variable.
    :directory := dir;

    -- Build the command.
    cmd := cmd || lib || int || dir || '/' || file || ext; 
  
    -- Print title and command.
    DBMS_OUTPUT.PUT_LINE('Command issued:');
    DBMS_OUTPUT.PUT_LINE('---------------');
    DBMS_OUTPUT.PUT_LINE(cmd);

    /*
    || Sample of what has been built for DNS execution.
    || ================================================
    || CREATE OR REPLACE LIBRARY library_write_string AS
    || '<oracle_home_directory>/<custom_library>/<file_name>.<file_ext>';
    || /
    */

    -- Execute the command.
    EXECUTE IMMEDIATE cmd;

  END IF;

END;
/

BEGIN

  -- Print title.
  DBMS_OUTPUT.PUT_LINE('Libraries found:');
  DBMS_OUTPUT.PUT_LINE(
    '----------------------------------------');

  -- Read all user libraries.
  FOR i IN (SELECT   library_name c1
            ,        file_spec c2
            ,        dynamic c3
            ,        status c4
            FROM     user_libraries) LOOP

    -- Print columns as rows.
    DBMS_OUTPUT.PUT_LINE('Library Name: ['||i.c1||']');
    DBMS_OUTPUT.PUT_LINE('File Spec   : ['||i.c2||']');
    DBMS_OUTPUT.PUT_LINE('Dynamic     : ['||i.c3||']');
    DBMS_OUTPUT.PUT_LINE('Status      : ['||i.c4||']');

    -- Print title and command.
    DBMS_OUTPUT.PUT_LINE(
      '----------------------------------------');

  END LOOP;

END;
/

CREATE OR REPLACE PROCEDURE write_string
  (path      VARCHAR2
  ,message   VARCHAR2) AS EXTERNAL
LIBRARY library_write_string
NAME "writestr1"
PARAMETERS
  (path      STRING
  ,message   STRING);
/

show errors

DECLARE

  -- Define a bad DLL path exception.
  bad_dll_path EXCEPTION;
  PRAGMA EXCEPTION_INIT(bad_dll_path,-28595);

  -- Define an missing file exception.
  missing_file EXCEPTION;
  PRAGMA EXCEPTION_INIT(missing_file,-6520);

BEGIN

  -- Call external library.
  write_string('/tmp/file.txt','Hello World!');

EXCEPTION

  -- Process bad DLL path.
  WHEN bad_dll_path THEN
    DBMS_OUTPUT.PUT_LINE('The DLL path is not found for '||:directory||'.');
    RETURN;

  -- Process file not found.
  WHEN missing_file THEN
    DBMS_OUTPUT.PUT_LINE('The library is not found in '||:directory||'.');
    RETURN;

END;
/
