/*
 * GrantPrivileges.sql
 * Chapter 5, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script grants privileges to Java programs run by the
 * IMPORTER user. The IMPORTER user name is case sensitive in
 * when used inside the DBMS_JAVA package, and must be 
 * uppercase text.
 *
 * You have to run this before you open a session where you're
 * testing the External File Framework. Any active session 
 * must disconnect and reconnect before the permissions work
 * in any session.
 *
 * You need to switch the '\' with a '/' when running in Unix
 * or Linux.
 */

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&upload_dir'
                             ,'read,write');
END;
/

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&upload_dir\item_import.csv'
                             ,'read,write,delete');
END;
/

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&log_dir'
                             ,'read,write');
END;
/

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&log_dir\item_import.log'
                             ,'read,write,execute,delete');
END;
/

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&log_dir\item_import.dis'
                             ,'read,write,execute,delete');
END;
/

BEGIN
  DBMS_JAVA.GRANT_PERMISSION('IMPORTER'
                             ,'SYS:java.io.FilePermission'
                             ,'&log_dir\item_import.bad'
                             ,'read,write,execute,delete');
END;
/
