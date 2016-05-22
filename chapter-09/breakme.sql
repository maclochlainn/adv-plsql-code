/*  ****************************************************************************
--------------------------------------------------------------------------------
FILENAME:   ch_09_breakme.sql
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
20-APR-2014 JMH         Examples from chapter for creating intervals
--------------------------------------------------------------------------------
****************************************************************************  */
 
--------------------------------------------------------------------------------
-- Example 09-08
-- creating a procedure that will break when passed a denominator = 0
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE break_me
(
  pi_numerator   IN  NUMBER
, pi_denominator IN  NUMBER
, po_quotient    OUT NUMBER
)
AS
  lv_quotient NUMBER;
BEGIN
  lv_quotient := pi_numerator / pi_denominator;
  po_quotient := lv_quotient;
END;
/
 
--------------------------------------------------------------------------------
-- Example 09-09
-- creating a one-time-run job that runs the break_me job successfully
--------------------------------------------------------------------------------
DECLARE
  lv_job VARCHAR2(30) := 'MY_JOB' || TO_CHAR ( sysdate, 'DDMMYYYYHHMISS' );
BEGIN
  DBMS_SCHEDULER.CREATE_JOB
  (
    JOB_NAME     => lv_job
  , JOB_TYPE     => 'PLSQL_BLOCK'
  , JOB_ACTION   => ' declare lv_quotient number; begin break_me '||
                    ' ( 1, 1, lv_quotient ); end; '
  , ENABLED      => true
  , AUTO_DROP    => true
  );
END;
/
 
--------------------------------------------------------------------------------
-- Example 09-10
-- viewing the results of the successful run
--------------------------------------------------------------------------------
SELECT  job_name
     ,  status
     ,  error#
     ,  instance_id
     ,  session_id
     ,  cpu_used
     ,  additional_info
  FROM  dba_scheduler_job_run_details
 WHERE  job_name like 'MY_JOB%';
 
--------------------------------------------------------------------------------
-- Example 09-11
-- creating a one-time-run job that triggers the breakage
--------------------------------------------------------------------------------
DECLARE
  lv_job VARCHAR2(30) := 'MY_JOB' || TO_CHAR ( sysdate, 'DDMMYYYYHHMISS' );
BEGIN
  DBMS_SCHEDULER.CREATE_JOB
  (
    JOB_NAME     => lv_job
  , JOB_TYPE     => 'PLSQL_BLOCK'
  , JOB_ACTION   => ' declare lv_quotient number; begin break_me '||
                    ' ( 1, 0, lv_quotient ); end; '
  , ENABLED      => true
  , AUTO_DROP    => true
  );
END;
/
 
--------------------------------------------------------------------------------
-- Example 09-12
-- creating a one-time-run job that triggers the breakage
--------------------------------------------------------------------------------
SELECT  job_name
     ,  status
     ,  error#
     ,  instance_id
     ,  session_id
     ,  cpu_used
     ,  additional_info
  FROM  dba_scheduler_job_run_details
 WHERE  job_name like 'MY_JOB%';
