/*
 * HelloWorld4.java
 * Chapter 15, Oracle Database 11g PL/SQL Programming
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script builds an internal or server-side Java class file
 * that is instantiable and queries the local instance for data.
 */

// Oracle class imports.
import java.sql.*;
import java.io.*;
import oracle.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.oracore.*;

// Class definition.
public class HelloWorld4 implements SQLData {
  // Define or declare SQLData components.
  private String className = new String("HelloWorld4.class");
  private String instanceName;
  private String qualifiedName;
  private String sql_type;

  public HelloWorld4() {
    String user = new String();

    try {
      user = getUserName(); }
    catch (Exception e) {}

    qualifiedName = user + "." + className; }

  public String getQualifiedName() throws SQLException {
    return this.qualifiedName + "." + instanceName; }

  public String getSQLTypeName() throws SQLException {
    return sql_type; }

  public String getUserName() throws SQLException {
    String userName = new String();
    String getDatabaseSQL = "SELECT user FROM dual";

    // Declare an Oracle connection.
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // Declare prepared statement, run query and read results.
    PreparedStatement ps = conn.prepareStatement(getDatabaseSQL);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
      userName = rs.getString(1); }

    return userName; }

  // Implements readSQL() method from the SQLData interface.
  public void readSQL(SQLInput stream, String typeName) throws SQLException {
    // Define sql_type to read input and signal overloading signatures.
    sql_type = typeName;

    // Pass values into the class.
    instanceName = stream.readString(); }

  // Implements readSQL() method from the SQLData interface.
  public void writeSQL(SQLOutput stream) throws SQLException {
    // You pass a value back by using a stream function.
    // stream.writeString('variable_name'); }

}
