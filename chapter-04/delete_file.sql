SET DEFINE OFF

CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "DeleteFile" AS
  // Java import statements
  import java.io.File;
  import java.security.AccessControlException;
 
  // Class definition.
  public class DeleteFile
  {
    // Define variable(s).
    private static File file;
 
    // Define copyTextFile() method.
    public static void deleteFile(String fileName) throws AccessControlException {
 
      // Create files from canonical file names.
      file = new File(fileName);
 
      // Delete file(s).
      if (file.isFile() && file.delete()) {}}}
/

CREATE OR REPLACE PROCEDURE delete_file (dfile VARCHAR2) IS
LANGUAGE JAVA
NAME 'DeleteFile.deleteFile(java.lang.String)';
/

BEGIN
  delete_file('Hobbit1_copy.txt');
END;
/