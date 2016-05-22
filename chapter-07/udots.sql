DROP TABLE sys.password_rainbow CASCADE CONSTRAINTS PURGE;
CREATE TABLE sys.password_rainbow
(
  password_id   INTEGER GENERATED ALWAYS AS IDENTITY
, password_fwd  VARCHAR2(30)
, password_sh1  VARCHAR2(250)
, password_md5  VARCHAR2(100)
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
 
/*
SQL> CREATE PROFILE h_user LIMIT password_verify_function NULL;
SQL> ALTER PROFILE h_user LIMIT password_reuse_max NULL;
SQL> CREATE USER fred IDENTIFIED BY "This Is My #1 Pass";
SQL> ALTER USER fred PROFILE h_user;
SQL> DROP TABLE sys.password_rainbow CASCADE CONSTRAINTS PURGE;
 
SQL> CREATE TABLE sys.password_rainbow
  2  (
  3    password_id   INTEGER GENERATED ALWAYS AS IDENTITY
  4  , password_fwd  VARCHAR2(30)
  5  , password_sh1  VARCHAR2(50)
  6  , password_md5  VARCHAR2(250)
  7  , db_username   VARCHAR2(30)
  8  , created_by    INTEGER
  9  , created_dt    DATE
 10  , updated_by    INTEGER
 11  , updated_dt    DATE
 12  );
 
SQL> CREATE OR REPLACE PROCEDURE sys.collect_rainbow
  2  (
  3    pi_username   VARCHAR2
  4  , pi_password   VARCHAR2
  5  )
  6  AS
  7    lv_hash_sh1   VARCHAR2(250);
  8    lv_hash_md5   VARCHAR2(100);
  9  BEGIN
 10    EXECUTE IMMEDIATE ' alter user '||pi_username||' identified by "'||pi_password||'"';
 11    SELECT  password
 12         ,  spare4
 13      INTO  lv_hash_md5
 14         ,  lv_hash_sh1
 15      FROM  sys.user$
 16     WHERE  name = pi_username;
 17    INSERT
 18      INTO  sys.password_rainbow
 19            ( password_fwd, password_sh1, password_md5, db_username, created_by
 20            , created_dt, updated_by, updated_dt)
 21    VALUES  ( pi_password, lv_hash_sh1, lv_hash_md5, pi_username, 1, SYSDATE, 1
 22            , SYSDATE );
 23  END;
 24  /
 
SQL> SET SERVEROUTPUT ON;
SQL> SET TAB OFF;
SQL> SET TIMING ON;
 
SQL> DECLARE
  2    CURSOR c IS
  3      SELECT  *
  4        FROM  dba_users du
  5                CROSS JOIN sys.password_dictionary pd
  6       WHERE  du.username in ( 'FRED' );
  7  BEGIN
  8    FOR r IN c LOOP
  9      sys.collect_rainbow ( r.username, r.password_fwd );
 10    END LOOP;
 11    COMMIT;
 12  END;
 13  /
PL/SQL procedure successfully completed.
 
Elapsed: 00:00:36.17
 
SQL> COLUMN db_username FORMAT a12
SQL> COLUMN password_fwd FORMAT a15
SQL> COLUMN password_md5 FORMAT a25
SQL> COLUMN password_sh1 FORMAT a25
SQL> SELECT  db_username
  2       ,  password_fwd
  3       ,  password_md5
  4       ,  password_sh1
  5    FROM  sys.password_rainbow
  6   WHERE  rownum <= 3;
DB_USERNAME PASSWORD_FWD    PASSWORD_MD5              PASSWORD_SH1
----------- --------------- ------------------------- -------------------------
FRED        password        A9050168F28E6063          S:42CECFB5C1CAC478F6AEC7E
                                                      BE39EE9C844A3742EB5BE1950
                                                      02A24D38EA22;H:1D165E4444
                                                      D1DBAB2005550044723906
 
FRED        123456          C83C3B127EE84B8B          S:70F8122A5607CB9B43BF711
                                                      6E0D9DB7F7CD0B252BEE111A8
                                                      89D2F1DF406C;H:DAE69B5E1A
                                                      107F776739EDFBB8F4E9FD
 
FRED        12345678        50FAF424D153C458          S:F838A4B4C60748A91F8276A
                                                      A093AAAEEC7298C949DF53547
                                                      03CED8BCE05F;H:C86CB3F475
                                                      A7B1C0215E07EADE7CA637
 
 
*/