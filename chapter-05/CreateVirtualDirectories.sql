/*
 * CreateVirtualDirectories.sql
 * Chapter 5, Oracle Database 12c PL/SQL Advanced Programming Techniques
 * by Michael McLaughlin & John Harper
 *
 * ALERTS:
 *
 * This script creates directories and grants privileges to 
 * the directories. It takes two inputs: one for the upload
 * directory and another for the log directory.
 */

CREATE OR REPLACE DIRECTORY upload AS '&upload_dir';
/

CREATE OR REPLACE DIRECTORY upload AS '&log_dir';
/

GRANT READ, WRITE ON DIRECTORY '&upload_dir';

GRANT READ, WRIRE ON DIRECTORY '&log_dir';
