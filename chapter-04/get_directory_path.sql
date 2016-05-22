/*
 * get_directory_path.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a PL/SQL function that rolls back security over
 * virtual directory paths.
 */

CREATE OR REPLACE FUNCTION get_directory_path
( virtual_directory IN VARCHAR2 )
RETURN VARCHAR2 IS

  /* Define return variable. */
  directory_path VARCHAR2(256) := '';

  /* Define dynamic cursor. */
  CURSOR get_directory
  (virtual_directory VARCHAR2) IS
    SELECT   directory_path
    FROM     sys.dba_directories
    WHERE    directory_name = UPPER(virtual_directory);

   /* Define an exception for a name violation. */
   directory_name EXCEPTION;
   PRAGMA EXCEPTION_INIT(directory_name,-22284);
BEGIN
  OPEN  get_directory (virtual_directory);
  FETCH get_directory
  INTO  directory_path;
  CLOSE get_directory;
 
  /* RETURN file name. */
  RETURN directory_path;
EXCEPTION
  WHEN directory_name THEN
    RETURN null;
END get_directory_path;
/
