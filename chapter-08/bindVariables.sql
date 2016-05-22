/*  ****************************************************************************
--------------------------------------------------------------------------------
FILENAME:   ch_08_utl_sec.sql
AUTHOR(S):  John M Harper, Michael McLaughlin, Brandon Hawkes, Tyler Hawkes
COPYRIGHT:  (c) 2014 McLaughlin Software Development LLC.
                McGraw-Hill use is granted for educational purposes. Commercial
                use is granted by written consent. Please remit requests to:
                  + john.maurice.harper@mclaughlinsoftware.com
                  + michael.mclaughlin@mclaughlinsoftware.com
                  + tyler.hawkes@mclaughlinsoftware.com
                  + brandon.hawkes@mclaughlinsoftware.com
--------------------------------------------------------------------------------
CHANGE_RECORD
================================================================================
DATE        INITIALS    REASON
--------------------------------------------------------------------------------
05/22/2014  JMH         To show users how bind variables work.
****************************************************************************  */
VARIABLE user_id NUMBER;
EXEC :user_id := 1;
SELECT system_user_name FROM dbsec.system_user WHERE system_user_id = :user_id;
 
 
SET SERVEROUTPUT ON
DECLARE
  lv_user_id NUMBER := 1;
  lv_value   VARCHAR2(50);
BEGIN
  EXECUTE IMMEDIATE ' select system_user_name from dbsec.system_user where '||
                    ' system_user_id = :1 '
                    INTO lv_value
                    USING lv_user_id;
  DBMS_OUTPUT.PUT_LINE ( lv_value );
END;
/