/*
 * HelloWorld3.java
 * Chapter 1, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script tests Java and the Oracle JDBC.
 */

// Oracle class imports.
import java.sql.*;
import oracle.jdbc.driver.*;

// Class definition.
public class HelloWorld3 {

  public static void doDML(String statement
                          ,String name) throws SQLException {
    // Declare an Oracle connection.
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // Declare prepared statement, run query and read results.
    PreparedStatement ps = conn.prepareStatement(statement);
    ps.setString(1,name);
    ps.execute(); }

  public static String doDQL(String statement) throws SQLException {
    // Define and initialize a local return variable.
    String result = new String();

    // Declare an Oracle connection.
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // Declare prepared statement, run query and read results.
    PreparedStatement ps = conn.prepareStatement(statement);
    ResultSet rs = ps.executeQuery();
    while (rs.next())
      result = rs.getString(1);

    return result; }
}
