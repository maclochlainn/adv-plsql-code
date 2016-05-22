/*
GRANT EXECUTE ON DBMS_CRYPTO TO video_store;
 
DROP TABLE contact CASCADE CONSTRAINTS PURGE;
DROP TABLE system_user CASCADE CONSTRAINTS PURGE;
 
CREATE TABLE contact
( contact_id                  NUMBER        CONSTRAINT pk_contact   PRIMARY KEY
, member_id                   NUMBER        CONSTRAINT nn_contact_1 NOT NULL
, contact_type                NUMBER        CONSTRAINT nn_contact_2 NOT NULL
, last_name                   VARCHAR2(20)  CONSTRAINT nn_contact_3 NOT NULL
, first_name                  VARCHAR2(20)  CONSTRAINT nn_contact_4 NOT NULL
, middle_name                 VARCHAR2(20)
, favorite_color              VARCHAR2(20)  CONSTRAINT nn_contact_9 NOT NULL
, favorite_food               VARCHAR2(20)  CONSTRAINT nn_contact_10 NOT NULL
, created_by                  NUMBER        CONSTRAINT nn_contact_5 NOT NULL
, creation_date               DATE          CONSTRAINT nn_contact_6 NOT NULL
, last_updated_by             NUMBER        CONSTRAINT nn_contact_7 NOT NULL
, last_update_date            DATE          CONSTRAINT nn_contact_8 NOT NULL
);
 
CREATE TABLE system_user
( system_user_id              NUMBER        CONSTRAINT pk_system_user   PRIMARY KEY
, system_contact_id           NUMBER
, system_user_name            VARCHAR2(20)  CONSTRAINT nn_system_user_1 NOT NULL
, system_user_group_id        NUMBER        CONSTRAINT nn_system_user_2 NOT NULL
, system_user_type            NUMBER        CONSTRAINT nn_system_user_3 NOT NULL
, system_password             VARCHAR2(250)  CONSTRAINT nn_system_user_8 NOT NULL
, created_by                  NUMBER        CONSTRAINT nn_system_user_4 NOT NULL
, creation_date               DATE          CONSTRAINT nn_system_user_5 NOT NULL
, last_updated_by             NUMBER        CONSTRAINT nn_system_user_6 NOT NULL
, last_update_date            DATE          CONSTRAINT nn_system_user_7 NOT NULL
);
 
ALTER TABLE system_user
  ADD CONSTRAINT fk_system_contact_id
  FOREIGN KEY ( system_contact_id )
  REFERENCES contact ( contact_id );
 
*/
 
CREATE OR REPLACE FUNCTION hashed
(
  pi_username   IN VARCHAR2
, pi_password   IN VARCHAR2
, pi_phrase1    IN VARCHAR2   -- secret answer 1
, pi_phrase2    IN VARCHAR2   -- secret answer 2
)
RETURN VARCHAR2 AS
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
END;
/
 
INSERT
  INTO  contact
VALUES  (
          10
        , 1
        , 1
        , 'Thornton'
        , 'Billy'
        , 'Bob'
        , 'Red'
        , 'Pizza'
        , 1
        , SYSDATE
        , 1
        , SYSDATE
        );
 
INSERT
  INTO  system_user
VALUES  (
          1
        , 10
        , 'thorntonbb'
        , 2
        , 1
        , hashed ( 'thorntonbb', 'abc123', 'pizza', 'red' )
        , 1
        , SYSDATE
        , 1
        , SYSDATE
        );
 
INSERT
  INTO  contact
VALUES  (
          11
        , 1
        , 1
        , 'Voight'
        , 'Angelina'
        , 'Jolie'
        , 'Black'
        , 'Cheerios'
        , 1
        , SYSDATE
        , 1
        , SYSDATE
        );
 
INSERT
  INTO  system_user
VALUES  (
          2
        , 11
        , 'voightaj'
        , 2
        , 1
        , hashed ( 'voightaj', 'abc123', 'cheerios', 'black' )
        , 1
        , SYSDATE
        , 1
        , SYSDATE
        );
 
CREATE DIRECTORY security AS '/u02/admin/scripts';
 
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
 
select * from PASSWORD_DICTIONARY_STAGE;
 
 
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
SELECT password password_fwd
     , reverse ( password ) password_rev
     , TO_NUMBER ( TRIM ( REPLACE ( frequency, CHR(13), ' ' ))) password_cnt
     , 0 created_by
     , sysdate created_dt
     , 0 updated_by
     , sysdate updated_dt
  FROM PASSWORD_DICTIONARY_STAGE
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
 
COMMIT;
 
 
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
--------------------------------------------------------------------------------
-- the reverse function is much more efficient than looping
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
-- get all of the string comparisons out of the way first
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
-- check the password dictionary
--------------------------------------------------------------------------------
  SELECT  COUNT(*)
    INTO  lv_dcount
    FROM  password_dictionary
   WHERE  password_fwd = password
      OR  password_rev = password;
 
  IF lv_dcount > 0 THEN
    RAISE_APPLICATION_ERROR ( -20017, 'password is a dictionary word' );
  END IF;
--------------------------------------------------------------------------------
-- everything checks out
--------------------------------------------------------------------------------
  RETURN TRUE;
END;
/
 
--------------------------------------------------------------------------------
-- you need to grant execute on the function to public so users can invoke it
-- with their profile
--------------------------------------------------------------------------------
GRANT EXECUTE ON ora12c_verify_function TO PUBLIC;
--------------------------------------------------------------------------------
-- Insert new passwords in the password dictionary file to increase its strength
--------------------------------------------------------------------------------
insert
  into  password_dictionary
        (
          password_fwd
        , password_rev
        , created_by
        , created_dt
        , updated_by
        , updated_dt
        )
values  (
          'changeOn_1nstall'
        , 'llatsn1_n0egnahc'
        , 0
        , sysdate
        , 0
        , sysdate
        );
commit;
--------------------------------------------------------------------------------
-- testing the function
-- uncomment one at a time
--------------------------------------------------------------------------------
DECLARE
  lv_compare BOOLEAN;
BEGIN
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'less8', 'fred' ); -- more than 8
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'thisisareallylongpassword123456', 'fred' ); -- more than 30
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'fr"edlongpassword', 'fred' ); -- cannot contain "
--  lv_compare := sys.ora12c_verify_function ( 'fred', '1fredlongpassword', 'fred' ); -- cannot start with a number
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'fredlongpassword', 'fred' ); -- at least 1 number
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'fredlongpassw0rd', 'fred' ); -- at least 1 upper
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'FREDLONGPASSW0RD', 'fred' ); -- at least 1 lower
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'fredLongPassW0rd', 'fred' ); -- specials
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'fredLongPassW0rd#', 'fredLongPassW0rd4#' ); -- to close
--  lv_compare := sys.ora12c_verify_function ( 'fredLongPassW0rd#', 'fredLongPassW0rd#', 'wilma' ); -- not the username
--  lv_compare := sys.ora12c_verify_function ( '#dr0WssaPgnoLderf', 'fredLongPassW0rd#', 'wilma' ); -- not the reversed username
--  lv_compare := sys.ora12c_verify_function ( 'fred', 'changeOn_1nstall', 'fred' ); -- in the dictionary
  lv_compare := sys.ora12c_verify_function ( 'fred', 'finally1ThatWorks#', 'fred' ); -- in the dictionary
  IF lv_compare THEN
    DBMS_OUTPUT.PUT_LINE ( 'passed' );
  END IF;
END;
/
--------------------------------------------------------------------------------
-- to implement change any profile or make a new one
--------------------------------------------------------------------------------
ALTER PROFILE DEFAULT LIMIT
PASSWORD_LIFE_TIME 180 -- 6 months
PASSWORD_GRACE_TIME 7  -- 7 days
PASSWORD_REUSE_TIME 1095 -- 3 years before reuse
PASSWORD_REUSE_MAX  3 -- only 3 uses max
FAILED_LOGIN_ATTEMPTS 10
PASSWORD_LOCK_TIME 4 -- 4 hour of lock per profile violation
PASSWORD_VERIFY_FUNCTION ora12c_verify_function;
 
/* Output from above
SQL> GRANT EXECUTE ON DBMS_CRYPTO TO video_store;
SQL> DROP TABLE contact CASCADE CONSTRAINTS PURGE;
SQL> DROP TABLE system_user CASCADE CONSTRAINTS PURGE;
 
SQL> CREATE TABLE contact
  2  ( contact_id       NUMBER        CONSTRAINT pk_contact   PRIMARY KEY
  3  , member_id        NUMBER        CONSTRAINT nn_contact_1 NOT NULL
  4  , contact_type     NUMBER        CONSTRAINT nn_contact_2 NOT NULL
  5  , last_name        VARCHAR2(20)  CONSTRAINT nn_contact_3 NOT NULL
  6  , first_name       VARCHAR2(20)  CONSTRAINT nn_contact_4 NOT NULL
  7  , middle_name      VARCHAR2(20)
  8  , favorite_color   VARCHAR2(20)  CONSTRAINT nn_contact_9 NOT NULL
  9  , favorite_food    VARCHAR2(20)  CONSTRAINT nn_contact_10 NOT NULL
 10  , created_by       NUMBER        CONSTRAINT nn_contact_5 NOT NULL
 11  , creation_date    DATE          CONSTRAINT nn_contact_6 NOT NULL
 12  , last_updated_by  NUMBER        CONSTRAINT nn_contact_7 NOT NULL
 13  , last_update_date DATE          CONSTRAINT nn_contact_8 NOT NULL
 14  );
 
SQL> CREATE TABLE system_user
  2  ( system_user_id              NUMBER        CONSTRAINT pk_system_user   PRIMARY KEY
  3  , system_contact_id           NUMBER
  4  , system_user_name            VARCHAR2(20)  CONSTRAINT nn_system_user_1 NOT NULL
  5  , system_user_group_id        NUMBER        CONSTRAINT nn_system_user_2 NOT NULL
  6  , system_user_type            NUMBER        CONSTRAINT nn_system_user_3 NOT NULL
  7  , system_password             VARCHAR2(250) CONSTRAINT nn_system_user_8 NOT NULL
  8  , created_by                  NUMBER        CONSTRAINT nn_system_user_4 NOT NULL
  9  , creation_date               DATE          CONSTRAINT nn_system_user_5 NOT NULL
 10  , last_updated_by             NUMBER        CONSTRAINT nn_system_user_6 NOT NULL
 11  , last_update_date            DATE          CONSTRAINT nn_system_user_7 NOT NULL
 12  );
 
SQL> CREATE OR REPLACE FUNCTION hashed
  2  (
  3    pi_username   IN VARCHAR2
  4  , pi_password   IN VARCHAR2
  5  , pi_phrase1    IN VARCHAR2   -- secret answer 1
  6  , pi_phrase2    IN VARCHAR2   -- secret answer 2
  7  )
  8  RETURN VARCHAR2 AS
  9    lv_salted VARCHAR2(250);
 10  BEGIN
 11    lv_salted :=
 12    UPPER (
 13      pi_username ||
 14      pi_phrase1  ||
 15      pi_password ||
 16      pi_phrase2
 17    );
 18    RETURN DBMS_CRYPTO.HASH ( UTL_RAW.CAST_TO_RAW ( lv_salted ), DBMS_CRYPTO.HASH_SH512 );
 19    RETURN lv_salted;
 20  END;
 21  /
 
SQL> INSERT
  2    INTO  contact
  3  VALUES  (
  4            10
  5          , 1
  6          , 1
  7          , 'Thornton'
  8          , 'Billy'
  9          , 'Bob'
 10          , 'Red'
 11          , 'Pizza'
 12          , 1
 13          , SYSDATE
 14          , 1
 15          , SYSDATE
 16          );
 
SQL> INSERT
  2  f  INTO  system_user
  3  VALUES  (
  4            1
  5          , 10
  6          , 'thorntonbb'
  7          , 2
  8          , 1
  9          , hashed ( 'thorntonbb', 'abc123', 'pizza', 'red' )
 10          , 1
 11          , SYSDATE
 12          , 1
 13          , SYSDATE
 14          );
 
SQL> INSERT
  2    INTO  contact
  3  VALUES  (
  4            11
  5          , 1
  6          , 1
  7          , 'Voight'
  8          , 'Angelina'
  9          , 'Jolie'
 10          , 'Black'
 11          , 'Cheerios'
 12          , 1
 13          , SYSDATE
 14          , 1
 15          , SYSDATE
 16          );
 
SQL> INSERT
  2    INTO  system_user
  3  VALUES  (
  4            2
  5          , 11
  6          , 'voightaj'
  7          , 2
  8          , 1
  9          , hashed ( 'voightaj', 'abc123', 'cheerios', 'black' )
 10          , 1
 11          , SYSDATE
 12          , 1
 13          , SYSDATE
 14          );
 
SQL> COLUMN system_password FORMAT A60
SQL> COLUMN system_user_name FORMAT A20
SQL> SELECT system_user_name
  2       , system_password
  3    FROM system_user;
 
SYSTEM_USER_NAME    SYSTEM_PASSWORD
--------------------------------------------------------------------------------
thorntonbb          306999E31B3BEEAB84B120C4C131151C5BF12E9C30374C919919CAD1F719
                    75D62930ECF99035E42640BCEDD10059F200F031AC2B6EFFB2CB2C6EF04D
                    8E87AF4E
 
voightaj            0F00D2C3DA3E0B67E87D8FB167F72F85FA908BD8A747AA71B0AA760B1D12
                    5635494B871C1B69D9C3AA056B84DDA34E0C8D9EF8A75FA0C45EF5284B53
                    D1DDB574
*/