GRANT EXECUTE ON DBMS_CRYPTO TO video_store;
DROP TABLE contact CASCADE CONSTRAINTS PURGE;
DROP TABLE system_user CASCADE CONSTRAINTS PURGE;
CREATE TABLE contact
( contact_id       NUMBER        CONSTRAINT pk_contact   PRIMARY KEY
, member_id        NUMBER        CONSTRAINT nn_contact_1 NOT NULL
, contact_type     NUMBER        CONSTRAINT nn_contact_2 NOT NULL
, last_name        VARCHAR2(20)  CONSTRAINT nn_contact_3 NOT NULL
, first_name       VARCHAR2(20)  CONSTRAINT nn_contact_4 NOT NULL
, middle_name      VARCHAR2(20)
, favorite_color   VARCHAR2(20)  CONSTRAINT nn_contact_9 NOT NULL
, favorite_food    VARCHAR2(20)  CONSTRAINT nn_contact_10 NOT NULL
, created_by       NUMBER        CONSTRAINT nn_contact_5 NOT NULL
, creation_date    DATE          CONSTRAINT nn_contact_6 NOT NULL
, last_updated_by  NUMBER        CONSTRAINT nn_contact_7 NOT NULL
, last_update_date DATE          CONSTRAINT nn_contact_8 NOT NULL
);
 
CREATE TABLE system_user
( system_user_id              NUMBER        CONSTRAINT pk_system_user   PRIMARY KEY
, system_contact_id           NUMBER
, system_user_name            VARCHAR2(20)  CONSTRAINT nn_system_user_1 NOT NULL
, system_user_group_id        NUMBER        CONSTRAINT nn_system_user_2 NOT NULL
, system_user_type            NUMBER        CONSTRAINT nn_system_user_3 NOT NULL
, system_password             VARCHAR2(250) CONSTRAINT nn_system_user_8 NOT NULL
, created_by                  NUMBER        CONSTRAINT nn_system_user_4 NOT NULL
, creation_date               DATE          CONSTRAINT nn_system_user_5 NOT NULL
, last_updated_by             NUMBER        CONSTRAINT nn_system_user_6 NOT NULL
, last_update_date            DATE          CONSTRAINT nn_system_user_7 NOT NULL
);
 
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
VALUES  ( 10, 1, 1, 'Thornton', 'Billy', 'Bob', 'Red', 'Pizza', 1
        , SYSDATE, 1, SYSDATE );
 
INSERT
  INTO  system_user
VALUES  ( 1, 10, 'thorntonbb', 2, 1
        , hashed ( 'thorntonbb', 'abc123', 'pizza', 'red' )
        , 1, SYSDATE, 1, SYSDATE );
 
INSERT
  INTO  contact
VALUES  ( 11, 1, 1, 'Voight', 'Angelina', 'Jolie', 'Red', 'Pizza', 1
        , SYSDATE, 1, SYSDATE );
 
INSERT
  INTO  system_user
VALUES  ( 1, 11, 'voightaj', 2, 1
        , hashed ( 'voightaj', 'abc123', 'cheerios', 'black' )
        , 1, SYSDATE, 1, SYSDATE );
 
COLUMN system_password FORMAT A60
COLUMN system_user_name FORMAT A20
SELECT system_user_name
     , system_password
  FROM system_user;