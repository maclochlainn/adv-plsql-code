/* Drop the table. */
DROP TABLE external_file;

/* Create the table. */
CREATE TABLE external_file
( file_id     NUMBER
, text_file   BFILE
, image_file  BFILE);

/* Drop sequence. */
DROP SEQUENCE external_file_s;

/* Create sequence. */
CREATE SEQUENCE external_file_s;

/* Insert values. */
INSERT INTO external_file
VALUES 
( external_file_s.NEXTVAL
, BFILENAME('LOADER','Hobbit1.txt')
, BFILENAME('LOADER','Hobbit1.png'));

/* Insert values. */
INSERT INTO external_file
VALUES 
( external_file_s.NEXTVAL
, BFILENAME('LOADER','Hobbit1_copy.txt')
, BFILENAME('LOADER','Hobbit1_copy.png'));

/* Create get_canonical_bfilename function. */
CREATE OR REPLACE FUNCTION get_canonical_bfilename
( pv_table_name     IN  VARCHAR2
, pv_bfile_column   IN  VARCHAR2
, pv_primary_key    IN  VARCHAR2
, pv_primary_value  IN  VARCHAR2
, pv_operating_sys  IN  VARCHAR2 := 'WINDOWS')
RETURN VARCHAR2 IS
 
  /* Declare default delimiter. */
  delimiter         VARCHAR2(1) := '\'; -- '''
 
  /* Define statement variable. */
  stmt              VARCHAR2(200);

  /* Declare a locator. */
  locator           BFILE;
 
  /* Define alias and file name. */
  dir_alias         VARCHAR2(255);
  directory         VARCHAR2(255);
  file_name         VARCHAR2(255);
 
  /* Define a local exception for size violation. */
  directory_num EXCEPTION;
  PRAGMA EXCEPTION_INIT(directory_num,-22285);
BEGIN
  /* Assign dynamic string to statement. */
  stmt := 'BEGIN'||CHR(10)
       || '  SELECT '||pv_bfile_column||CHR(10)
       || '  INTO   :column_name'||CHR(10)
       || '  FROM  '||pv_table_name||CHR(10)
       || '  WHERE '||pv_primary_key||'='||CHR(10)
       || ''''||pv_primary_value||''''||';'
       || 'END;';

  /* Run dynamic statement. */
  EXECUTE IMMEDIATE stmt USING OUT locator;

  /* Check available locator. */
  IF locator IS NOT NULL THEN
    DBMS_LOB.filegetname(locator,dir_alias,file_name);
  END IF;
 
  /* Check operating system and swap delimiter when necessary. */
  IF pv_operating_sys <> 'WINDOWS' THEN
    delimiter := '/';
  END IF;
 
  /* Create a fully qualified file name. */
  file_name := get_directory_path(dir_alias) || delimiter || file_name;
 
  /* Return file name. */
  RETURN file_name;
EXCEPTION
  WHEN directory_num THEN
    RETURN NULL;
END get_canonical_bfilename;
/

LIST
SHOW ERRORS

SET SERVEROUTPUT ON SIZE UNLIMITED

/* Query the value of a text file. */
DECLARE
  /* Declare a file path. */ 
  pv_file_path  VARCHAR2(100);
BEGIN
  /* Call the function of a BFILE column. */
  pv_file_path := get_canonical_bfilename
                    ( pv_table_name    => 'EXTERNAL_FILE'
                    , pv_bfile_column  => 'TEXT_FILE'
                    , pv_primary_key   => 'FILE_ID'
                    , pv_primary_value => 1);
  /* Print the fully qualified path. */
  dbms_output.put_Line(pv_file_path);
END;
/


/* Query the value of an image file. */
DECLARE
  /* Declare a file path. */ 
  pv_file_path  VARCHAR2(100);
BEGIN
  /* Call the function of a BFILE column. */
  pv_file_path := get_canonical_bfilename
                    ( pv_table_name    => 'EXTERNAL_FILE'
                    , pv_bfile_column  => 'IMAGE_FILE'
                    , pv_primary_key   => 'FILE_ID'
                    , pv_primary_value => 1);
  /* Print the fully qualified path. */
  dbms_output.put_Line(pv_file_path);
END;
/
