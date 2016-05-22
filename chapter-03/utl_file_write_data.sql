DECLARE
  /* Declare local input variables. */
  lv_location      VARCHAR2(60) := 'C:\Data\Direct';
  lv_file_name     VARCHAR2(40) := 'TextItem.txt';

  /* Declare a file reference pointer and buffer. */
  lv_file     UTL_FILE.FILE_TYPE;  -- File reference
  lv_line     VARCHAR2(32767);     -- Reading buffer

  /* Declare local file source. */
  lv_source   VARCHAR2(32765);

  /* Declare local file attribute data. */
  lv_file_size  NUMBER;
  lv_file_exists  BOOLEAN := FALSE;
  lv_block_size   BINARY_INTEGER;

  /* Declare a cursor. */
  CURSOR get_items IS
    SELECT   i.item_title
    ,        i.item_subtitle
    FROM     item i;

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
    /* Remove any previous file. */
    utl_file.fremove( location  => lv_location
                    , filename  => lv_file_name );
  END IF;

  /* Open the file for read-only of 32,767 byte lines. */
  lv_file := utl_file.fopen( location     => lv_location
                           , filename     => lv_file_name
                           , open_mode    => 'W'
                           , max_linesize => 32767);

  FOR i IN get_items LOOP
    /* Concatenate the results into a CSV format. */
    lv_source := i.item_title||','||i.item_subtitle;

    /* Write a line of text. */
    utl_file.put_line( file   => lv_file
                     , buffer => lv_source );
  END LOOP;

  /* Flush any buffer to file. */
  utl_file.fflush( file   => lv_file );

  /* Close the file. */
  utl_file.fclose(lv_file);
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