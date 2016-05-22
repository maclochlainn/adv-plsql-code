CREATE OR REPLACE TYPE file_list AS TABLE OF VARCHAR2(255);
/

CREATE OR REPLACE AND COMPILE JAVA SOURCE
  NAMED "ListVirtualDirectory" AS

  // Import required classes.
  import java.io.*;
  import java.security.AccessControlException;
  import java.sql.*;
  import java.util.Arrays;
  import oracle.sql.driver.*;
  import oracle.sql.ArrayDescriptor;
  import oracle.sql.ARRAY;
 
  // Define the class.
  public class ListVirtualDirectory {
 
    // Define the method.
    public static ARRAY getList(String path) throws SQLException {
 
    // Declare variable as a null.
    ARRAY listed = null;
 
    // Define a connection (this is for Oracle 11g).
    Connection conn =
      DriverManager.getConnection("jdbc:default:connection:");
 
    // Use a try-catch block to trap a Java permission
    // error on the directory.
    try {
      // Declare a class with the file list.
      File directory = new File(path);
 
      // Declare a mapping schema SQL collection type.
      ArrayDescriptor arrayDescriptor = 
        new ArrayDescriptor("FILE_LIST",conn);
 
      // Translate the Java String[] collection type.
      listed = new ARRAY(arrayDescriptor
                        ,conn
                        ,((Object[]) directory.list())); }
    catch (AccessControlException e) {
      throw new AccessControlException(
                  "Directory permissions restricted."); }
  return listed; }}
/

CREATE OR REPLACE FUNCTION list_files(path VARCHAR2) RETURN FILE_LIST IS
LANGUAGE JAVA
NAME 'ListVirtualDirectory.getList(java.lang.String) return oracle.sql.ARRAY';
/


SELECT column_value FROM TABLE(list_files('C:\Data\loader'));