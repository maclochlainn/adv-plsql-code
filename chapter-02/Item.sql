/*
 * Item.sql
 * Chapter 2, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates a Java library that creates an Item object type.
 */

/* Enable logical comparison operators in Java. */
SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

/* Drop the Java source. */
DROP JAVA SOURCE "ItemSt";
DROP JAVA SOURCE "Item"; 

/* Create the Java source file for item instance. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "Item" AS

// Java library imports.
import java.sql.*;
import java.io.*;
import oracle.sql.*;
import oracle.jdbc.*;
import oracle.oracore.*;
import oracle.jdbc2.*;
import java.math.*;

public class Item implements SQLData
{
  // Implement the attributes and operations for this type.
  private BigDecimal id;
  private String title;
  private String subtitle;
  private String rating;
  private String ratingAgency;
  private Date releaseDate;

  // A getter for the rating attribute.
  public String getRating() {
    return this.rating; }

  // A getter for the class instance name.
  public String getName() {
    return this.getClass().getName(); }

  // A getter for the rating attribute.
  public String getUserName() {
    // Declare local variables.
    String userName = new String();
    String query = "SELECT user FROM dual";

    try {
      // Declare an Oracle connection.
      OracleConnectionWrapper conn =
        (oracle.jdbc.OracleConnectionWrapper)
          DriverManager.getConnection("jdbc:default:connection:");

      // Prepare and execute a statement.
      java.sql.PreparedStatement ps = conn.prepareStatement(query);
      ResultSet rs = ps.executeQuery();

      // Read the result set.
      while (rs.next())
        userName = rs.getString(1); }
      catch (SQLException e) {}
        // Return a user name.
        return userName; }

  // A setter for this object.
  public void setItem(Struct item) throws java.sql.SQLException {

    // Get the attributes of the Item object.
    Object[] attributes = (Object[]) item.getAttributes();

    // Assign Item instance variables.
    this.id = (BigDecimal) attributes[0];
    this.title = (String) attributes[1];
    this.subtitle = (String) attributes[2];
    this.rating = (String) attributes[3];
    this.ratingAgency = (String) attributes[4];
    this.releaseDate = 
      new Date(((Timestamp) attributes[5]).getTime()); }

  // A setter for the rating attribute.
  public void setRating(String rating) {
    this.rating = rating; }

  // Declare an instance toString method.
  public String toString() {
    return "ID #    [" + this.id + "]\n" +
           "Title   [" + this.title + ": " + this.subtitle +"]\n" +
           "Rating  [" + this.ratingAgency +
                   ":" + this.rating + "]\n" +
           "Release [" + this.releaseDate + "]\n"; }

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

  // Returns the interface required variable value.
  public String getSQLTypeName() throws SQLException  {
    return this.sql_type; }

  // Reads the stream from the Oracle session.
  public void readSQL(SQLInput stream, String typeName)
    throws SQLException {
    // Map instance variables.
    this.sql_type = typeName;
    this.id = stream.readBigDecimal();
    this.title = stream.readString();
    this.subtitle = stream.readString();
    this.rating = stream.readString();
    this.ratingAgency = stream.readString();
    this.releaseDate = stream.readDate(); }

  // Writes the stream to the Oracle session.
  public void writeSQL(SQLOutput stream) throws SQLException {
    // Map instance variables.
    stream.writeBigDecimal(this.id);
    stream.writeString(this.title);
    stream.writeString(this.subtitle);
    stream.writeString(this.rating);
    stream.writeString(this.ratingAgency);
    stream.writeDate(this.releaseDate); }

  /*
  || --------------------------------------------------------
  ||  End Implementation of SQLData interface.
  */
}
/

SHOW ERRORS

/* Create the Java source file for copying files. */
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "ItemSt" AS
  // Java library imports.
import java.sql.*;
import java.io.*;
import oracle.sql.*;
import oracle.jdbc.*;
import oracle.oracore.*;
import oracle.jdbc2.*;
import java.math.*;

public class ItemSt extends Item implements SQLData
{
  // Implement the attributes and operations for this type.
  private String bluray;

  // A getter for the rating attribute.
  public String getBluray() {
    return this.bluray; }

  // A setter for the rating attribute.
  public void setBluray(String bluray) {
    this.bluray = new String(bluray); }

  // A setter for this object.
  public void setItem(Struct item) throws java.sql.SQLException {

    // Assign Item instance variables.
    super.setItem(item);

    // Get the attributes of the Item object.
    Object[] attributes = (Object[]) item.getAttributes();

    // Assign the subtype element.
    this.bluray = (String) attributes[6]; }

  // Declare an instance toString method.
  public String toString() {
    return super.toString() +
           "Blu-ray [" + this.bluray +"]\n"; }

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

  // Reads the stream from the Oracle session.
  public void readSQL(SQLInput stream, String typeName)
    throws SQLException {
    // Call to parent class.
    super.readSQL(stream, typeName);

    // Map instance variables.
    sql_type = typeName;
    bluray = stream.readString(); }

  // Writes the stream to the Oracle session.
  public void writeSQL(SQLOutput stream) throws SQLException {
    // Call to parent class.
    super.writeSQL(stream);

    // Map instance variables.
    stream.writeString(bluray); }

  /*
  || --------------------------------------------------------
  ||  End Implementation of SQLData interface.
  */
}
/

SHOW ERRORS

/* Drop table of item structures. */
DROP TABLE item_struct;

/* Drop Item_Tab type. */
DROP TYPE item_tab;

/* Drop Item type. */
DROP TYPE item_obj FORCE;

/* Create Item type. */
CREATE OR REPLACE TYPE item_obj IS OBJECT
( id             NUMBER
, title          VARCHAR2(60)
, subtitle       VARCHAR2(60)
, rating         VARCHAR2(8)
, rating_agency  VARCHAR2(4)
, release_date   DATE
, MEMBER FUNCTION get_rating RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'Item.getRating() return java.lang.String'
, MEMBER FUNCTION get_name RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'Item.getName() return java.lang.String'
, MEMBER FUNCTION get_sql_type RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'Item.getSQLTypeName() return java.lang.String'
, MEMBER FUNCTION get_user_name RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'Item.getUserName() return java.lang.String'
, MEMBER PROCEDURE set_item (item  ITEM_OBJ)
  AS LANGUAGE JAVA
  NAME 'Item.setItem(java.sql.Struct)'
, MEMBER PROCEDURE set_rating (rating  VARCHAR2)
  AS LANGUAGE JAVA
  NAME 'Item.setRating(java.lang.String)'
, MEMBER FUNCTION to_string RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'Item.toString() return java.lang.String')
INSTANTIABLE NOT FINAL;
/

SHOW ERRORS

/* Create Item subtype. */
CREATE OR REPLACE TYPE item_obj_st UNDER item_obj
( bluray         VARCHAR2(20)
, MEMBER FUNCTION get_bluray RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'ItemSt.getBluray() return java.lang.String'
, MEMBER PROCEDURE set_bluray (bluray  VARCHAR2)
  AS LANGUAGE JAVA
  NAME 'ItemSt.setBluray(java.lang.String)'
, MEMBER PROCEDURE set_item (item  ITEM_OBJ_ST)
  AS LANGUAGE JAVA
  NAME 'ItemSt.setItem(java.sql.Struct)'
, OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'ItemSt.toString() return java.lang.String')
INSTANTIABLE NOT FINAL;
/

SHOW ERRORS

/* Create table of item structures. */
CREATE TABLE item_struct
( item_struct_id  NUMBER
, item_struct     ITEM_OBJ);

/* Drop sequence for item_structure table. */
DROP SEQUENCE item_struct_s;

/* Create sequence for item structure table. */
CREATE SEQUENCE item_struct_s;

/* Create a table of item_obj type. */
CREATE TYPE item_tab IS TABLE OF item_obj;
/

/* Insert super type row. */
INSERT INTO item_struct VALUES
( item_struct_s.NEXTVAL
, item_obj( 1
          ,'The Hobbit'
          ,'An Unexpected Journey'
          ,'PG-13'
          ,'MPAA'
          ,'14-DEC-2012'));

/* Insert super type row. */
INSERT INTO item_struct VALUES
( item_struct_s.NEXTVAL
, item_obj( 2
          ,'The Hobbit'
          ,'The Desolation of Smaug'
          ,'PG-13'
          ,'MPAA'
          ,'13-DEC-2013'));

/* Insert super type row. */
INSERT
INTO   item_struct
VALUES
( item_struct_s.NEXTVAL
, item_obj_st( 3
             ,'The Hobbit'
             ,'The Battle of the Five Armies'
             ,'PG-13'
             ,'MPAA'
             ,'17-DEC-2014'
             ,'Sony Blu-ray'));

/* Query item_struct table. */
COLUMN struct_id     FORMAT 9999 HEADING "Struct|ID"
COLUMN item_id       FORMAT 9999 HEADING "Item|ID"
COLUMN title         FORMAT A36  HEADING "Title"
COLUMN rating        FORMAT A6   HEADING "Rating"
COLUMN rating_agency FORMAT A6   HEADING "Rating|Agency"
COLUMN release_date  FORMAT A9   HEADING "Release|Date"
SELECT   id AS struct_id
,        id AS item_id
,        title||': '||subtitle AS title
,        rating
,        rating_agency
,        release_date
FROM   item_struct
CROSS JOIN
TABLE(
  SELECT CAST(COLLECT(item_struct) AS item_tab)
  FROM   dual);

/* Test anonymous block. */
DECLARE
  /* Create an object type instance. */
  lv_item  ITEM_OBJ :=
    item_obj( 1
            ,'The Hobbit'
            ,'An Unexpected Journey'
            ,'PG-13'
            ,'MPAA'
            ,'14-DEC-2012');
BEGIN
  /* Print the getter rating result. */
  dbms_output.put_line(
    '---------------------------------------------');
  dbms_output.put_line(
    'Rating Value: ['||lv_item.get_rating()||']');

  /* Set the value of the rating. */
  lv_item.set_rating('PG');
  
  /* Print the getter rating result. */
  dbms_output.put_line(
    'Rating Value: ['||lv_item.get_rating()||']');
  dbms_output.put_line(
    '---------------------------------------------');
 
  /* Print user name and sql_type value. */
  dbms_output.put_line(
    'User Name:    ['||lv_item.get_user_name()||']');
  dbms_output.put_line(
    'Class Name:   ['||lv_item.get_name()||']');
  dbms_output.put_line(
    'Object Name:  ['||lv_item.get_sql_type()||']');
 
  /* Print the toString value. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item.to_string());
  dbms_output.put_line(
    '---------------------------------------------');
END;
/

/* Test anonymous block. */
DECLARE
  /* Create an object type instance. */
  lv_item  ITEM_OBJ :=
    item_obj( 1
            ,'The Hobbit'
            ,'An Unexpected Journey'
            ,'PG-13'
            ,'MPAA'
            ,'14-DEC-2012');

  /* Create an object subtype instance. */
  lv_item_st ITEM_OBJ_ST :=
    item_obj_st( 3
               ,'The Hobbit'
               ,'The Battle of the Five Armies'
               ,'PG-13'
               ,'MPAA'
               ,'17-DEC-2014'
               ,'Sony Blu-ray');
BEGIN
  /* Print the getter rating result. */
  dbms_output.put_line(
    '---------------------------------------------');
  dbms_output.put_line(
    'Rating Value: ['||lv_item.get_rating()||']');

  /* Set the value of the rating. */
  lv_item.set_rating('PG');

  /* Print the getter rating result. */
  dbms_output.put_line(
    'Rating Value: ['||lv_item.get_rating()||']');
  dbms_output.put_line(
    '---------------------------------------------');

  /* Print user name & sql_type value. */
  dbms_output.put_line(
    'User Name:    ['||lv_item.get_user_name()||']');
  dbms_output.put_line(
    'Class Name:   ['||lv_item.get_name()||']');
  dbms_output.put_line(
    'Object Name:  ['||lv_item.get_sql_type()||']');

  /* Print the toString value. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item.to_string());

  /* Set the value of the rating. */
  lv_item.set_item(
    item_obj( 2
            ,'The Hobbit'
            ,'The Desolation of Smaug'
            ,'PG-13'
            ,'MPAA'
            ,'13-DEC-2013'));

  /* Print the toString value. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item.to_string());
  dbms_output.put_line(
    '---------------------------------------------');

  /* Print the user name and sql_type value. */
  dbms_output.put_line(
    'User Name:    ['||lv_item_st.get_user_name()||']');
  dbms_output.put_line(
    'Class Name:   ['||lv_item_st.get_name()||']');
  dbms_output.put_line(
    'Object Name:  ['||lv_item_st.get_sql_type()||']');

  /* Print the toString value. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item_st.to_string());
  dbms_output.put_line(
    '---------------------------------------------');

  /* Set the rating and bluray values. */
  lv_item_st.set_rating('PG');
  lv_item_st.set_bluray('Hitachi Blu-ray');

  /* Print the toString value. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item_st.to_string());
  dbms_output.put_line(
    '---------------------------------------------');
END;
/
/

/* Print a subtype. */
DECLARE
  lv_item  ITEM_OBJ :=
    item_obj( 3
            ,'The Hobbit'
            ,'The Battle of the Five Armies'
            ,'PG-13'
            ,'MPAA'
            ,TO_DATE('17-DEC-2014'));
BEGIN
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item.to_string);
  dbms_output.put_line(
    '---------------------------------------------');
END;
/

/* */
CREATE OR REPLACE FUNCTION get_item
( id             NUMBER
, title          VARCHAR2
, subtitle       VARCHAR2
, rating         VARCHAR2
, rating_agency  VARCHAR2
, release_date   DATE
, bluray         VARCHAR2 DEFAULT NULL )
RETURN item_obj IS
  /* Declare a local variable. */
  lv_item  ITEM_OBJ;
BEGIN
  /* Check for the subtype attribute. */
  IF bluray IS NULL THEN
    lv_item := item_obj( id
                       , title
                       , subtitle
                       , rating
                       , rating_agency
                       , release_date);
  ELSE
    lv_item := item_obj_st( id
                          , title
                          , subtitle
                          , rating
                          , rating_agency
                          , release_date
                          , bluray);
  END IF;

  /* Return a type. */
  RETURN lv_item;
END;
/

DECLARE
  /* Declare a generalized object type. */
  lv_item_obj  ITEM_OBJ;
BEGIN
  /* Assign generalization. */
  lv_item_obj := get_item(
                     id => 1
                   , title => 'The Hobbit'
                   , subtitle => 'An Unexpected Journey'
                   , rating => 'PG-13'
                   , rating_agency => 'MPAA'
                   , release_date => '14-DEC-2014');

  /* Print the contents of the item_obj. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item_obj.to_string());
  dbms_output.put_line(
    '---------------------------------------------');
END;
/

DECLARE
  /* Declare a generalized object type. */
  lv_item_obj  ITEM_OBJ;
BEGIN
  /* Assign generalization. */
  lv_item_obj := get_item(
                     id => 3
                   , title => 'The Hobbit'
                   , subtitle => 'The Battle of the Five Armies'
                   , rating => 'PG-13'
                   , rating_agency => 'MPAA'
                   , release_date => '17-DEC-2014'
                   , bluray => 'Sony Blu-ray');

  /* Print the contents of the item_obj. */
  dbms_output.put_line(
    '---------------------------------------------');
  parse_rows(lv_item_obj.to_string());
  dbms_output.put_line(
    '---------------------------------------------');
END;
/

DECLARE
  /* Declare a generalized object type. */
  lv_item_tab  ITEM_TAB := item_tab();
BEGIN
  /* Assign an object to a generalization. */
  lv_item_tab.EXTEND;
  lv_item_tab(lv_item_tab.COUNT) :=
    get_item(
        id => 2
      , title => 'The Hobbit'
      , subtitle => 'The Desolation of Smaug'
      , rating => 'PG-13'
      , rating_agency => 'MPAA'
      , release_date => '13-DEC-2013');

  /* Assign an object to a specialization. */
  lv_item_tab.EXTEND;
  lv_item_tab(lv_item_tab.COUNT) :=
    get_item(
        id => 3
      , title => 'The Hobbit'
      , subtitle => 'The Battle of the Five Armies'
      , rating => 'PG-13'
      , rating_agency => 'MPAA'
      , release_date => '17-DEC-2014'
      , bluray => 'Sony Blu-ray');

  /* Print header line. */
  dbms_output.put_line(
    '---------------------------------------------');

  /* Print items in collection. */
  FOR i IN 1..lv_item_tab.COUNT LOOP
    /* Print the contents of the item_obj. */
    parse_rows(lv_item_tab(i).to_string());
    dbms_output.put_line(
      '---------------------------------------------');
  END LOOP;
END;
/

