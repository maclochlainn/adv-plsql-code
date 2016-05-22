DECLARE
  /* Declare local input variables. */
  lv_src_location    VARCHAR2(60) := 'C:\Data\Direct';
  lv_src_file_name   VARCHAR2(40) := 'TextFile.txt';

  /* Declare local input variables. */
  lv_dest_location   VARCHAR2(60) := 'DIRECT';
  lv_dest_file_name  VARCHAR2(40) := 'TextCopy.txt';
BEGIN
  /* Open the file for read-only of 32,767 byte lines. */
  utl_file.frename( src_location  => lv_src_location
                  , src_filename  => lv_src_file_name
                  , dest_location => lv_dest_location
                  , dest_filename => lv_dest_file_name);

EXCEPTION
  /* Manage package raised exceptions. */
  WHEN utl_file.read_error THEN
    RAISE_APPLICATION_ERROR(-20001,'Read error.');
  WHEN utl_file.write_error THEN
    RAISE_APPLICATION_ERROR(-20002,'Write error.');
  WHEN utl_file.access_denied THEN
    RAISE_APPLICATION_ERROR(-20003,'Read error.');
END;
/

CREATE OR REPLACE FUNCTION move_file 
( pv_src_location    VARCHAR2
, pv_src_file_name   VARCHAR2
, pv_dest_location   VARCHAR2
, pv_dest_file_name  VARCHAR2 ) RETURN NUMBER IS

  /* Declare local input variables. */
  lv_src_location    VARCHAR2(60);
  lv_src_file_name   VARCHAR2(40);
  lv_dest_location   VARCHAR2(60);
  lv_dest_file_name  VARCHAR2(40);

  /* Declare a local return variable. */
  lv_return          NUMBER := 0;
BEGIN
  /* Assign parameters to local variables. */
  lv_src_location   := pv_src_location;
  lv_src_file_name  := pv_src_file_name;
  lv_dest_location  := pv_dest_location;
  lv_dest_file_name := pv_dest_file_name;

  /* Open the file for read-only of 32,767 byte lines. */
  utl_file.frename( src_location  => lv_src_location
                  , src_filename  => lv_src_file_name
                  , dest_location => lv_dest_location
                  , dest_filename => lv_dest_file_name);

  /* Set return variable to success. */
  lv_return := 1;

  /* Return 0 for false and 1 for true. */
  RETURN lv_return;
EXCEPTION
  /* Manage package raised exceptions. */
  WHEN utl_file.read_error THEN
    RAISE_APPLICATION_ERROR(-20001,'Read error.');
  WHEN utl_file.write_error THEN
    RAISE_APPLICATION_ERROR(-20002,'Write error.');
  WHEN utl_file.access_denied THEN
    RAISE_APPLICATION_ERROR(-20003,'Read error.');
END;
/

LIST
SHOW ERRORS

-- Query with the function.
SELECT   move_file('C:\Data\Direct'
                  ,'TextCopy.txt'
                  ,'DIRECT'
                  ,'TextMove.txt') AS "Moved"
FROM     dual;
