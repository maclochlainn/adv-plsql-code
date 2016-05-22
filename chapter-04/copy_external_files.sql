/*
 * copy_external_files.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that copies text and binary files.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "Copy" AS
  // Java library imports.
  import java.io.File;
  import java.io.IOException;
  import java.io.FileReader;
  import java.io.FileWriter;
  import javax.imageio.stream.FileImageInputStream;
  import javax.imageio.stream.FileImageOutputStream;
  import java.security.AccessControlException;
 
  // Class definition.  
  public class Copy
  {
    // Define variable(s).
    private static int c;
    private static File file1,file2;
    private static FileReader inTextFile;
    private static FileWriter outTextFile;
    private static FileImageInputStream inImageFile;
    private static FileImageOutputStream outImageFile;
 
    // Define copyText() method.
    public static int copyText(String fromFile,String toFile)
      throws AccessControlException
    {
      // Create files from canonical file names.
      file1 = new File(fromFile);
      file2 = new File(toFile);
 
      // Copy file(s).
      try
      {
        // Define and initialize FileReader(s).
        inTextFile  = new FileReader(file1);
        outTextFile = new FileWriter(file2);
 
        // Delete older file when present.
        if (file2.isFile() && file2.delete()) {}
 
        // Read character-by-character.
        while ((c = inTextFile.read()) != -1) {
          outTextFile.write(c); }
 
        // Close Stream(s).
        inTextFile.close();
        outTextFile.close(); }
      catch (IOException e) {
        return 0; }
    return 1; }
 
    // Define copyImage() method.
    public static int copyImage(String fromFile,String toFile)
      throws AccessControlException
    {
      // Create files from canonical file names.
      file1 = new File(fromFile);
      file2 = new File(toFile);
 
      // Copy file(s).
      try
      {
 
      // Define and initialize FileReader(s).
      inImageFile  = new FileImageInputStream(file1);
      outImageFile = new FileImageOutputStream(file2);
 
      // Delete older file when present.
      if (file2.isFile() && file2.delete()) {}
 
      // Read character-by-character.
      while ((c = inImageFile.read()) != -1) {
        outImageFile.write(c); }
 
      // Close Stream(s).
      inImageFile.close();
      outImageFile.close(); }
    catch (IOException e) {
      return 0; }
    return 1; }}
/

/* Disable logical comparison operators in Java. */
SET DEFINE ON

CREATE OR REPLACE FUNCTION copy_text_file
(from_file VARCHAR2, to_file VARCHAR2)
RETURN NUMBER IS LANGUAGE JAVA NAME
'Copy.copyText(java.lang.String,java.lang.String) return java.lang.int';
/

CREATE OR REPLACE FUNCTION copy_image_file
(from_file VARCHAR2, to_file VARCHAR2)
RETURN NUMBER IS LANGUAGE JAVA NAME
'Copy.copyImage(java.lang.String,java.lang.String) return java.lang.int';
/

DECLARE
  file1 BFILE := BFILENAME('LOADER','Hobbit1.png');
  file2 BFILE := BFILENAME('LOADER','Hobbit1_Copy.png');
BEGIN
  IF copy_image_file(
         get_canonical_bfilename(
           pv_table_name    => 'EXTERNAL_FILE'
         , pv_bfile_column  => 'TEXT_FILE'
         , pv_primary_key   => 'FILE_ID'
         , pv_primary_value => '1')
       , get_canonical_bfilename(
           pv_table_name    => 'EXTERNAL_FILE'
         , pv_bfile_column  => 'TEXT_FILE'
         , pv_primary_key   => 'FILE_ID'
         , pv_primary_value => '2')) = 1 THEN
    DBMS_OUTPUT.put_line('It copied an image file.');
  END IF;
END;
/

DECLARE
  file1 BFILE := BFILENAME('LOADER','Hobbit1.txt');
  file2 BFILE := BFILENAME('LOADER','Hobbit1_Copy.txt');
BEGIN
  IF copy_image_file(
         get_canonical_bfilename(
           pv_table_name    => 'EXTERNAL_FILE'
         , pv_bfile_column  => 'IMAGE_FILE'
         , pv_primary_key   => 'FILE_ID'
         , pv_primary_value => '1')
       , get_canonical_bfilename(
           pv_table_name    => 'EXTERNAL_FILE'
         , pv_bfile_column  => 'IMAGE_FILE'
         , pv_primary_key   => 'FILE_ID'
         , pv_primary_value => '2')) = 1 THEN
    DBMS_OUTPUT.put_line('It copied a text file.');
  END IF;
END;
/

/* Copy the image. */
CREATE OR REPLACE FUNCTION copy_image
( file_name_1     VARCHAR2
, file_path_1     VARCHAR2
, file_name_2     VARCHAR2
, file_path_2     VARCHAR2 :=  NULL
, file_type       VARCHAR2 := 'IMAGE'
, file_system     VARCHAR2 := 'WINDOWS')
RETURN NUMBER IS
  /* Declare 0 as false standby value. */
  lv_return_code  NUMBER := 0;
  lv_file_path    VARCHAR2(100);
  lv_valid_type   VARCHAR2(7);
  lv_delimiter    VARCHAR2(1) := '\'; -- '''

  /* Declare valid file types. */
  TYPE type_table IS TABLE OF VARCHAR2(7);

  /* Declare an alternative file type. */
  lv_systems  TYPE_TABLE := type_table('LINUX','UNIX','WINDOWS');
  lv_types    TYPE_TABLE := type_table('IMAGE','TEXT');

BEGIN
  /* Copy the current directory as the target directory. */
  IF file_path_2 IS NULL THEN
    lv_file_path := file_path_1; 
  END IF;

  /* Assign valid file type. */
  FOR i IN 1..lv_types.COUNT LOOP
    IF lv_types(i) = file_type THEN
      lv_valid_type := file_type;
    END IF;
  END LOOP;

  /* Assign forward slash for Linux or Unix. */
  FOR i IN 1..lv_types.COUNT LOOP
    IF lv_types(i) = file_type AND
       lv_types(i) IN ('LINUX','UNIX') THEN
      lv_delimiter := '/';
    END IF;
  END LOOP;

  /* Copy text or image file. */
  IF lv_valid_type IS NOT NULL THEN
    /* Copy a text file. */
    IF lv_valid_type = 'TEXT' THEN
      IF copy_image_file(file_path_1||lv_delimiter||file_name_1
                        ,file_path_2||lv_delimiter||file_name_2) = 1 THEN
        /* Return success for copying a text file. */
        lv_return_code := 1;
      END IF;
    ELSIF lv_valid_type = 'IMAGE' THEN
      IF copy_image_file(file_path_1||lv_delimiter||file_name_1
                        ,file_path_2||lv_delimiter||file_name_2) = 1 THEN
        /* Return success for copying an image file. */
        lv_return_code := 1;
      END IF;
    END IF;
  ELSE
    raise_application_error('20010','Not TEXT or IMAGE type.');
  END IF;

  /* Return success or failure code. */
  RETURN lv_return_code;
END;
/

/* Query result. */
SELECT   copy_image('Hobbit1.txt'
                   ,'LOADER'
                   ,'Hobbit1_Copy.txt')
FROM     dual;