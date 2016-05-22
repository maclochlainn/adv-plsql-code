DECLARE
  /* Declare local input variables. */
  lv_location      VARCHAR2(60) := 'C:\Data\Direct';
  lv_file_name     VARCHAR2(40) := 'TextFile.txt';

  /* Declare a file reference pointer and buffer. */
  lv_file     UTL_FILE.FILE_TYPE;  -- File reference
  lv_line     VARCHAR2(32767);     -- Reading buffer
BEGIN
  /* Check for open file and close when open. */
  IF utl_file.is_open(lv_file) THEN
    utl_file.fclose(lv_file);
  END IF;

  /* Open the file for read-only of 32,767 byte lines. */
  lv_file := utl_file.fopen( location     => lv_location
                           , filename     => lv_file_name
                           , open_mode    => 'R'
                           , max_linesize => 32767);

  /* Read all lines of a text file. */
  LOOP
    /* Read a line of text until the eof marker. */
    utl_file.get_line( file   => lv_file
                     , buffer => lv_line );

    /* Print the line of text. */
    dbms_output.put_line(NVL(lv_line,CHR(10)));
  END LOOP;
EXCEPTION
  /* Close file after reading the last line of a file. */
  WHEN NO_DATA_FOUND THEN
    utl_file.fclose(lv_file);
  /* Close file after a thrown exception. */
  WHEN UTL_FILE.READ_ERROR THEN
    dbms_output.put_line(
      'Position ['||utl_file.fgetpos(lv_file)||']');
    utl_file.fclose(lv_file);
    RETURN;
END;
/