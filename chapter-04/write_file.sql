/*
 * write_file.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that writes text and binary files.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "Write" AS
  // Java library imports.
  import java.io.File;
  import java.io.IOException;
  import java.io.FileReader;
  import java.io.FileWriter;
  import javax.imageio.stream.FileImageInputStream;
  import javax.imageio.stream.FileImageOutputStream;
  import java.security.AccessControlException;
  import oracle.sql.driver.*;
  import oracle.sql.*;
 
  // Class definition.  
  public class Write {
    // Define variable(s).
    private static File file;
    private static FileReader inTextFile;
    private static FileWriter outTextFile;
    private static FileImageInputStream inImageFile;
    private static FileImageOutputStream outImageFile;
 
    // Define writeText() method.
    public static int writeText(String toFile, CLOB clob)
      throws AccessControlException, java.sql.SQLException {

      // Create files from canonical file names.
      file = new File(toFile);
 
      // Write file.
      try {

        // Define and initialize FileReader(s).
        outTextFile = new FileWriter(file);
 
        // Delete older file when present.
        if (file.isFile() && file.delete()) {}
 
        // Write character stream.
        outTextFile.write(
          clob.getSubString(1L,(int) clob.length()));
 
        // Close Stream(s).
        outTextFile.close(); }
      catch (IOException e) {
        return 0; }
    return 1; }
 
    // Define writeImage() method.
    public static int writeImage(String toFile, BLOB blob)
      throws AccessControlException, java.sql.SQLException {

      // Create files from canonical file names.
      file = new File(toFile);
 
      // Write file.
      try {
 
        // Define and initialize FileReader(s).
        outImageFile = new FileImageOutputStream(file);
 
        // Delete older file when present.
        if (file.isFile() && file.delete()) {}
 
        // Write binary stream.
        outImageFile.write(
          blob.getBytes(1L,(int) blob.length()));
 
        // Close Stream(s).
        outImageFile.close(); }
    catch (IOException e) {
      return 0; }
    return 1; }}
/

/* Disable logical comparison operators in Java. */
SET DEFINE ON

CREATE OR REPLACE FUNCTION write_text_file
(to_file VARCHAR2, text CLOB)
RETURN NUMBER IS LANGUAGE JAVA NAME
'Write.writeText(java.lang.String,oracle.sql.CLOB)
 return java.lang.int';
/

BEGIN
  IF write_text_file(
        'C:\Data\loader\Hobbit21.txt'
       , read_clob_file('C:\Data\loader\Hobbit1.txt')) = 1 THEN
    dbms_output.put_line('Success');
  END IF;
END;
/

CREATE OR REPLACE FUNCTION write_image_file
(to_file VARCHAR2, blob BLOB)
RETURN NUMBER IS LANGUAGE JAVA NAME
'Write.writeImage(java.lang.String,oracle.sql.BLOB)
 return java.lang.int';
/

BEGIN
  IF write_image_file(
        'C:\Data\loader\Hobbit21.png'
       , read_blob_file('C:\Data\loader\Hobbit1.png')) = 1 THEN
    dbms_output.put_line('Success');
  END IF;
END;
/

CREATE OR REPLACE PACKAGE write_file IS
  /* Write a text file. */
  FUNCTION write
  ( to_file  VARCHAR2
  , text     CLOB)
  RETURN NUMBER;

  /* Write a binary file. */
  FUNCTION write
  ( to_file  VARCHAR2
  , blob     BLOB)
  RETURN NUMBER;
END write_file;
/

CREATE OR REPLACE PACKAGE BODY write_file AS
  /* Write a text file. */
  FUNCTION write
  ( to_file  VARCHAR2
  , text     CLOB)
  RETURN NUMBER IS LANGUAGE JAVA NAME
    'Write.writeText(java.lang.String,oracle.sql.CLOB)
     return java.lang.int';

  /* Write a binary file. */
  FUNCTION write
  ( to_file  VARCHAR2
  , blob     BLOB)
  RETURN NUMBER IS LANGUAGE JAVA NAME
    'Write.writeImage(java.lang.String,oracle.sql.BLOB)
     return java.lang.int';
END write_file;
/

BEGIN
  IF write_file.write(
        'C:\Data\loader\Hobbit21.txt'
       , read_clob_file('C:\Data\loader\Hobbit1.txt')) = 1 THEN
    dbms_output.put_line('Success');
  END IF;
END;
/

BEGIN
  IF write_file.write(
        'C:\Data\loader\Hobbit21.png'
       , read_clob_file('C:\Data\loader\Hobbit1.png')) = 1 THEN
    dbms_output.put_line('Success');
  END IF;
END;
/

-- Create a three column temp table.
CREATE TABLE temp
( temp_id    NUMBER GENERATED ALWAYS AS IDENTITY
, textClob   CLOB
, imageBlob  BLOB);

INSERT INTO temp
(textclob)
VALUES
(read_clob_file('C:\Data\loader\Hobbit1.txt'));

UPDATE temp
SET    imageblob = read_blob_file('C:\Data\loader\Hobbit1.png')
WHERE  temp_id = 1;
