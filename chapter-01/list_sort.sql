/*
 * list_sort.sql
 * Chapter 1, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script tests Java with ADT collections and uses the JDBC library.
 */

CREATE OR REPLACE
  TYPE stringlist IS TABLE OF VARCHAR2(4000);
/

CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "SortList" AS
 
  // Import required classes.
  import java.io.*;
  import java.security.AccessControlException;
  import java.sql.*;
  import java.util.Arrays;
  import java.util.Comparator;
  import oracle.sql.driver.*;
  import oracle.sql.ArrayDescriptor;
  import oracle.sql.ARRAY;
 
  // Define class.
  public class Sorting {
    public static ARRAY sortTitleCaseList(oracle.sql.ARRAY list)
      throws SQLException, AccessControlException {
 
    // Convert Oracle data type to Java data type.
    String[] unsorted = (String[])list.getArray();
 
    // Sort elements.
    Arrays.sort(unsorted, new Comparator<String>() {
      public int compare(String s1, String s2) {
 
      // Declare a sorting key integer for the return value.
      int sortKey;
 
      // Check if lowercase words match and sort on first letter only.
      if (s1.toLowerCase().compareTo(s2.toLowerCase()) == 0)
         sortKey = s1.substring(0,1).compareTo(s2.substring(0,1));
      else
        sortKey = s1.toLowerCase().compareTo(s2.toLowerCase());
 
      // Return the sorting index.
      return sortKey; }});
 
      // Define a connection (this is for Oracle 11g).
      Connection conn =
        DriverManager.getConnection("jdbc:default:connection:");
 
      // Declare a mapping to the schema-level SQL collection type.
      ArrayDescriptor arrayDescriptor =
        new ArrayDescriptor("STRINGLIST",conn);
 
      // Translate the Java String{} to the Oracle SQL collection type.
      ARRAY sorted = 
        new ARRAY(arrayDescriptor,conn,((Object[])unsorted));
 
      // Return the sorted list.
      return sorted; }
  }
/

CREATE OR REPLACE
  FUNCTION sortTitleCaseList(list STRINGLIST) RETURN STRINGLIST IS
  LANGUAGE JAVA NAME
  'Sorting.sortTitleCaseList(oracle.sql.ARRAY) return oracle.sql.ARRAY';
/

DECLARE
  /* Declare a counter. */
  lv_counter  NUMBER := 1;
  /* Declare a unordered collection of fruit. */
  lv_list  STRINGLIST := stringlist('Oranges'
                                   ,'apples'
                                   ,'Apples'
                                   ,'Bananas'
                                   ,'Apricots'
                                   ,'apricots');
  BEGIN
    /* Read through an element list. */
    FOR i IN (SELECT column_value
              FROM   TABLE(sortTitleCaseList(lv_list))) LOOP
      dbms_output.put_line('['||lv_counter||']['||i.column_value||']');
      lv_counter := lv_counter + 1;
    END LOOP;
END;
/

 