/*  ****************************************************************************
--------------------------------------------------------------------------------
FILENAME:   ch_09_xml_chained_job.sql
AUTHOR(S):  John M Harper, Michael McLaughlin
COPYRIGHT:  (c) 2014 McLaughlin Software Development LLC.
                McGraw-Hill use is granted for educational purposes. Commercial
                use is granted by written consent. Please remit requests to:
                  + john.maurice.harper@mclaughlinsoftware.com
                  + michael.mclaughlin@mclaughlinsoftware.com
--------------------------------------------------------------------------------
CHANGE_RECORD
================================================================================
DATE        INITIALS    REASON
--------------------------------------------------------------------------------
25-MAR-2014 JMH         Creating an example set to show how dbms_scheduler can
                        help in xml ingestion to the database. This file is not
                        intended to be run as a script; however, you can run
                        individual blocks with little/no modification.
--------------------------------------------------------------------------------
-- !!!STEPS REQUIRED!!!
-- 01. Unzip the person_xml.zip to obtain xml test files, sqlldr, and ctl files.
-- 02. Create the credentials
-- 03. Create 2 jobs
-- 04. Define the steps
-- 05. Add the rules
-- 06. Enable the chain
-- 07. Create main job to run the chain
****************************************************************************  */
-- START OF SCRIPT --
-- cleanup before re-running
BEGIN DBMS_SCHEDULER.STOP_JOB     ( 'CHAIN_XML2PERSON', TRUE       ); END;
/
BEGIN DBMS_SCHEDULER.DROP_JOB     ( 'CHAIN_XML2PERSON', TRUE           ); END;
/
BEGIN DBMS_SCHEDULER.DROP_PROGRAM ( 'MERGE_PERSON', TRUE               ); END;
/
BEGIN DBMS_SCHEDULER.DROP_PROGRAM ( 'IMPDP_XML', TRUE                  ); END;
/
BEGIN DBMS_SCHEDULER.DROP_CHAIN   ( 'ADMJMH.LOAD_XML', TRUE            ); END;
/
BEGIN DBMS_CREDENTIAL.DROP_CREDENTIAL ( 'INGEST_XML_CREDENTIAL', TRUE  ); END;
/
 
BEGIN
  SYS.DBMS_CREDENTIAL.CREATE_CREDENTIAL
  (
    username                 => 'oracle'
  , password                 => 'fioora12'
  , database_role            => 'SYSDBA'
  , comments                 => 'Stored credentials for ingestion of xml samples'
  , enabled                  => true
  , credential_name          => '"ADMJMH"."INGEST_XML_CREDENTIAL"'
  );
END;
/
 
drop table admjmh.test cascade constraints purge;
create table admjmh.test of xmltype;
drop table admjmh.person cascade constraints purge;
create table admjmh.person
(
  contact_id        integer
, given_name_1      varchar2(50)
, given_name_2      varchar2(50)
, family_name       varchar2(50)
, dob               date
, phone_code_ctry   varchar2(15)
, phone_code_area   varchar2(15)
, phone_code_dial   varchar2(15)
, email             varchar2(150)
, gender            char
);
 
create or replace procedure load_person
as
begin
  merge into admjmh.person p
  using   (
            with
            extraction as
            (
              select to_number ( extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/CONTACT_ID' )) contact_id
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/GIVEN_NAME_1'            ) given_name_1
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/GIVEN_NAME_2'            ) given_name_2
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/FAMILY_NAME'             ) family_name
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/DOB'                     ) dob
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/PHONE_CODE_CTRY'         ) phone_code_ctry
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/PHONE_CODE_AREA'         ) phone_code_area
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/PHONE_CODE_DIAL'         ) phone_code_dial
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/EMAIL'                   ) email
                   , extractvalue ( SYS_NC_ROWINFO$, '/CONTACTS/CONTACT/GENDER'                  ) gender
                from admjmh.test
            )
              select to_number ( contact_id ) contact_id
                   , given_name_1
                   , given_name_2
                   , family_name
                   , dob
                   , phone_code_ctry
                   , phone_code_area
                   , phone_code_dial
                   , email
                   , gender
                from extraction e
          ) e
  on      ( p.contact_id = e.contact_id )
  when matched then
  update
     set  given_name_1 = e.given_name_1
       ,  given_name_2 = e.given_name_2
       ,  family_name  = e.family_name
       ,  dob = e.dob
       ,  phone_code_ctry = e.phone_code_ctry
       ,  phone_code_area = e.phone_code_area
       ,  phone_code_dial = e.phone_code_dial
       ,  email = e.email
       ,  gender = e.gender
  when not matched then
  insert
  values  (
            e.contact_id
          , e.given_name_1
          , e.given_name_2
          , e.family_name
          , e.dob
          , e.phone_code_ctry
          , e.phone_code_area
          , e.phone_code_dial
          , e.email
          , e.gender
          );
end;
/
 
BEGIN
  DBMS_SCHEDULER.create_program
  (
    program_name              => 'ADMJMH.IMPDP_XML'
  , program_action            => '/u01/app/oracle/admin/A454/dpdump/person_xml/test.sh'
  , program_type              => 'EXECUTABLE'
  , number_of_arguments       => 0
  , comments                  => NULL
  , enabled                   => TRUE
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.create_program
  (
    PROGRAM_NAME              => 'ADMJMH.MERGE_PERSON'
  , PROGRAM_ACTION            => 'ADMJMH.LOAD_PERSON'
  , PROGRAM_TYPE              => 'STORED_PROCEDURE'
  , NUMBER_OF_ARGUMENTS       => 0
  , COMMENTS                  => 'A stored procedure that populates the person table.'
  , ENABLED                   => TRUE
  );
END;
/
 
BEGIN
    DBMS_SCHEDULER.create_chain(
        comments => 'One chain to rule them all.',
        chain_name => 'ADMJMH.LOAD_XML'
    );
      DBMS_SCHEDULER.enable(name=>'ADMJMH.LOAD_XML');
END;
/
 
BEGIN
  DBMS_SCHEDULER.DEFINE_CHAIN_STEP
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME  => '"XML_STAGE"'
  , PROGRAM_NAME => '"ADMJMH"."IMPDP_XML"'
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
   CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"XML_STAGE"'
  , ATTRIBUTE => 'PAUSE'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"XML_STAGE"'
  , ATTRIBUTE => 'SKIP'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"XML_STAGE"'
  , ATTRIBUTE => 'RESTART_ON_FAILURE'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"XML_STAGE"'
  , ATTRIBUTE => 'RESTART_ON_RECOVERY'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME  => '"XML_STAGE"'
  , ATTRIBUTE => 'CREDENTIAL_NAME'
  , CHAR_VALUE => '"ADMJMH"."INGEST_XML_CREDENTIAL"'
  ); 
END;
/
 
BEGIN
  DBMS_SCHEDULER.DEFINE_CHAIN_RULE
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , comments => 'Starting test.sh'
  , rule_name  => '"START_XML_STAGE"'
  , condition => '1=1'
  , action => 'START XML_STAGE'
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.DEFINE_CHAIN_STEP
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME  => '"LOAD_PERSON_TABLE"'
  , PROGRAM_NAME => '"ADMJMH"."MERGE_PERSON"'
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"LOAD_PERSON_TABLE"'
  , ATTRIBUTE => 'PAUSE'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"LOAD_PERSON_TABLE"'
  , ATTRIBUTE => 'SKIP'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"LOAD_PERSON_TABLE"'
  , ATTRIBUTE => 'RESTART_ON_FAILURE'
  , VALUE => false
  );
  DBMS_SCHEDULER.ALTER_CHAIN
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , STEP_NAME => '"LOAD_PERSON_TABLE"'
  , ATTRIBUTE => 'RESTART_ON_RECOVERY'
  , VALUE => false
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.DEFINE_CHAIN_RULE
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , comments => 'Start admjmh.load_person procedure'
  , rule_name  => '"START_LOAD_PERSON_TABLE"'
  , condition => 'XML_STAGE SUCCEEDED'
  , action => 'START LOAD_PERSON_TABLE'
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.DEFINE_CHAIN_RULE
  (
    CHAIN_NAME  => '"ADMJMH"."LOAD_XML"'
  , comments => 'All done.'
  , rule_name  => '"FINISHED"'
  , condition => 'LOAD_PERSON_TABLE SUCCEEDED'
  , action => 'END'
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.CREATE_JOB
  (
    job_name => '"ADMJMH"."CHAIN_XML2PERSON"'
  , job_type => 'CHAIN'
  , job_action => '"ADMJMH"."LOAD_XML"'
  , number_of_arguments => 0
  , start_date => TO_TIMESTAMP_TZ('2014-03-29 11:30:36.000000000 AMERICA/DENVER','YYYY-MM-DD HH24:MI:SS.FF TZR')
  , repeat_interval => 'FREQ=MINUTELY;INTERVAL=5'
  , end_date => NULL
  , enabled => FALSE
  , auto_drop => FALSE
  , comments => ''
  );
 
  DBMS_SCHEDULER.SET_ATTRIBUTE
  (
    name => '"ADMJMH"."CHAIN_XML2PERSON"'
  , attribute => 'store_output'
  , value => TRUE
  );
  DBMS_SCHEDULER.SET_ATTRIBUTE
  (
    name => '"ADMJMH"."CHAIN_XML2PERSON"'
  , attribute => 'job_priority'
  , value => '1'
  );
  DBMS_SCHEDULER.SET_ATTRIBUTE
  (
    name => '"ADMJMH"."CHAIN_XML2PERSON"'
  , attribute => 'logging_level'
  , value => DBMS_SCHEDULER.LOGGING_FULL
  );
 
  DBMS_SCHEDULER.enable('"ADMJMH"."CHAIN_XML2PERSON"');
END;
/
 
-- END OF SCRIPT --
 
 
/*
TROUBLESHOOTING
 
select * from dba_scheduler_jobs where owner = 'ADMJMH';
select * from dba_scheduler_programs where owner = 'ADMJMH';
select * from dba_scheduler_running_jobs where owner = 'ADMJMH';
select * from dba_scheduler_job_run_details where owner = 'ADMJMH' order by log_date;
 
BEGIN
  DBMS_SCHEDULER.DROP_JOB ( 'TEST_JOB' );
END;
/
SQL> BEGIN
  2    DBMS_SCHEDULER.CREATE_JOB
  3    (
  4    job_name => '"ADMJMH"."TEST_JOB"',
  5    program_name => '"ADMJMH"."IMPDP_XML"',
  6    start_date => NULL,
  7    repeat_interval => NULL,
  8    end_date => NULL,
  9    enabled => FALSE,
 10    auto_drop => TRUE,
 11    comments => '',
 12    job_style => 'REGULAR',
 13    credential_name => 'INGEST_XML_CREDENTIAL'
 14    );
 15    DBMS_SCHEDULER.SET_ATTRIBUTE(
 16             name => '"ADMJMH"."TEST_JOB"',
 17             attribute => 'store_output', value => TRUE);
 18    DBMS_SCHEDULER.SET_ATTRIBUTE(
 19             name => '"ADMJMH"."TEST_JOB"',
 20             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_OFF);
 21    DBMS_SCHEDULER.enable(
 22             name => '"ADMJMH"."TEST_JOB"');
 23  END;
 24  /
 
PL/SQL procedure successfully completed.
 
 
SQL> select  job_name
  2       ,  status
  3       ,  output
  4    from  dba_scheduler_job_run_details
  5   where  owner = 'ADMJMH' and job_name like '%TEST%'
 
JOB_NAME   STATUS     OUTPUT
---------- ---------- ------------------------------------------------------------
TEST_JOB   SUCCEEDED  SQL*Loader: Release 12.1.0.1.0 - Production on Sat Mar 29 20
                      :45:16 2014
 
                      Copyright (c) 1982, 2013, Oracle and/or its affiliates.  All
                       rights reserved.
 
                      Path used:      Direct
 
                      Load completed - logical record count 7.
 
                      Table ADMJMH.TEST:
                        7 Rows successfully loaded.
 
                      Check the log file:
                        test.log
                      for more information about the load.
 
stoping, enabling, disabling, pausing
 
BEGIN
  DBMS_SCHEDULER.STOP_JOB
  ( 
    name=> '"ADMJMH"."test_job"'
  , force => TRUE
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.disable(name=>'"ADMJMH"."test_job"', force => TRUE);
END;
/
 
BEGIN
  DBMS_SCHEDULER.enable(name=>'"ADMJMH"."test_job"');
END;
/
 
BEGIN
  DBMS_SCHEDULER.DROP_JOB
  (
    job_name => '"ADMJMH"."test_job"'
  , defer => false
  , force => false
  );
END;
/
 
BEGIN
  DBMS_SCHEDULER.ALTER_RUNNING_CHAIN
  (
    job_name => '"ADMJMH"."CHAINXML2PERSON"'
  , step_name => 'LOAD_PERSON_TABLE'
  , attribute => 'PAUSE BEFORE'
  , value => 'NOT_STARTED'
  );
END;
/
 
*/