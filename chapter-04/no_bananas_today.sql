/*
 * no_bananas_today.sql
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that reads a file and translates
 * it into a VARCHAR2 data type, which has a maximum limit of 4,000 bytes.
 */

CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ReadClobFile" AS
  // Java library imports.
  import java.io.File;
  import java.io.BufferedReader;
  import java.io.ByteArrayOutputStream;
  import java.io.InputStream;
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
    private static byte[] byteArray;
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
          tempCLOB =
            CLOB.createTemporary(
               (oracle.jdbc.OracleConnectionWrapper) conn
              , true, CLOB.DURATION_SESSION);
          i = tempCLOB.setString(1,outText);

          // Assign the contents of the CLOB to a byte array.         
          byteArray = toByteArrayUsingJava(tempCLOB.getAsciiStream());

          // Create a new CLOB instance.
          outCLOB = new CLOB(
                           (oracle.jdbc.OracleConnectionWrapper) conn
                          , byteArray);

          // Free resources from the temporary CLOB.
          CLOB.freeTemporary(tempCLOB);

          // Close File.
          inTextFile.close(); }
        else {
          i = outCLOB.setString(1,"Empty"); }}
      catch (IOException e) {
        i = outCLOB.setString(1,"");
        return outCLOB; }
    return outCLOB; }

    private static byte[] toByteArrayUsingJava(InputStream is)
      throws IOException {
        // Declare a new ByteArrayOutputStream.
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        
        // Transfer InputStream to byte array.
        int i = is.read();
        while(i != -1) {
            baos.write(i);
            i = is.read(); }

        return baos.toByteArray(); }

    }
/