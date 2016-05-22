 /*
 * ReadSmallFile.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that reads a file and translates
 * it into a VARCHAR2 data type, which has a maximum limit of 4,000 bytes.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF

DROP JAVA SOURCE "ReadFile"; 

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ReadFile" AS
  // Java library imports.
  import java.io.File;
  import java.io.BufferedReader;
  import java.io.FileNotFoundException;
  import java.io.IOException;
  import java.io.FileReader;
  import java.security.AccessControlException;
 
  // Class definition.  
  public class ReadFile {
    // Define class variables.
    private static File file;
    private static FileReader inTextFile;
    private static BufferedReader inTextReader;
    private static StringBuffer output = new StringBuffer();
    private static String outLine, outText;
 
    // Define readText() method.
    public static String readText(String fromFile)
      throws AccessControlException, IOException {
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

          // Close File.
          inTextFile.close(); }
        else {
          outText = new String("Empty"); }}
      catch (IOException e) {
        outText = new String("");
        return outText; }
    return outText; }}
/

/* Disable logical comparison operators in Java. */
SET DEFINE ON

CREATE OR REPLACE FUNCTION read_text_file
(from_file VARCHAR2) RETURN VARCHAR2 IS
LANGUAGE JAVA
NAME 'ReadFile.readText(java.lang.String)
      return java.lang.String';
/

/* Query a file smaller than 4,000 bytes. */
SELECT   read_text_file('C:\Data\loader\SmallHobbit1.txt')
FROM     dual;

/* Query a file larger than 4,000 bytes. */
SELECT   read_text_file('C:\Data\loader\Hobbit1.txt')
FROM     dual;