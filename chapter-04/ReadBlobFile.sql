/*
 * ReadBlobFile.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that reads a file and translates
 * it into a BLOB data type.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF

DROP JAVA SOURCE "ReadImageFile"; 

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ReadImageFile" AS
  // Java library imports.
  import java.io.File;
  import java.io.FileInputStream;
  import java.io.ByteArrayOutputStream;
  import java.io.FileNotFoundException;
  import java.io.IOException;
  import java.security.AccessControlException;
  import java.sql.*;
  import oracle.sql.driver.*;
  import oracle.sql.*;

  // Class definition.  
  public class ReadImageFile {
    // Define class variables.
    private static int i;
    private static byte [] byteArray, emptyArray;
    private static File file;
    private static FileInputStream inImageFile;
    private static ByteArrayOutputStream outImageFile;
    private static BLOB outBLOB;
 
    // Define readText() method.
    public static oracle.sql.BLOB readBinary(String fromFile)
      throws AccessControlException, IOException, SQLException  {
      // Read file.
      try {
        // Initialize File.
        file = new File(fromFile);

        // Check for valid file.
        if (file.exists()) {

          // Assign file to a stream.          
          inImageFile  = new FileInputStream(file);
 
          // Declare an output stream.
          outImageFile = new ByteArrayOutputStream();

          // Transfer InputStream to byte array.
          int i = inImageFile.read();
          while(i != -1) {
            outImageFile.write(i);
            i = inImageFile.read(); }

          // Assigning output stream to a byte array.
          byteArray = outImageFile.toByteArray();

          // Declare an Oracle connection.
          Connection conn =
            DriverManager.getConnection("jdbc:default:connection:");

          // Transfer the String to CLOB.
          outBLOB =
            BLOB.createTemporary(
               (oracle.jdbc.OracleConnectionWrapper) conn
              , true, BLOB.DURATION_SESSION);

          // Assign the byte stream to a BLOB.
          outBLOB.setBytes(1,byteArray);

          // Close Stream(s).
          inImageFile.close(); }
        else {
          i = outBLOB.setBytes(1,emptyArray); }}
      catch (IOException e) {
        i = outBLOB.setBytes(1,emptyArray);
        return outBLOB; }
    return outBLOB; }}
/

SHOW ERRORS

/* Disable logical comparison operators in Java. */
SET DEFINE ON
SET ECHO ON
DROP FUNCTION read_clob_file;

CREATE OR REPLACE FUNCTION read_blob_file
(from_file VARCHAR2) RETURN BLOB IS
LANGUAGE JAVA
NAME 'ReadImageFile.readBinary(java.lang.String) return oracle.sql.BLOB';
/

-- Drop temp table if it exists.
DROP TABLE temp;

-- Create temp table.
CREATE TABLE temp
( temp_id    NUMBER GENERATED ALWAYS AS IDENTITY
, temp_blob  BLOB
, CONSTRAINT temp_pk PRIMARY KEY (temp_id));

-- Insert a clob from the file system.
INSERT INTO temp
(temp_blob)
VALUES
(read_blob_file('C:\Data\loader\Hobbit1.png'));

-- Commit the insert.
COMMIT;

-- Query the column results.
SELECT   LENGTH(temp_blob) AS ASize
FROM     temp;