DECLARE
  /* Declare local input variables. */
  lv_location      VARCHAR2(60) := 'C:\Data\Direct';
  lv_file_name     VARCHAR2(40) := 'TextFile.txt';

  /* Declare a file reference pointer and buffer. */
  lv_file     UTL_FILE.FILE_TYPE;  -- File reference
  lv_line     VARCHAR2(32767);     -- Reading buffer

  /* Declare local sizing variables. */
  lv_file_size  NUMBER;
  lv_line_size  NUMBER;
  lv_read_size  NUMBER :=0;

    /* Declare local file attribute data. */
  lv_file_exists  BOOLEAN := FALSE;
  lv_block_size   BINARY_INTEGER;
BEGIN
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

    /* Read all lines of a text file. */
    WHILE (lv_read_size < lv_file_size) LOOP
      /* Read a line of text until the eof marker. */
      utl_file.get_line( file   => lv_file
                       , buffer => lv_line );

      /* Print the line of text. */
      dbms_output.put_line(NVL(lv_line,CHR(10)));

      /* Add the line size to the read size. */
      lv_read_size := lv_read_size
                    + LENGTH(NVL(lv_line,CHR(10))) + 2;
    END LOOP;

    /* Close the file. */
    utl_file.fclose(lv_file);
  END IF;
EXCEPTION
  /* Close file after a thrown exception. */
  WHEN UTL_FILE.READ_ERROR  THEN
    dbms_output.put_line(
      'Position ['||utl_file.fgetpos(lv_file)||']');
    RETURN;
END;
/