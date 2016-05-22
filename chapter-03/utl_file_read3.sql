CREATE OR REPLACE FUNCTION read_file_to_clob
( pv_location   VARCHAR2
, pv_file_name  VARCHAR2 ) RETURN CLOB IS 

  /* Declare local input variables. */
  lv_location      VARCHAR2(60);
  lv_file_name     VARCHAR2(40);

  /* Declare a file reference pointer and buffer. */
  lv_file    UTL_FILE.FILE_TYPE;  -- File reference
  lv_line    VARCHAR2(32767);     -- Reading buffer

  /* Declare local sizing variables. */
  lv_file_size  NUMBER;
  lv_line_size  NUMBER;
  lv_read_size  NUMBER :=0;

    /* Declare local file attribute data. */
  lv_file_exists  BOOLEAN := FALSE;
  lv_block_size   BINARY_INTEGER;

  /* Declare a control variable and return CLOB variable. */
  lv_enable  BOOLEAN := FALSE;
  lv_return  CLOB;
BEGIN
  /* Declare local input variables. */
  lv_location  := pv_location;
  lv_file_name := pv_file_name;

  /* Check for open file and close when open. */
  IF utl_file.is_open(lv_file) THEN
    utl_file.fclose(lv_file);
  END IF;

  /* Read the file attributes to get the physical size. */
  utl_file.fgetattr( location    => lv_location
                   , filename    => lv_file_name
                   , fexists     => lv_file_exists
                   , file_length => lv_file_size
                   , block_size  => lv_block_size ); 

  /* Open only files that exist. */
  IF lv_file_exists THEN
    /* Open the file for read-only of 32,767 byte lines. */
    lv_file := utl_file.fopen( location     => lv_location
                             , filename     => lv_file_name
                             , open_mode    => 'R'
                             , max_linesize => 32767);

    /* Create a temporary CLOB in memory. */
    dbms_lob.createtemporary(lv_return, FALSE, dbms_lob.CALL);

    /* Read all lines of a text file. */
    WHILE (lv_read_size < lv_file_size) LOOP
      /* Read a line of text until the eof marker. */
      utl_file.get_line( file   => lv_file
                       , buffer => lv_line );

      /* Add the line terminator or 2 bytes to its length. */
      lv_line := NVL(lv_line,'')||CHR(10);
      lv_read_size := lv_read_size
                    + LENGTH(NVL(lv_line,CHR(10))) + 2;

      /* Write to an empty CLOB or append to an existing CLOB. */
      IF NOT lv_enable THEN
        /* Write to the temporary CLOB variable. */
        dbms_lob.write( lv_return, LENGTH(lv_line), 1, lv_line);

        /* Set the control variable. */
        lv_enable := TRUE;
      ELSE
        /* Append to the temporary CLOB variable. */
        dbms_lob.writeappend( lv_return, LENGTH(lv_line),lv_line);
      END IF;
    END LOOP;

    /* Close the file. */
    utl_file.fclose(lv_file);
  END IF;

  /* This line is never reached. */
  RETURN lv_return;
EXCEPTION
  WHEN OTHERS THEN
    utl_file.fclose(lv_file);
    RETURN NULL;
END;
/

LIST
SHOW ERRORS

SET LONG 100000
SET PAGESIZE 999

SELECT read_file_to_clob('DIRECT','TextFile.txt') AS "Output"
FROM   dual;

SELECT read_file_to_clob('C:\Data\InDirect','TextFile.txt') AS "Output"
FROM   dual;