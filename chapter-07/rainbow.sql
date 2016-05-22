CREATE DIRECTORY security AS '/u01/app/oracle/admin/T12101/pdb1/sec';
DROP TABLE password_dictionary CASCADE CONSTRAINTS PURGE;
CREATE TABLE password_dictionary
(
  password_id     INTEGER GENERATED ALWAYS AS IDENTITY
, password_fwd    VARCHAR2(30)
, password_rev    VARCHAR2(30)
, password_rnk    INTEGER
, password_cnt    INTEGER
, created_by      INTEGER
, created_dt      DATE
, updated_by      INTEGER
, updated_dt      DATE
);
 
DROP TABLE PASSWORD_DICTIONARY_STAGE;
CREATE TABLE PASSWORD_DICTIONARY_STAGE
(
  password  VARCHAR2(50)
, frequency VARCHAR2(50)
)
ORGANIZATION EXTERNAL
(
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY security
  LOCATION
  (
 'tenThousandPasswords.dat'
  )
)
REJECT LIMIT UNLIMITED;
 
INSERT  /*+ append */
  INTO  password_dictionary
     (
       password_fwd
     , password_rev
     , password_cnt
     , password_rnk
     , created_by
     , created_dt
     , updated_by
     , updated_dt
     )
WITH
passwords AS
(
SELECT password_fwd
  , password_rev
  , TO_NUMBER ( TRIM ( REPLACE ( password_cnt, CHR(13), ' ' ))) password_cnt
  , created_by
  , created_dt
  , updated_by
  , updated_dt
  FROM pwd_stg
)
SELECT  p.password_fwd
  ,  p.password_rev
  ,  p.password_cnt
  ,  RANK () OVER ( ORDER BY password_cnt DESC ) password_rnk
  ,  p.created_by
  ,  p.created_dt
  ,  p.updated_by
  ,  p.updated_dt
  FROM  passwords p
;
DROP TABLE password_dictionary_stage;
 
CREATE OR REPLACE FUNCTION ora12c_verify_function
(
  username      varchar2
, password      varchar2
, old_password  varchar2
)
RETURN BOOLEAN IS
  lv_un_fwd VARCHAR2(30);
  lv_un_rev VARCHAR2(30);
  lv_hn_fwd VARCHAR2(64);
  lv_hn_rev VARCHAR2(64);
  lv_in_fwd VARCHAR2(30);
  lv_in_rev VARCHAR2(30);
  lv_dcount NUMBER;
BEGIN
-----------------------------------------------------------------------------
-- the reverse function is much more efficient than looping
-----------------------------------------------------------------------------
  SELECT  username
    ,  REVERSE ( username )
    ,  host_name
    ,  REVERSE ( host_name )
    ,  instance_name
    ,  REVERSE ( instance_name )
 INTO  lv_un_fwd
    ,  lv_un_rev
    ,  lv_hn_fwd
    ,  lv_hn_rev
    ,  lv_in_fwd
    ,  lv_in_rev
 FROM  v$instance vi;
-----------------------------------------------------------------------------
-- get all of the string comparisons out of the way first
-----------------------------------------------------------------------------
  IF    LENGTH ( password ) < 8
  THEN  RAISE_APPLICATION_ERROR ( -20001, 'password must be more than 8 characters' );
  ELSIF LENGTH ( password ) > 30
  THEN  RAISE_APPLICATION_ERROR ( -20002, 'password must be no more than 30 characters' );
  ELSIF REGEXP_INSTR ( password, '"' ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20003, 'password must not contain the " symbol' );
  ELSIF REGEXP_INSTR ( PASSWORD, '^[a-zA-Z]' ) < 1
  THEN  RAISE_APPLICATION_ERROR ( -20004, 'password must start with a letter' );
  ELSIF REGEXP_INSTR ( PASSWORD, '\d{1,}' ) < 1
  THEN  RAISE_APPLICATION_ERROR ( -20005, 'password must contain at least one digit' );
  ELSIF REGEXP_INSTR ( PASSWORD, '[A-Z]{1,}' ) < 1
  THEN  RAISE_APPLICATION_ERROR ( -20006, 'password must contain at least one upper' );
  ELSIF REGEXP_INSTR ( PASSWORD, '[a-z]{1,}' ) < 1
  THEN  RAISE_APPLICATION_ERROR ( -20007, 'password must contain at least one lower' );
  ELSIF REGEXP_INSTR ( PASSWORD, '(%|~|#|_|!|\^|\-|\[|\]|\+|\,|\.]){1,}' ) < 1
  THEN  RAISE_APPLICATION_ERROR ( -20008, 'password must contain one of the following symbols %~#!^-[]+,.' );
  ELSIF UTL_MATCH.JARO_WINKLER ( password, old_password ) > .5
  THEN  RAISE_APPLICATION_ERROR ( -20009, 'password is too close to the old one' );
  ELSIF INSTR ( LOWER ( password ), lv_un_fwd ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20010, 'password cannot contain the username' );
  ELSIF INSTR ( LOWER ( password ), lv_un_rev ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20011, 'password cannot contain the reversed username' );
  ELSIF INSTR ( LOWER ( password ), lv_hn_fwd ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20012, 'password cannot contain the server name' );
  ELSIF INSTR ( LOWER ( password ), lv_hn_rev ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20013, 'password cannot contain the reversed server name' );
  ELSIF INSTR ( LOWER ( password ), lv_in_fwd ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20014, 'password cannot contain the instance name' );
  ELSIF INSTR ( LOWER ( password ), lv_in_rev ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20015, 'password cannot contain the reversed instance_name' );
  ELSIF REGEXP_INSTR ( password, '(.+{3,}).*\1' ) > 0
  THEN  RAISE_APPLICATION_ERROR ( -20016, 'password cannot contain 3+ repeated characters' );
  END   IF;
-----------------------------------------------------------------------------
-- check the password dictionary
-----------------------------------------------------------------------------
  SELECT  COUNT(*)
 INTO  lv_dcount
 FROM  password_dictionary
WHERE  password_fwd = password
   OR  password_rev = password;
  IF lv_dcount > 0 THEN
 RAISE_APPLICATION_ERROR ( -20017, 'password is a dictionary word' );
  END IF;
-----------------------------------------------------------------------------
-- everything checks out
-----------------------------------------------------------------------------
  RETURN TRUE;
END;
/
 
GRANT EXECUTE ON ora12c_verify_function TO PUBLIC;
ALTER PROFILE DEFAULT LIMIT
PASSWORD_LIFE_TIME 180 -- 6 months
PASSWORD_GRACE_TIME 7  -- 7 days
PASSWORD_REUSE_TIME 1095 -- 3 years before reuse
PASSWORD_REUSE_MAX  3 -- only 3 uses max
FAILED_LOGIN_ATTEMPTS 10
PASSWORD_LOCK_TIME 4 -- 4 hour of lock per profile violation
PASSWORD_VERIFY_FUNCTION ora12c_verify_function
/
 
DROP TABLE sys.password_rainbow CASCADE CONSTRAINTS PURGE;
CREATE TABLE sys.password_rainbow
(
  password_id   INTEGER GENERATED ALWAYS AS IDENTITY
, password_fwd  VARCHAR2(30)
, password_sh1  VARCHAR2(50)
, password_md5  VARCHAR2(50)
, db_username   VARCHAR2(30)
, created_by    INTEGER
, created_dt    DATE
, updated_by    INTEGER
, updated_dt    DATE
);
 
CREATE OR REPLACE PROCEDURE sys.collect_rainbow
(
  pi_username   VARCHAR2
, pi_password   VARCHAR2
)
AS
  lv_hash_sh1   VARCHAR2(250);
  lv_hash_md5   VARCHAR2(100);
BEGIN
  EXECUTE IMMEDIATE ' alter user '||pi_username||' identified by "'||pi_password||'"';
  SELECT  password
       ,  spare4
    INTO  lv_hash_md5
       ,  lv_hash_sh1
    FROM  sys.user$
   WHERE  name = pi_username;
  INSERT
    INTO  sys.password_rainbow
          ( password_fwd, password_sh1, password_md5, db_username, created_by
          , created_dt, updated_by, updated_dt)
  VALUES  ( pi_password, lv_hash_sh1, lv_hash_md5, pi_username, 1, SYSDATE, 1
          , SYSDATE );
END;
/
 
SET SERVEROUTPUT ON;
SET TAB OFF;
SET TIMING ON;
 
DECLARE
  CURSOR c IS
    SELECT  *
      FROM  dba_users du
              CROSS JOIN sys.password_dictionary pd
     WHERE  du.username in ( 'FRED' );
BEGIN
  FOR r IN c LOOP
    sys.collect_rainbow ( r.username, r.password_fwd );
  END LOOP;
  COMMIT;
END;
/