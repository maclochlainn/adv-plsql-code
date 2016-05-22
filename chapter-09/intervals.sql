/*  ****************************************************************************
--------------------------------------------------------------------------------
FILENAME:   ch_09_intervals.sql
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
-- Example 09-01
-- creating a one-time-run job
--------------------------------------------------------------------------------
DECLARE
  lv_job VARCHAR2(30) := 'MYJOB' || TO_CHAR ( SYSDATE, 'DDMMYYYYHHMISS' );
BEGIN
  DBMS_SCHEDULER.CREATE_JOB
  (
    JOB_NAME   => lv_job
  , JOB_TYPE   => 'PLSQL_BLOCK'
  , JOB_ACTION => ' begin null; end; '
  , ENABLED    => true
  , AUTO_DROP  => true
  );
END;
/ 
--------------------------------------------------------------------------------
-- Example 09-02
-- creating a custom schedule by date
--------------------------------------------------------------------------------
BEGIN 
  DBMS_SCHEDULER.CREATE_SCHEDULE
  ( 
    SCHEDULE_NAME   => 'company_holiday'
  , REPEAT_INTERVAL => 'FREQ=YEARLY;BYDATE=0101,0120,0217,0526,1225'
  );
END;
/
--------------------------------------------------------------------------------
-- Example 09-03
-- creating a minutely schedule
--------------------------------------------------------------------------------
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE
  (
    SCHEDULE_NAME  => 'security_heartbeat'
  , REPEAT_INTERVAL => 'FREQ=MINUTELY'
  );
END;
/
--------------------------------------------------------------------------------
-- Example 09-04
-- creating a custom blue-moon schedule
--------------------------------------------------------------------------------
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE
  (
    SCHEDULE_NAME   => 'blue_moons'
  , REPEAT_INTERVAL => 'FREQ=YEARLY;BYDATE=20150731,20180131,20180331,20230831'    
  );
END;
/
--------------------------------------------------------------------------------
-- Example 09-05
-- creating a combined schedule-001
--------------------------------------------------------------------------------
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE
  (
    SCHEDULE_NAME   => 'combined_001'
  , REPEAT_INTERVAL => 'FREQ=blue_moons;include=quarterly_end'
  );
END;
/
--------------------------------------------------------------------------------
-- Example 09-06
-- creating a combined schedule-002
--------------------------------------------------------------------------------
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE
  (
    SCHEDULE_NAME   => 'combined_02'
  , REPEAT_INTERVAL => 'FREQ=MINUTELY;include=quarterly_end,blue_moons'
  );
END;
/
--------------------------------------------------------------------------------
-- Example 09-07
-- first look at dba_scheduler_schedules
--------------------------------------------------------------------------------
  SELECT  owner
       ,  schedule_name
       ,  schedule_type
       ,  repeat_interval
    FROM  dba_scheduler_schedules
ORDER BY  owner
       ,  schedule_name;