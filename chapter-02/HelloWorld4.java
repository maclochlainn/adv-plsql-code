/*
||  Program name: HelloWorld4.java
*/

// Oracle class imports.
import java.sql.*;
import java.io.*;
import oracle.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.oracore.*;
import java.math.*;

// Class definition.
public class HelloWorld4 implements SQLData {
  // Declare class instance variable.
  private String whom;

  // Declare getter for SQL data type value.
  public String getSQLTypeName() throws SQLException {
    // Returns the UDT map value or database object name.
    return sql_type;  }

  /*  Implement SQLData interface.
  || --------------------------------------------------------
  ||  Required interface components:
  ||  ==============================
  ||   1. String sql_type instance variable.
  ||   2. getSQLTypeName() method returns the sql_type value.
  ||   3. readSQL() method to read from the Oracle session.
  ||   4. writeSQL() method to write to the Oracle session.
  */

  // Required interface variable.
  private String sql_type;

  // Implements readSQL() method from the SQLData interface.
  public void readSQL(SQLInput stream, String typeName) throws SQLException {
    this.sql_type = typeName;
    this.whom = stream.readString(); }

  // Implements writeSQL() method from the SQLData interface.
  public void writeSQL(SQLOutput stream) throws SQLException {
    stream.writeString(whom); }

  // Declare an instance toString method.
  public String toString() {
    String datatype = null;

    try {
      datatype = getSQLTypeName(); }
    catch (SQLException e) {}

    // Return message.
    return datatype + " says hello [" + this.whom + "]!\n"; }
}