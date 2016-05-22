/*
 * ReadClobFile.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that reads a file and translates
 * it into a CLOB data type.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF

DROP JAVA SOURCE "ReadClobFile"; 

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ReadClobFile" AS
  // Java library imports.
  import java.io.File;
  import java.io.BufferedReader;
  import java.io.FileNotFoundException;
  import java.io.IOException;
  import java.io.FileReader;
  import java.security.AccessControlException;
  import java.sql.*;
  import oracle.sql.driver.*;
  import oracle.sql.*;

  // Class definition.  
  public class ReadClobFile {
    // Define class variables.
    private static int i;
    private static File file;
    private static FileReader inTextFile;
    private static BufferedReader inTextReader;
    private static StringBuffer output = new StringBuffer();
    private static String outLine, outText;
    private static CLOB outCLOB, tempCLOB;
 
    // Define readFile() method.
    public static oracle.sql.CLOB readFile(String fromFile)
      throws AccessControlException, IOException, SQLException  {
      // Read file.
      try {
        // Initialize File.
        file = new File(fromFile);

        // Check for valid file.
        if (file.exists()) {

          // Assign file to a stream.          
          inTextFile = new FileReader(file);
          inTextReader = new BufferedReader(inTextFile);
 
          // Read character-by-character.
          while ((outLine = inTextReader.readLine()) != null) {
            output.append(outLine + "\n"); }
 
          // Assing the StringBuffer to a String.
          outText = output.toString();

          // Declare an Oracle connection.
          Connection conn =
            DriverManager.getConnection("jdbc:default:connection:");

          // Transfer the String to CLOB.
          outCLOB =
            CLOB.createTemporary(
               (oracle.jdbc.OracleConnectionWrapper) conn
              , true, CLOB.DURATION_CALL);
          i = outCLOB.setString(1,outText);

          // Close File.
          inTextFile.close(); }
        else {
          i = outCLOB.setString(1,"Empty"); }}
      catch (IOException e) {
        i = outCLOB.setString(1,"");
        return outCLOB; }
    return outCLOB; }}
/

SHOW ERRORS

/* Disable logical comparison operators in Java. */
SET DEFINE ON

DROP FUNCTION read_clob_file;

CREATE OR REPLACE FUNCTION read_clob_file
(from_file VARCHAR2) RETURN CLOB IS
LANGUAGE JAVA NAME
'ReadClobFile.readFile(java.lang.String)
 return oracle.sql.CLOB';
/

SET LONG 100000
SET PAGESIZE 9999
COLUMN atext FORMAT A60 HEADING "Text"
COLUMN asize FORMAT 99,999 HEADING "Size"

-- Query results.
SELECT   read_clob_file('C:\Data\loader\Hobbit1.txt') AS AText
,        LENGTH(read_clob_file('C:\Data\loader\Hobbit1.txt')) AS ASize
FROM dual;

CREATE OR REPLACE FUNCTION read_clob
( pv_file_name  VARCHAR2 ) RETURN CLOB IS
  /* Declare CLOB. */
  lv_clob  CLOB := empty_clob();

  /* Precompiler directive for an autonomous program scope. */
  -- PRAGMA autonomous_transaction;
BEGIN
  /* Assign the result of the function to a local CLOB variable. */
  lv_clob := read_clob_file(pv_file_name);

  /* Return the CLOB column in a new session. */
  RETURN lv_clob;
END;
/

SELECT   read_clob('C:\Data\loader\Hobbit1.txt') AS AText
,        LENGTH(read_clob('C:\Data\loader\Hobbit1.txt')) AS ASize
FROM dual;


SELECT   LENGTH(read_clob_file('C:\Data\loader\Hobbit1.txt')) AS ASize
FROM dual;

-- Drop temp table if it exists.
DROP TABLE temp;

-- Create temp table.
CREATE TABLE temp
( temp_id    NUMBER GENERATED ALWAYS AS IDENTITY
, temp_clob  CLOB
, CONSTRAINT temp_pk PRIMARY KEY (temp_id));

-- Insert a clob from the file system.
INSERT INTO temp
(temp_clob)
VALUES
(read_clob_file('C:\Data\loader\Hobbit1.txt'));

-- Commit the insert.
COMMIT;

-- Query the column results.
SELECT   temp_clob AS AText
,        LENGTH(temp_clob) AS ASize
FROM     temp;

