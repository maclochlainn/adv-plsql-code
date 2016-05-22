/*
 * CreateExportFramework.sql
 * Chapter 5, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script test Java compilation.
 */

BEGIN
  FOR i IN (SELECT   ut.table_name
            FROM     user_tables ut
            WHERE    ut.table_name = UPPER('item_import')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name;
  END LOOP;
END;
/

SET ECHO ON

CREATE TABLE item_import
( asin_number         VARCHAR2(10)
, item_type           VARCHAR2(15)
, item_title          VARCHAR2(60)
, item_subtitle       VARCHAR2(60)
, item_rating         VARCHAR2(8)
, item_rating_agency  VARCHAR2(4)
, item_release_date   DATE)
  ORGANIZATION EXTERNAL
  ( TYPE oracle_loader
    DEFAULT DIRECTORY UPLOAD
    ACCESS PARAMETERS
    ( RECORDS DELIMITED BY NEWLINE CHARACTERSET US7ASCII
      BADFILE     'LOG':'item_import.bad'
      DISCARDFILE 'LOG':'item_import.dis'
      LOGFILE     'LOG':'item_import.log'
      FIELDS TERMINATED BY ','
      OPTIONALLY ENCLOSED BY "'"
      MISSING FIELD VALUES ARE NULL )
  LOCATION ('item_import.csv'))
PARALLEL
REJECT LIMIT UNLIMITED;

DESCRIBE item_import

-- Set the pagesize.
SET PAGESIZE 99

-- Formats columns. 
COLUMN asin_number        FORMAT A11 HEADING "ASIN #"
COLUMN item_title         FORMAT A46 HEADING "ITEM TITLE"
COLUMN item_rating        FORMAT A6  HEADING "RATING"
COLUMN item_release_date  FORMAT A11 HEADING "RELEASE|DATE"

-- Query results from external table. 
SELECT   asin_number
,        item_title
,        item_rating
,        TO_CHAR(item_release_date,'DD-MON-YYYY') AS item_release_date
FROM     item_import;

-- Query the directory data path.
SELECT   get_directory_path('upload')
FROM     dual;

-- Query the directory log path.
SELECT   get_directory_path('log')
FROM     dual;

-- Create a scalar array.
CREATE OR REPLACE
  TYPE file_list AS TABLE OF VARCHAR2(255);
/

-- Create a Java source file to read external directories.
-- Source: Chapter 3
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ListVirtualDirectory" AS
 
  // Import required classes.
  import java.io.*;
  import java.security.AccessControlException;
  import java.sql.*;
  import java.util.Arrays;
  import oracle.sql.driver.*;
  import oracle.sql.ArrayDescriptor;
  import oracle.sql.ARRAY;
 
  // Define the class.
  public class ListVirtualDirectory {

    // Define the method.
    public static ARRAY getList(String path) throws SQLException {

    // Declare variable as a null, required because of try-catch block.
    ARRAY listed = null;

    // Define a connection (this is for Oracle 11g).
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // Use a try-catch block to trap a Java permission error on the directory.
    try {
      // Declare a class with the file list.
      File directory = new File(path);

      // Declare a mapping to the schema-level SQL collection type.
      ArrayDescriptor arrayDescriptor = new ArrayDescriptor("FILE_LIST",conn);

      // Translate the Java String[] to the Oracle SQL collection type.
      listed = new ARRAY(arrayDescriptor,conn,((Object[]) directory.list())); }
    catch (AccessControlException e) {
      throw new AccessControlException("Directory permissions restricted."); }
  return listed; }}
/

SHOW ERRORS

-- Create a wrapper to the Java library.
-- Source: Chapter 3
CREATE OR REPLACE FUNCTION list_files(path VARCHAR2) RETURN FILE_LIST IS
LANGUAGE JAVA
NAME 'ListVirtualDirectory.getList(java.lang.String) return oracle.sql.ARRAY';
/

-- Query upload directory file names.
-- --------------------------------------------------------------
--   Privileges must be granted before connecting to the session
--   or you'll encounter an invalid privileges error.
-- --------------------------------------------------------------
SELECT   column_value AS "File Names"
FROM     TABLE(list_files(get_directory_path('UPLOAD')));

-- Query log directory file names.
-- --------------------------------------------------------------
--   Privileges must be granted before connecting to the session
--   or you'll encounter an invalid privileges error.
-- --------------------------------------------------------------
SELECT   column_value AS "File Names"
FROM     TABLE(list_files(get_directory_path('LOG')))

-- Query tables mapped against files.
COLUMN table_name FORMAT A30
COLUMN file_name  FORMAT A30
SELECT   xt.table_name
,        xt.file_name
FROM    (SELECT   uxt.table_name
         ,        ixt.column_value AS file_name
         FROM     user_external_tables uxt CROSS JOIN
         TABLE(
           list_files(
             get_directory_path(
               uxt.default_directory_name))) ixt) xt
JOIN     user_external_locations xl
ON       xt.table_name = xl.table_name
AND      xt.file_name = xl.location;

-- Create external_file_found function.
CREATE OR REPLACE FUNCTION external_file_found
( table_in VARCHAR2 ) RETURN NUMBER IS
  -- Define a default return value.
  retval NUMBER := 0;
 
  -- Decalre a cursor to find external tables.
  CURSOR c (cv_table VARCHAR2) IS
    SELECT   xt.table_name
    ,        xt.file_name
    FROM    (SELECT   uxt.table_name
             ,        ixt.column_value AS file_name
             FROM     user_external_tables uxt CROSS JOIN
             TABLE(
               list_files(
                 get_directory_path(
                   uxt.default_directory_name))) ixt) xt
    JOIN     user_external_locations xl
    ON       xt.table_name = xl.table_name
    AND      xt.file_name = xl.location
    AND      xt.table_name = UPPER(cv_table);
BEGIN
  FOR i IN c(table_in) LOOP
    retval := 1;
  END LOOP;
  RETURN retval;
END;
/

-- Create an item_import view.
CREATE OR REPLACE VIEW item_import_v AS
SELECT   *
FROM     item_import
WHERE    external_file_found('ITEM_IMPORT') = 1;

COLUMN asin_number        FORMAT A11 HEADING "ASIN #"
COLUMN item_title         FORMAT A46 HEADING "ITEM TITLE"
COLUMN item_rating        FORMAT A6  HEADING "RATING"
COLUMN item_release_date  FORMAT A11 HEADING "RELEASE|DATE"

SELECT   asin_number
,        item_title
,        item_rating
,        TO_CHAR(item_release_date,'DD-MON-YYYY') AS item_release_date
FROM item_import_v;

-- Conditionally drop types.
BEGIN
  FOR i IN (SELECT   uo.object_type
            ,        uo.object_name
            FROM     user_objects uo
            WHERE    uo.object_name IN ('ITEM_IMPORT_OBJECT'
                                       ,'ITEM_IMPORT_OBJECT_TABLE')
            AND      uo.object_type = 'TYPE'
            OR       uo.object_name = 'EXTERNAL_FILE_CONTENTS'
            AND       uo.object_type = 'FUNCTION'
            ORDER BY uo.object_type, uo.object_name DESC) LOOP
    EXECUTE IMMEDIATE 'DROP '||i.object_type||' '||i.object_name;
  END LOOP;
END;
/

-- Create or replace an item_import object.
CREATE OR REPLACE
  TYPE item_import_object IS OBJECT
  ( asin_number         VARCHAR2(10)
  , item_type           VARCHAR2(15)
  , item_title          VARCHAR2(60)
  , item_subtitle       VARCHAR2(60)
  , item_rating         VARCHAR2(8)
  , item_rating_agency  VARCHAR2(4)
  , item_release_date   DATE);
/

-- Create a collection of item_import objects.
CREATE OR REPLACE TYPE item_import_object_table IS
  TABLE OF item_import_object;
/

-- Create an external file contents function.
CREATE OR REPLACE FUNCTION external_file_contents
  RETURN item_import_object_table IS
 
  -- Define a local counter.
  lv_counter NUMBER := 1;
 
  -- Construct an empty collection.
  lv_item_import_table ITEM_IMPORT_OBJECT_TABLE :=
    item_import_object_table();
 
  -- Decalre a cursor to find external tables.
  CURSOR c IS
    SELECT   *
    FROM     item_import
    WHERE    external_file_found('ITEM_IMPORT') = 1;
 
BEGIN
  FOR i IN c LOOP
    lv_item_import_table.EXTEND;
    lv_item_import_table(lv_counter) :=
      item_import_object(i.asin_number
                        ,i.item_type
                        ,i.item_title
                        ,i.item_subtitle
                        ,i.item_rating
                        ,i.item_rating_agency
                        ,i.item_release_date);
    lv_counter := lv_counter + 1;
  END LOOP;
 
  /*
   *  This is where you can place autonomous function calls:
   *  ======================================================
   *   - These can read source and log files, and write them
   *     to CLOB attributes for later inspection or review.
   *   - These can call Java libraries to delete files, but
   *     you should note that Java deletes any file rather
   *     than moving it to the trash bin (where you might
   *     recover it.
   */
 
  RETURN lv_item_import_table;
END;
/

SHOW ERRORS

/*
 *  SQL*Plus formatting.
 */
SET PAGESIZE 99
 
COLUMN asin_number        FORMAT A11 HEADING "ASIN #"
COLUMN item_title         FORMAT A46 HEADING "ITEM TITLE"
COLUMN item_rating        FORMAT A6  HEADING "RATING"
COLUMN item_release_date  FORMAT A11 HEADING "RELEASE|DATE"
 
/*
 *  Query works only when item_import.csv file is present.
 */
SELECT   asin_number
,        item_title
,        item_rating
,        TO_CHAR(item_release_date,'DD-MON-YYYY') AS item_release_date
FROM     TABLE(external_file_contents);

-- Create an view of item_import.
CREATE OR REPLACE VIEW item_import_v AS
SELECT   *
FROM     TABLE(external_file_contents);

-- Disable substitution variables, which conflict with the
-- ampersands used by Java.
SET DEFINE OFF 

-- Create a Java library that deletes a library.
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "DeleteFile" AS
  // Java import statements
  import java.io.File;
  import java.security.AccessControlException;
 
  // Class definition.
  public class DeleteFile
  {
    // Define variable(s).
    private static File file;
 
    // Define copyTextFile() method.
    public static void deleteFile(String fileName) throws AccessControlException {
 
      // Create files from canonical file names.
      file = new File(fileName);
 
      // Delete file(s).
      if (file.isFile() && file.delete()) {}}}
/

-- Re-enable substitution variables.
SET DEFINE ON

-- Create PL/SQL wrapper to the Java library that deletes files.
CREATE OR REPLACE PROCEDURE delete_file (dfile VARCHAR2) IS
LANGUAGE JAVA
NAME 'DeleteFile.deleteFile(java.lang.String)';
/

-- Conditionally drop the tables.
BEGIN
  FOR i IN (SELECT   uo.object_type
            ,        uo.object_name
            FROM     user_objects uo
            WHERE    uo.object_name IN ('IMPORT_MASTER','IMPORT_MASTER_S'
                                       ,'IMPORT_DATA','IMPORT_DATA_S'
                                       ,'IMPORT_LOG','IMPORT_LOG_S'
                                       ,'IMPORT_DISCARD','IMPORT_DISCARD_S'
                                       ,'IMPORT_BAD','IMPORT_BAD_S')
            AND      uo.object_type IN ('TABLE','SEQUENCE')
            ORDER BY 1) LOOP
    IF i.object_type = 'SEQUENCE' THEN
      EXECUTE IMMEDIATE 'DROP '||i.object_type||' '||i.object_name;
    ELSIF i.object_type = 'TABLE' THEN
      EXECUTE IMMEDIATE 'DROP '||i.object_type||' '||i.object_name||' CASCADE CONSTRAINTS';
    END IF;
  END LOOP;
END;
/

DESCRIBE item_import

-- Create a master import.
CREATE TABLE import_master
( import_master_id  NUMBER CONSTRAINT pk_import_master PRIMARY KEY
, import_table      VARCHAR2(30));

DESCRIBE import_master
 
-- Create sequence for import master.
CREATE SEQUENCE import_master_s;
 
-- Create import table.
CREATE TABLE import_data
( import_data_id    NUMBER CONSTRAINT pk_import_data PRIMARY KEY
, import_master_id  NUMBER
, import_data       CLOB
, CONSTRAINT fk_import_data FOREIGN KEY (import_data_id)
  REFERENCES import_master (import_master_id))
LOB (import_data) STORE AS BASICFILE item_import_clob
(TABLESPACE videots ENABLE STORAGE IN ROW CHUNK 32768
 PCTVERSION 10 NOCACHE LOGGING
 STORAGE (INITIAL 1048576
          NEXT    1048576
          MINEXTENTS 1
          MAXEXTENTS 2147483645));
 
DESCRIBE import_data

-- Create sequence for import master.
CREATE SEQUENCE import_data_s;
 
-- Create import table.
CREATE TABLE import_log
( import_log_id     NUMBER CONSTRAINT pk_import_log PRIMARY KEY
, import_master_id  NUMBER
, import_log        CLOB
, CONSTRAINT fk_import_log FOREIGN KEY (import_log_id)
  REFERENCES import_master (import_master_id))
LOB (import_log) STORE AS BASICFILE item_import_log_clob
(TABLESPACE videots ENABLE STORAGE IN ROW CHUNK 32768
 PCTVERSION 10 NOCACHE LOGGING
 STORAGE (INITIAL 1048576
          NEXT    1048576
          MINEXTENTS 1
          MAXEXTENTS 2147483645));
 
-- Create sequence for import master.
CREATE SEQUENCE import_log_s;

DESCRIBE import_log
 
-- Create import table.
CREATE TABLE import_discard
( import_discard_id  NUMBER CONSTRAINT pk_import_discard PRIMARY KEY
, import_master_id   NUMBER
, import_discard     CLOB
, CONSTRAINT fk_import_discard FOREIGN KEY (import_discard_id)
  REFERENCES import_master (import_master_id))
LOB (import_discard) STORE AS BASICFILE item_import_discard_clob
(TABLESPACE videots ENABLE STORAGE IN ROW CHUNK 32768
 PCTVERSION 10 NOCACHE LOGGING
 STORAGE (INITIAL 1048576
          NEXT    1048576
          MINEXTENTS 1
          MAXEXTENTS 2147483645));
 
-- Create sequence for import master.
CREATE SEQUENCE import_discard_s;

DESCRIBE import_discard
 
-- Create import table.
CREATE TABLE import_bad
( import_bad_id     NUMBER CONSTRAINT pk_import_bad PRIMARY KEY
, import_master_id  NUMBER
, import_bad        CLOB
, CONSTRAINT fk_import_bad FOREIGN KEY (import_bad_id)
  REFERENCES import_master (import_master_id))
LOB (import_bad) STORE AS BASICFILE item_import_bad_clob
(TABLESPACE videots ENABLE STORAGE IN ROW CHUNK 32768
 PCTVERSION 10 NOCACHE LOGGING
 STORAGE (INITIAL 1048576
          NEXT    1048576
          MINEXTENTS 1
          MAXEXTENTS 2147483645));
 
-- Create sequence for import master.
CREATE SEQUENCE import_bad_s;

DESCRIBE import_bad


SELECT   list.column_value
FROM     TABLE(list_files(get_directory_path('LOG'))) list
JOIN    (SELECT UPPER('item_import') AS file_name FROM dual) filter
ON       list.column_value = FILTER.file_name;


-- Generic loading script to any of the CLOB columns.
CREATE OR REPLACE FUNCTION load_clob_from_file
( pv_src_file_name  IN VARCHAR2
, pv_virtual_dir    IN VARCHAR2
, pv_table_name     IN VARCHAR2
, pv_column_name    IN VARCHAR2
, pv_foreign_key    IN NUMBER ) RETURN NUMBER IS
 
  -- Declare placeholder for sequence generated primary key.
  lv_primary_key  NUMBER;
 
  -- Declare default return value.
  lv_retval  NUMBER := 0;
 
  -- Declare local DBMS_LOB.LOADCLOBFROMFILE variables.
  des_clob    CLOB;
  src_clob    BFILE := BFILENAME(pv_virtual_dir,pv_src_file_name);
  des_offset  NUMBER := 1;
  src_offset  NUMBER := 1;
  ctx_lang    NUMBER := dbms_lob.default_lang_ctx;
  warning     NUMBER;
 
  -- Declare pre-reading size.
  src_clob_size  NUMBER;
 
  -- Declare variables for handling NDS sequence value.
  lv_sequence          VARCHAR2(30);
  lv_sequence_output   NUMBER;
  lv_sequence_tagline  VARCHAR2(10) := '_s.nextval';
 
  -- Define local NDS statement vvariable.
  stmt  VARCHAR2(2000);
 
  -- Declare the function as an autonomous transaction.
  PRAGMA AUTONOMOUS_TRANSACTION;
 
BEGIN
 
  -- Open file only when found.
  IF      dbms_lob.fileexists(src_clob) = 1  
  AND NOT dbms_lob.isopen(src_clob) = 1 THEN
    src_clob_size := dbms_lob.getlength(src_clob);
    dbms_lob.OPEN(src_clob,dbms_lob.lob_readonly);
  END IF;
 
  -- Concatenate the sequence name with the tagline.
  lv_sequence := pv_table_name || lv_sequence_tagline;
 
  -- Assign the sequence through an anonymous block.
  stmt := 'BEGIN '
       || '  :output := '||lv_sequence||';'
       || 'END;';
 
  -- Run the statement to extract a sequence value through NDS.
  EXECUTE IMMEDIATE stmt USING IN OUT lv_sequence_output;
 
  --  Create a dynamic statement that works for all source and log files.
  -- ----------------------------------------------------------------------
  --  NOTE: This statement requires that the row holding the primary key
  --        has been committed because otherwise it raises the following
  --        error because it can't verify the integrity of the foreign
  --        key constraint.
  -- ----------------------------------------------------------------------
  --        DECLARE
  --        *
  --        ERROR at line 1:
  --        ORA-00060: deadlock detected while waiting for resource
  --        ORA-06512: at "IMPORT.LOAD_CLOB_FROM_FILE", line 50
  --        ORA-06512: at line 20
  -- ----------------------------------------------------------------------  
  stmt := 'INSERT INTO '||pv_table_name||' '||CHR(10)||
          'VALUES '||CHR(10)||
          '('||lv_sequence_output||CHR(10)||
          ','||pv_foreign_key||CHR(10)||
          ', empty_clob())'||CHR(10)||
          'RETURNING '||pv_column_name||' INTO :locator';
 
  -- Run dynamic statement.
  EXECUTE IMMEDIATE stmt USING OUT des_clob;
 
  -- Read and write file to CLOB, close source file and commit.
  dbms_lob.loadclobfromfile( dest_lob     => des_clob
                           , src_bfile    => src_clob
                           , amount       => dbms_lob.getlength(src_clob)
                           , dest_offset  => des_offset
                           , src_offset   => src_offset
                           , bfile_csid   => dbms_lob.default_csid
                           , lang_context => ctx_lang
                           , warning      => warning );
 
  -- Close open source file.
  dbms_lob.close(src_clob);
 
  -- Commit write and conditionally acknowledge it.
  IF src_clob_size = dbms_lob.getlength(des_clob) THEN
    COMMIT;
    lv_retval := 1;
  ELSE
    RAISE dbms_lob.operation_failed;
  END IF;
 
  RETURN lv_retval;  
END load_clob_from_file;
/

-- Enable PL/SQL output display.
SET SERVEROUTPUT ON SIZE UNLIMITED

-- Master clean up script.
CREATE OR REPLACE FUNCTION cleanup_external_files
( table_in           VARCHAR2
, data_directory_in  VARCHAR2
, log_directory_in   VARCHAR2 ) RETURN NUMBER IS
 
  -- Declare a local Attribute Data Type (ADT).
  TYPE list IS TABLE OF VARCHAR2(3);
 
  -- Declare a collection.
  lv_extension LIST := list('csv','log','bad','dis');
 
  -- Define a default return value.
  retval NUMBER := 0;
 
  -- Declare base target table name.
  lv_target_table  VARCHAR2(30) := 'IMPORT';
  lv_foreign_key   NUMBER;
 
  -- Decalre a cursor to find external tables.
  CURSOR check_source (cv_table_name VARCHAR2) IS
    SELECT   xt.file_name
    ,        xt.path_name
    FROM    (SELECT   uxt.table_name
             ,        get_directory_path(
                        uxt.default_directory_name) AS path_name
             ,        ixt.column_value AS file_name
             FROM     user_external_tables uxt CROSS JOIN
             TABLE(
               list_files(
                 get_directory_path(
                   uxt.default_directory_name))) ixt) xt
    JOIN     user_external_locations xl
    ON       xt.TABLE_NAME = xl.TABLE_NAME
    AND      xt.file_name = xl.location
    AND xt.TABLE_NAME = UPPER(cv_table_name);
 
  -- Declare a cursor to find files and compare for one input file name.
  CURSOR check_logs ( cv_file_name VARCHAR2
                    , cv_dir_name  VARCHAR2 ) IS
    SELECT   get_directory_path(cv_dir_name) AS path_name
    ,        list.column_value AS file_name
    FROM     TABLE(
               list_files(
                 get_directory_path(cv_dir_name))) list
    JOIN    (SELECT cv_file_name AS file_name FROM dual) filter
    ON       list.column_value = filter.file_name;
 
  -- Declare the function as autonomous.
  PRAGMA AUTONOMOUS_TRANSACTION;
 
BEGIN
 
  -- Master loop to check for source and log files.  
  FOR i IN check_source (table_in) LOOP

    -- Assign next sequence value to local variable.
    lv_foreign_key := import_master_s.NEXTVAL;
 
    -- Write the master record and commit it for the autonomous threads.
    INSERT INTO import_master
    VALUES (lv_foreign_key,'ITEM_IMPORT');
    COMMIT;
 
    -- Process all file extensions.    
    FOR j IN 1..lv_extension.COUNT LOOP
 
      -- The source data file is confirmed by the CHECK_SOURCE cursor.
      IF lv_extension(j) = 'csv' THEN
 
        --  Load the source data file.
        -- ----------------------------------------------------------
        --  The RETVAL holds success or failure, this approach 
        --  suppresses an error when the file can't be loaded.
        --  It should only occur when there's no space available 
        --  in the target table.
        retval := load_clob_from_file(i.file_name
                                     ,data_directory_in
                                     ,lv_target_table||'_DATA'
                                     ,lv_target_table||'_DATA'
                                     ,lv_foreign_key);

        -- Increment the foreign key value.
        lv_foreign_key := lv_foreign_key + 1;

        -- Delete the file with fully qualified path; the backslash needs to 
        -- be replaced by a forward slash when working in Linux or Unix.
        delete_file(i.path_name||'\'||i.file_name); -- '''
      ELSE
 
        -- Verify that log file exists before attempting to load it.
        FOR k IN check_logs ( LOWER(table_in)||'.'||lv_extension(j)
                            , log_directory_in) LOOP
 
          --  Load the log, bad, or dis(card) file.
          -- ----------------------------------------------------------
          --  The RETVAL holds success or failure, as mentioned above.
          retval := load_clob_from_file(LOWER(table_in)||'.'||lv_extension(j)
                                       ,log_directory_in
                                       ,lv_target_table||'_'||lv_extension(j)
                                       ,lv_target_table||'_'||lv_extension(j)
                                       ,lv_foreign_key);

          -- Delete the file with fully qualified path; the backslash needs to 
          -- be replaced by a forward slash when working in Linux or Unix.
          delete_file(k.path_name||'\'||k.file_name); -- '''
        END LOOP;
      END IF;
    END LOOP;
    retval := 1;
  END LOOP;
  RETURN retval;
END;
/

-- Test the cleanup_external_files function.
VARIABLE sv_return_var NUMBER
CALL cleanup_external_files('ITEM_IMPORT','UPLOAD','LOG')
INTO :sv_return_var;
SELECT :sv_return_var AS "Boolean Flag" FROM dual;

-- Enable more than default content display from CLOB columns.
SET LONG 1510

-- Query import master.
SELECT * FROM import_master;

-- Query import log.
SELECT import_log
FROM   import_log;

-- Query import discards.
SELECT import_discard
FROM   import_discard;

-- Query import bad records.
SELECT import_bad
FROM   import_bad;

-- Create a collection of item_import objects.
CREATE OR REPLACE TYPE item_import_object_table IS
  TABLE OF item_import_object;
/

-- Create an external file contents function.
CREATE OR REPLACE FUNCTION external_file_contents
  RETURN item_import_object_table IS
 
  -- Define a local counter.
  lv_counter NUMBER := 1;
 
  -- Construct an empty collection of ITEM_IMPORT_OBJECT data types.
  lv_item_import_table ITEM_IMPORT_OBJECT_TABLE :=
    item_import_object_table();
 
  -- Decalre a cursor to find external tables.
  CURSOR c IS
    SELECT   *
    FROM     item_import
    WHERE    external_file_found('ITEM_IMPORT') = 1;
 
BEGIN
  FOR i IN c LOOP
    lv_item_import_table.EXTEND;
    lv_item_import_table(lv_counter) :=
      item_import_object(i.asin_number
                        ,i.item_type
                        ,i.item_title
                        ,i.item_subtitle
                        ,i.item_rating
                        ,i.item_rating_agency
                        ,i.item_release_date);
    lv_counter := lv_counter + 1;
  END LOOP;
 
  /*
   *  This is where you can place autonomous function calls:
   *  ======================================================
   *   - These can read source and log files, and write them
   *     to CLOB attributes for later inspection or review.
   *   - These can call Java libraries to delete files, but
   *     you should note that Java deletes any file rather
   *     than moving it to the trash bin (where you might
   *     recover it.
   */
 
  RETURN lv_item_import_table;
END;
/

SHOW ERRORS

/*
 *  SQL*Plus formatting.
 */
SET PAGESIZE 99
 
COLUMN asin_number        FORMAT A11 HEADING "ASIN #"
COLUMN item_title         FORMAT A46 HEADING "ITEM TITLE"
COLUMN item_rating        FORMAT A6  HEADING "RATING"
COLUMN item_release_date  FORMAT A11 HEADING "RELEASE|DATE"

SELECT asin_number
,      item_title
,      item_rating
,      item_release_date
FROM   TABLE(external_file_contents);