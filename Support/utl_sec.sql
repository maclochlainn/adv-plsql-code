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
05/22/2014  JMH         To show users how our proxy-access method works. We have
                        refined this method much more than is shown.
****************************************************************************  */
DROP USER dbsec cascade;
CREATE USER dbsec IDENTIFIED BY fioora12;
GRANT  ALTER USER
    ,  CREATE PROCEDURE
    ,  CREATE ROLE
    ,  CREATE SESSION
    ,  INHERIT ANY PRIVILEGES
    ,  SELECT ANY DICTIONARY
    ,  CREATE ANY JOB
    ,  ALTER SYSTEM
   TO  dbsec;

GRANT EXECUTE ON DBMS_CRYPTO TO dbsec;

ALTER USER dbsec QUOTA UNLIMITED ON users;

CREATE TABLE dbsec.contact
( contact_id        INTEGER       CONSTRAINT pk_contact   PRIMARY KEY
, member_id         INTEGER       CONSTRAINT nn_contact_1 NOT NULL
, contact_type      INTEGER       CONSTRAINT nn_contact_2 NOT NULL
, last_name         VARCHAR(20)   CONSTRAINT nn_contact_3 NOT NULL
, first_name        VARCHAR(20)   CONSTRAINT nn_contact_4 NOT NULL
, middle_name       VARCHAR(20)
, favorite_color    VARCHAR(20)   CONSTRAINT nn_contact_9 NOT NULL
, favorite_food     VARCHAR(20)   CONSTRAINT nn_contact_10 NOT NULL
, created_by        INTEGER       CONSTRAINT nn_contact_5 NOT NULL
, created_dt        DATE          CONSTRAINT nn_contact_6 NOT NULL
, updated_by        INTEGER       CONSTRAINT nn_contact_7 NOT NULL
, updated_dt        DATE          CONSTRAINT nn_contact_8 NOT NULL
);
sa
CREATE TABLE dbsec.system_user
( system_user_id              INTEGER       CONSTRAINT pk_system_user   PRIMARY KEY
, contact_id                  INTEGER
, system_user_name            VARCHAR(20)   CONSTRAINT nn_system_user_1 NOT NULL
, system_user_group_id        INTEGER       CONSTRAINT nn_system_user_2 NOT NULL
, system_user_type            INTEGER       CONSTRAINT nn_system_user_3 NOT NULL
, system_password             VARCHAR(250)  CONSTRAINT nn_system_user_4 NOT NULL
, created_by                  INTEGER       CONSTRAINT nn_system_user_5 NOT NULL
, created_dt                  DATE          CONSTRAINT nn_system_user_6 NOT NULL
, updated_by                  INTEGER       CONSTRAINT nn_system_user_7 NOT NULL
, updated_dt                  DATE          CONSTRAINT nn_system_user_8 NOT NULL
);

CREATE TABLE dbsec.proxy_rule_type
(
  proxy_rule_type_id          INTEGER       CONSTRAINT pk_proxy_rule_type PRIMARY KEY
, proxy_rule_description      VARCHAR(50)   CONSTRAINT nn_proxy_rule_type_1 NOT NULL
, created_by                  INTEGER       CONSTRAINT nn_proxy_rule_type_2 NOT NULL
, created_dt                  DATE          CONSTRAINT nn_proxy_rule_type_3 NOT NULL
, updated_by                  INTEGER       CONSTRAINT nn_proxy_rule_type_4 NOT NULL
, updated_dt                  DATE          CONSTRAINT nn_proxy_rule_type_5 NOT NULL
);

CREATE TABLE dbsec.proxy_rule
(
  proxy_rule_id               INTEGER       CONSTRAINT pk_proxy_rule    PRIMARY KEY
, proxy_rule_type_id          INTEGER       CONSTRAINT nn_proxy_rule_1  NOT NULL
, system_user_id              INTEGER       CONSTRAINT nn_proxy_rule_2  NOT NULL
, value                       VARCHAR2(50)  CONSTRAINT nn_proxy_rule_3  NOT NULL
, created_by                  INTEGER       CONSTRAINT nn_proxy_rule_4  NOT NULL
, created_dt                  DATE          CONSTRAINT nn_proxy_rule_5  NOT NULL
, updated_by                  INTEGER       CONSTRAINT nn_proxy_rule_6  NOT NULL
, updated_dt                  DATE          CONSTRAINT nn_proxy_rule_7  NOT NULL
);

CREATE TABLE dbsec.logon
(
  sid         NUMBER
, serial#     NUMBER
, db_user     VARCHAR2(50)
, proxy_user  VARCHAR2(50)
, os_user     VARCHAR2(50)
, ip_address  VARCHAR2(50)
, message     VARCHAR2(50)
, update_dt   DATE
);

ALTER TABLE dbsec.proxy_rule
  ADD CONSTRAINT fk_proxy_rule_1
  FOREIGN KEY ( proxy_rule_type_id )
  REFERENCES dbsec.proxy_rule_type ( proxy_rule_type_id )
  ADD CONSTRAINT fk_proxy_rule_2
  FOREIGN KEY ( system_user_id )
  REFERENCES dbsec.system_user ( system_user_id );

ALTER TABLE dbsec.system_user
  ADD CONSTRAINT fk_system_user_1
  FOREIGN KEY ( contact_id )
  REFERENCES dbsec.contact ( contact_id );
--------------------------------------------------------------------------------
-- package spec
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE dbsec.utl_sec
AS
  FUNCTION hashed
  (
    pi_username   IN VARCHAR2
  , pi_password   IN VARCHAR2
  , pi_phrase1    IN VARCHAR2   -- secret answer 1
  , pi_phrase2    IN VARCHAR2   -- secret answer 2
  )
  RETURN VARCHAR2;

  PROCEDURE grant_proxy
  (
    pi_user       IN VARCHAR2
  , pi_target     IN VARCHAR2
  , pi_expiry_dt  IN DATE
  );

  PROCEDURE revoke_proxy
  (
    pi_user       IN VARCHAR2
  , pi_target     IN VARCHAR2
  );

  PROCEDURE kill_session
  (
    pi_sid        IN NUMBER
  , pi_serial#    IN NUMBER
  );
end utl_sec;
/

CREATE OR REPLACE PACKAGE BODY dbsec.utl_sec
AS
--------------------------------------------------------------------------------
  FUNCTION hashed
  (
    pi_username   IN VARCHAR2
  , pi_password   IN VARCHAR2
  , pi_phrase1    IN VARCHAR2   -- secret answer 1
  , pi_phrase2    IN VARCHAR2   -- secret answer 2
  )
  RETURN VARCHAR2
  IS
    lv_salted VARCHAR2(250);
  BEGIN
    lv_salted :=
    UPPER (
      pi_username ||
      pi_phrase1  ||
      pi_password ||
      pi_phrase2
    );
    RETURN DBMS_CRYPTO.HASH ( UTL_RAW.CAST_TO_RAW ( lv_salted ), DBMS_CRYPTO.HASH_SH512 );
    RETURN lv_salted;
  END hashed;
--------------------------------------------------------------------------------
  PROCEDURE grant_proxy
  (
    pi_user       IN VARCHAR2
  , pi_target     IN VARCHAR2
  , pi_expiry_dt  IN DATE
  )
  IS
    lv_security_check VARCHAR2(30);
    lv_job            VARCHAR2(30);
    lv_sql            VARCHAR2(100);
  BEGIN
    lv_security_check := DBMS_ASSERT.SIMPLE_SQL_NAME ( pi_user   );
    lv_security_check := DBMS_ASSERT.SIMPLE_SQL_NAME ( pi_target );

    lv_job := DBMS_SCHEDULER.GENERATE_JOB_NAME ( 'proxy' );
    lv_sql := 'begin execute immediate ''alter user $1 grant connect through $2''; end; ';
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$1', pi_target );
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$2', pi_user   );
    DBMS_OUTPUT.PUT_LINE ( lv_sql );
    DBMS_SCHEDULER.CREATE_JOB
    (
      job_name    => lv_job
    , job_type    => 'PLSQL_BLOCK'
    , job_action  => lv_sql
    , enabled     => TRUE
    , auto_drop   => TRUE
    );

    lv_job := DBMS_SCHEDULER.GENERATE_JOB_NAME ( 'proxy' );
    lv_sql := 'begin execute immediate ''alter user $1 revoke connect through $2''; end; ';
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$1', pi_target );
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$2', pi_user   );

    DBMS_SCHEDULER.CREATE_JOB
    (
      job_name    => lv_job
    , job_type    => 'PLSQL_BLOCK'
    , job_action  => lv_sql
    , start_date  => pi_expiry_dt
    , enabled     => TRUE
    , auto_drop   => TRUE
    );
  END grant_proxy;
--------------------------------------------------------------------------------
  PROCEDURE revoke_proxy
  (
    pi_user       IN VARCHAR2
  , pi_target     IN VARCHAR2
  )
  IS
    lv_security_check VARCHAR2(30);
    lv_job            VARCHAR2(30);
    lv_sql            VARCHAR2(100);
  BEGIN
    lv_security_check := DBMS_ASSERT.SIMPLE_SQL_NAME ( pi_user   );
    lv_security_check := DBMS_ASSERT.SIMPLE_SQL_NAME ( pi_target );

    lv_job := DBMS_SCHEDULER.GENERATE_JOB_NAME ( 'proxy' );
    lv_sql := 'begin execute immediate ''alter user $1 revoke connect through $2''; end; ';
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$1', pi_target );
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$2', pi_user   );
    DBMS_OUTPUT.PUT_LINE ( lv_sql );
    DBMS_SCHEDULER.CREATE_JOB
    (
      job_name    => lv_job
    , job_type    => 'PLSQL_BLOCK'
    , job_action  => lv_sql
    , enabled     => TRUE
    , auto_drop   => TRUE
    );
  END revoke_proxy;
--------------------------------------------------------------------------------
  PROCEDURE kill_session
  (
    pi_sid        IN NUMBER
  , pi_serial#    IN NUMBER
  )
  AS
    lv_sql            VARCHAR2(4000);
    lv_job            VARCHAR2(30);
  BEGIN
    lv_job := DBMS_SCHEDULER.GENERATE_JOB_NAME ( 'kill' );
    lv_sql := ' begin execute immediate ''ALTER SYSTEM KILL SESSION ''''$1, $2'''' IMMEDIATE ''; end; ';
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$1', pi_sid     );
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$2', pi_serial# );

    DBMS_SCHEDULER.CREATE_JOB
    (
      job_name    => lv_job
    , job_type    => 'PLSQL_BLOCK'
    , job_action  => lv_sql
    , enabled     => TRUE
    , auto_drop   => TRUE
    );
  END kill_session;
END utl_sec;
/

INSERT INTO dbsec.proxy_rule_type VALUES ( 1, 'IP_RANGE'   , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule_type VALUES ( 2, 'OS_USERNAME', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule_type VALUES ( 3, 'DB_USERNAME', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule_type VALUES ( 4, 'TIME_START' , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule_type VALUES ( 5, 'TIME_END'   , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule_type VALUES ( 6, 'PROXY_USER' , 1, SYSDATE, 1, SYSDATE );

INSERT INTO dbsec.contact VALUES ( 10, 1, 1, 'Thornton', 'Billy', 'Bob', 'Red', 'Pizza', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.system_user VALUES  ( 1, 10, 'thorntonbb', 2, 1, dbsec.utl_sec.hashed ( 'thorntonbb', 'abc123', 'pizza', 'red' ), 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.contact VALUES  ( 11, 1, 1, 'Voight', 'Angelina', 'Jolie', 'Black', 'Cheerios', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.system_user VALUES  ( 2, 11, 'voightaj', 1, 1, dbsec.utl_sec.hashed ( 'voightaj', 'A Much B33t3r Pa$$word', 'cheerios', 'black' ), 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.contact VALUES  ( 12, 1, 1, 'Flinstone', 'Fred', 'Rocky', 'black', 'steak', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.system_user VALUES  ( 3, 11, 'fred', 1, 1, dbsec.utl_sec.hashed ( 'fred', 'A Much B33t3r Pa$$word', 'steak', 'black' ), 1, SYSDATE, 1, SYSDATE );

INSERT INTO dbsec.proxy_rule VALUES (  1, 1, 2, '10.118.194', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  3, 2, 2, 'oracle'    , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  4, 3, 2, 'proxy_dba' , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  5, 4, 2, '01:00:00'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  6, 5, 2, '23:59:59'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  7, 6, 2, 'voightaj'  , 1, SYSDATE, 1, SYSDATE );

INSERT INTO dbsec.proxy_rule VALUES (  8, 1, 3, '10.118.194', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES (  9, 2, 3, 'oracle'    , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 10, 3, 3, 'proxy_dba' , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 11, 4, 3, '01:00:00'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 12, 5, 3, '23:59:59'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 13, 6, 3, 'fred'      , 1, SYSDATE, 1, SYSDATE );

INSERT INTO dbsec.proxy_rule VALUES ( 14, 1, 1, '10.118.194', 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 15, 2, 1, 'oracle'    , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 16, 3, 1, 'proxy_dev' , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 17, 4, 1, '06:00:00'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 18, 5, 1, '10:00:00'  , 1, SYSDATE, 1, SYSDATE );
INSERT INTO dbsec.proxy_rule VALUES ( 19, 6, 1, 'thorntonbb', 1, SYSDATE, 1, SYSDATE );

DROP USER thorntonbb;
DROP USER voightaj;
DROP USER fred;
DROP USER proxy_dba;
DROP USER proxy_dev;

CREATE USER thorntonbb IDENTIFIED BY abc123;
CREATE USER voightaj IDENTIFIED BY abc123;
CREATE USER fred IDENTIFIED BY abc123;
CREATE USER proxy_dba IDENTIFIED BY "RXuHUkHFVLQ38EcJgmt6Jf3f5Wqe4k";
CREATE USER proxy_dev IDENTIFIED BY "VvQ86Vc8hu7JM5x6HXU3kx8suPnrx8";

GRANT CONNECT to thorntonbb;
GRANT CONNECT to voightaj;
GRANT CONNECT, DBA to proxy_DBA
GRANT CONNECT, RESOURCE to proxy_dev;

GRANT SELECT on dbsec.system_user to voightaj;
GRANT SELECT on dbsec.proxy_rule to voightaj;
GRANT SELECT on v_$session TO voightaj;
GRANT SELECT on v_$process TO voightaj;

GRANT SELECT on dbsec.system_user to fred;
GRANT SELECT on dbsec.proxy_rule to fred;
GRANT SELECT on v_$session TO fred;
GRANT SELECT on v_$process TO fred;

GRANT SELECT on dbsec.system_user to thorntonbb;
GRANT SELECT on dbsec.proxy_rule to thorntonbb;
GRANT SELECT on v_$session TO thorntonbb;
GRANT SELECT on v_$process TO thorntonbb;

BEGIN
  dbsec.utl_sec.grant_proxy ( 'VOIGHTAJ'  , 'PROXY_DBA', SYSDATE + 1 );
  dbsec.utl_sec.grant_proxy ( 'THORNTONBB', 'PROXY_DEV', SYSDATE + 1 );
  dbsec.utl_sec.grant_proxy ( 'FRED'      , 'PROXY_DBA', SYSDATE + 1 );
END;
/

select job_name, status from dba_scheduler_job_run_details where job_name like 'PROXY%';

COLUMN ip_address FORMAT A15
COLUMN db_user FORMAT A15
COLUMN os_user FORMAT A15
COLUMN proxy_user FORMAT A15
COLUMN db_sid FORMAT A15
COLUMN db_sessionid FORMAT A30

CREATE OR REPLACE TRIGGER user_authorization
AFTER LOGON ON DATABASE
DECLARE
  lv_sid        NUMBER;
  lv_serial#    NUMBER;
  lv_now        VARCHAR2(50);
  lv_time       DATE;
  lv_db_user    VARCHAR2(50);
  lv_os_user    VARCHAR2(50);
  lv_proxy_user VARCHAR2(50);
  lv_ip_address VARCHAR2(50);
  lv_counter1   NUMBER;
  lv_counter2   NUMBER;
BEGIN
  SELECT  COUNT(*)
    INTO  lv_counter1
    FROM  dbsec.system_user
   WHERE  system_user_name = lower ( sys_context ( 'userenv', 'current_user' ))
      OR  system_user_name = lower ( sys_context ( 'userenv', 'proxy_user' ));

  IF lv_counter1 > 0 THEN
--------------------------------------------------------------------------------
-- GET USERENV VALUES
--------------------------------------------------------------------------------
    SELECT  vs.sid
         ,  vs.serial#
         ,  lower ( vs.username ) db_user
         ,  to_char ( sysdate, 'HH24:MI:SS' ) update_dt
         ,  sys_context ( 'userenv', 'ip_address' ) ip_address
         ,  lower ( sys_context ( 'userenv', 'os_user' )) os_user
         ,  lower ( sys_context ( 'userenv', 'proxy_user' )) proxy_user
         ,  sysdate
      INTO  lv_sid
         ,  lv_serial#
         ,  lv_db_user
         ,  lv_now
         ,  lv_ip_address
         ,  lv_os_user
         ,  lv_proxy_user
         ,  lv_time
      FROM  sys.v$process vp
              INNER JOIN  sys.v$session vs ON vp.addr = vs.paddr
                     AND  vs.audsid = USERENV ( 'sessionid' )
                     AND  vs.sid = USERENV ( 'sid' );

    lv_ip_address := substr ( lv_ip_address, 1, instr ( lv_ip_address, '.', 1, 3 ) - 1 );
--------------------------------------------------------------------------------
-- EVALUATE AGAINST PROXY_RULE
--------------------------------------------------------------------------------
    WITH
    my_user AS
    (
      SELECT  system_user_name
           ,  proxy_rule_type_id
           ,  value
        FROM  dbsec.system_user su
                INNER JOIN  dbsec.proxy_rule pr
                        ON  su.system_user_id = pr.system_user_id
    ),
    pivot_point AS
    (
      SELECT  *
        FROM  my_user
       PIVOT  (
                MAX  ( value ) value
                FOR  ( proxy_rule_type_id )
                 IN  (
                       1 AS ip_range
                     , 2 AS os_user
                     , 3 AS db_user
                     , 4 AS tod_start
                     , 5 AS tod_end
                     , 6 AS proxy_user
                     )
              )
    )
    SELECT  COUNT(*)
      INTO  lv_counter2
      FROM  pivot_point pp
     WHERE  db_user_value = lv_db_user
       AND  lv_now BETWEEN tod_start_value AND tod_end_value
       AND  proxy_user_value = lv_proxy_user
       AND  os_user_value = lv_os_user
       AND  lv_ip_address LIKE ip_range_value;

    IF lv_proxy_user IS NOT NULL THEN
      IF lv_counter2 = 0 THEN
        INSERT INTO dbsec.logon values ( lv_sid, lv_serial#, lv_db_user, lv_proxy_user, lv_os_user, lv_ip_address, 'failure', lv_time );
        dbsec.utl_sec.revoke_proxy ( lv_proxy_user, lv_db_user );
        dbsec.utl_sec.kill_session ( lv_sid, lv_serial# );
      ELSE
        INSERT INTO dbsec.logon values ( lv_sid, lv_serial#, lv_db_user, lv_proxy_user, lv_os_user, lv_ip_address, 'success', lv_time );
      END IF;
    END IF;
  END IF;
  COMMIT;
END;
/

/*

SQL> conn voightaj[proxy_dba]/abc123@A002;
Connected.
SQL> show user
USER is "PROXY_DBA"

SQL> conn fred[proxy_dba]/abc123@A002;
Connected.
SQL> show user
USER is "PROXY_DBA"

SQL> conn thorntonbb[proxy_dev]/abc123@A002;
Connected.
SQL> show user
USER is "PROXY_DEV"

SQL> UPDATE dbsec.proxy_rule SET value = '10.10.10' WHERE proxy_rule_id = 14;

1 row updated.

SQL> commit;

Commit complete.


SELECT  vs.sid
     ,  vs.serial#
     ,  lower ( vs.username ) db_user
     ,  to_char ( sysdate, 'HH24:MI:SS' ) update_dt
     ,  sys_context ( 'userenv', 'ip_address' ) ip_address
     ,  lower ( sys_context ( 'userenv', 'os_user' )) os_user
     ,  lower ( sys_context ( 'userenv', 'proxy_user' )) proxy_user
     ,  sysdate
  FROM  v$process vp
          INNER JOIN  v$session vs ON vp.addr = vs.paddr
                 AND  vs.audsid = USERENV ( 'sessionid' )
                 AND  vs.sid = USERENV ( 'sid' )


