 /*
 * ReadFile.java
 * Chapter 4, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that reads a file and translates
 * it into a VARCHAR2 data type, which has a maximum limit of 4,000 bytes.
 */

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
          inTextFile.close(); }}
      catch (IOException e) {
        outText = new String("");
        return outText; }
    return outText; }

    // A main method to test the class.
    public static void main(String args[]) {

      // Create an instance of a class for testing.
      ReadFile rf = new ReadFile();
      try {
      System.out.println(rf.readText(args[0])); }
      catch (IOException e) {
         System.out.println("Static main ..."); }}}