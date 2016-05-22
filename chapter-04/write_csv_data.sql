/*
 * write_csv_data.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that writes text and binary files.
 */

 SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION write_item_records
RETURN CLOB IS
  /* Declare a file reference pointer and buffer. */
  lv_clob     CLOB;            -- File reference
  lv_line     VARCHAR2(32767); -- Reading buffer
  first_line  BOOLEAN := TRUE; -- First line flag.

  /* Declare a cursor. */
  CURSOR get_items IS
    SELECT   i.item_title
    ,        i.item_subtitle
    FROM     item i
    WHERE    REGEXP_LIKE(i.item_title,'Star.*$');
BEGIN
  /* Create a temporary CLOB in memory for the scope of the call. */
  dbms_lob.createtemporary(lv_clob, FALSE, dbms_lob.call);

  /* Read the cursor for values. */
  FOR i IN get_items LOOP
    /* Concatenate the results into a CSV format. */
    lv_line := i.item_title||','||i.item_subtitle||CHR(10);

    /* Write or append a line of text. */
    IF first_line THEN
      dbms_lob.write(
          lob_loc => lv_clob
        , amount  => LENGTH(lv_line)
        , offset  => 1
        , buffer  => lv_line);

      /* Reset logical first line control flag. */
      first_line := FALSE;
    ELSE
      dbms_lob.writeappend(
          lob_loc => lv_clob
        , amount  => LENGTH(lv_line)
        , buffer  => lv_line);
    END IF;
  END LOOP;

  RETURN lv_clob;
EXCEPTION
  /* Manage raised exceptions. */
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
END;
/

SHOW ERRORS

SELECT   write_item_records
FROM     dual;

BEGIN
  IF write_file.write(
        'C:\Data\loader\ItemText.csv'
       , write_item_records) = 1 THEN
    dbms_output.put_line('Success');
  END IF;
END;
/