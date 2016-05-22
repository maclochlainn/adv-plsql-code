SQL> grant execute on dbms_datapump to video_store;
SQL> grant datapump_exp_full_database to video_store;
SQL> grant datapump_imp_full_database to video_store;
SQL> grant read, write on directory wwest_001 to video_store;
 
SET TIMING ON;
SET SERVEROUTPUT ON;
SET TAB OFF;
 
DECLARE
  lv_info_table       ku$_dumpfile_info;
  lv_filetype         number;
  lv_item_decoded     dbms_sql.varchar2_table;
BEGIN
  DBMS_DATAPUMP.GET_DUMPFILE_INFO (
                                    filename    => 'video_store24.dmp'
                                  , directory   => 'WWEST_001'
                                  , info_table  => lv_info_table
                                  , filetype    => lv_filetype
                                  );
 
  FOR a IN 1 .. lv_info_table.COUNT LOOP
    CASE
      WHEN lv_info_table(a).item_code = 1
      THEN lv_item_decoded(a) := 'FILE VERSION';
      WHEN lv_info_table(a).item_code = 2
      THEN lv_item_decoded(a) := 'MASTER TABLE PRESENT';
      WHEN lv_info_table(a).item_code = 3
      THEN lv_item_decoded(a) := 'EXPORT GUID';
      WHEN lv_info_table(a).item_code = 4
      THEN lv_item_decoded(a) := 'FILE NUMBER';
      WHEN lv_info_table(a).item_code = 5
      THEN lv_item_decoded(a) := 'CHARACTER SET';
      WHEN lv_info_table(a).item_code = 6
      THEN lv_item_decoded(a) := 'CREATE DATE';
      WHEN lv_info_table(a).item_code = 7
      THEN lv_item_decoded(a) := 'INTERNAL FLAG';
      WHEN lv_info_table(a).item_code = 8
      THEN lv_item_decoded(a) := 'JOB NAME';
      WHEN lv_info_table(a).item_code = 9
      THEN lv_item_decoded(a) := 'PLATFORM';
      WHEN lv_info_table(a).item_code = 10
      THEN lv_item_decoded(a) := 'INSTANCE';
      WHEN lv_info_table(a).item_code = 11
      THEN lv_item_decoded(a) := 'LANGUAGE';
      WHEN lv_info_table(a).item_code = 12
      THEN lv_item_decoded(a) := 'BLOCK SIZE';
      WHEN lv_info_table(a).item_code = 13
      THEN lv_item_decoded(a) := 'DIRECT PATH USED';
      WHEN lv_info_table(a).item_code = 14
      THEN lv_item_decoded(a) := 'METADATA COMPRESSED';
      WHEN lv_info_table(a).item_code = 15
      THEN lv_item_decoded(a) := 'DB VERSION';
      WHEN lv_info_table(a).item_code = 16
      THEN lv_item_decoded(a) := 'MASTER PIECE COUNT';
      WHEN lv_info_table(a).item_code = 17
      THEN lv_item_decoded(a) := 'MASTER PIECE NUMBER';
      WHEN lv_info_table(a).item_code = 18
      THEN lv_item_decoded(a) := 'DATA COMPRESSED';
      WHEN lv_info_table(a).item_code = 19
      THEN lv_item_decoded(a) := 'METADATA ENCRYPTED';
      WHEN lv_info_table(a).item_code = 20
      THEN lv_item_decoded(a) := 'DATA ENCRYPTED';
      WHEN lv_info_table(a).item_code = 21
      THEN lv_item_decoded(a) := 'COLUMNS ENCRYPTED';
      WHEN lv_info_table(a).item_code = 22
      THEN lv_item_decoded(a) := 'ENCRYPTION MODE';
      WHEN lv_info_table(a).item_code = 23
      THEN lv_item_decoded(a) := 'COMPRESSION ALGORITHM';
      ELSE lv_item_decoded(a) := lv_info_table(a).item_code;
    END CASE;
 
    DBMS_OUTPUT.PUT_LINE  (
                            rpad ( lv_item_decoded(a), '25', '.' ) || ':  ' ||
                            lv_info_table(a).value
                          );
  END LOOP;
END;
/
 
SET tab OFF;
SET timing ON;
SET serveroutput ON;
DECLARE
  lv_jobname                  VARCHAR2(30) := 'VS_'||DBMS_SCHEDULER.GENERATE_JOB_NAME;
  ind                         NUMBER;
  spos                        NUMBER;
  slen                        NUMBER;
  h1                          NUMBER;
  percent_done                NUMBER;
  job_state                   VARCHAR2(30);
  le                          ku$_LogEntry;
  js                          ku$_JobStatus;
  jd                          ku$_JobDesc;
  sts                         ku$_Status;
BEGIN
  h1 := DBMS_DATAPUMP.OPEN ( 'EXPORT','SCHEMA',NULL,lv_jobname,'LATEST' );
  DBMS_DATAPUMP.ADD_FILE   ( h1,'video_store%U.dmp','WWEST_01' );
  DBMS_DATAPUMP.METADATA_FILTER ( h1,'SCHEMA_EXPR','IN (''VIDEO_STORE'')' );
  DBMS_DATAPUMP.SET_PARALLEL ( h1, 16 );
  BEGIN
    DBMS_DATAPUMP.START_JOB(H1);
    DBMS_OUTPUT.PUT_LINE('Data Pump job started successfully');
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = DBMS_DATAPUMP.SUCCESS_WITH_INFO_NUM
        THEN
          DBMS_OUTPUT.PUT_LINE('Data Pump job started with info available:');
          DBMS_DATAPUMP.GET_STATUS
          (
            h1
          , DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR
          , 0
          , job_state
          , sts
          );
          IF (BITAND(sts.mask,DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR) != 0)
          THEN
            le := sts.error;
            IF LE IS NOT NULL
            THEN
              ind := le.FIRST;
              WHILE ind IS NOT NULL LOOP
                DBMS_OUTPUT.PUT_LINE(le(ind).LogText);
                ind := le.NEXT(ind);
              END LOOP;
            END IF;
          END IF;
        ELSE
          RAISE;
        END IF;
  END;
  percent_done := 0;
  job_state := 'UNDEFINED';
  WHILE (job_state != 'COMPLETED') AND (job_state != 'STOPPED') LOOP
    DBMS_DATAPUMP.GET_STATUS
    (
      H1
    , DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR +
      DBMS_DATAPUMP.KU$_STATUS_JOB_STATUS +
      DBMS_DATAPUMP.KU$_STATUS_WIP
    , -1
    , JOB_STATE,STS
    );
    js := sts.job_status;
    IF js.percent_done != percent_done
    THEN
      DBMS_OUTPUT.PUT_LINE
      (
        '*** Job percent done = ' ||
        TO_CHAR ( js.percent_done )
      );
      percent_done := js.percent_done;
    END IF;
    IF (BITAND(sts.mask,dbms_datapump.ku$_status_wip) != 0)
    THEN
      le := sts.wip;
    ELSE
      IF ( BITAND ( sts.mask,dbms_datapump.ku$_status_job_error ) != 0 )
      THEN
        le := sts.error;
      ELSE
        le := NULL;
      END IF;
    END IF;
    IF le IS NOT NULL
    THEN
      ind := le.FIRST;
      WHILE ind IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE ( le(ind).LogText );
        ind := le.NEXT ( ind );
      END LOOP;
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE ( 'Job has completed' );
  DBMS_OUTPUT.PUT_LINE ( 'Final job state = ' || job_state );
  DBMS_DATAPUMP.DETACH ( h1 );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE ( 'Exception in Data Pump job' );
      DBMS_DATAPUMP.GET_STATUS
      (
        h1
      , DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR
      , 0
      , job_state
      , sts
      );
      IF (BITAND(sts.mask,dbms_datapump.ku$_status_job_error) != 0)
      THEN
        le := sts.error;
        IF le IS NOT NULL
        THEN
          ind := le.FIRST;
          WHILE ind IS NOT NULL LOOP
            spos := 1;
            slen := LENGTH ( le(ind).LogText );
            IF slen > 255
            THEN
              slen := 255;
            END IF;
            WHILE slen > 0 LOOP
              DBMS_OUTPUT.PUT_LINE ( SUBSTR ( le(ind).LogText, spos, slen ));
              spos := spos + 255;
              slen := LENGTH ( le(ind).LogText ) + 1 - spos;
            END LOOP;
            ind := le.NEXT(ind);
          END LOOP;
        END IF;
      END IF;
END;
/
 
select * from dba_datapump_jobs;
select * from dba_datapump_sessions;
select * from dba_views where view_name like '%DATAPUMP%';
 
declare
  lv_handle number;
begin
  lv_handle := dbms_datapump.attach ( 'VS_JOB$_682','ADMJMH' );
  dbms_datapump.stop_job ( lv_handle,1,0 );
end;
/
 
-- Example modified from Oracle Documentation
-- Oracle Database Utilities, Oracle Part B14215-01
DECLARE
  lv_jobname                  VARCHAR2(30) := 'VS_'||DBMS_SCHEDULER.GENERATE_JOB_NAME;
  ind NUMBER;              -- Loop index
  h1 NUMBER;               -- Data Pump job handle
  percent_done NUMBER;     -- Percentage of job complete
  job_state VARCHAR2(30);  -- To keep track of job state
  le ku$_LogEntry;         -- For WIP and error messages
  js ku$_JobStatus;        -- The job status from get_status
  jd ku$_JobDesc;          -- The job description from get_status
  sts ku$_Status;          -- The status object returned by get_status
BEGIN
  h1 := DBMS_DATAPUMP.OPEN('IMPORT','FULL',NULL,lv_jobname);
  DBMS_DATAPUMP.ADD_FILE(h1,'video_store%U.dmp','WWEST_01');
  DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_SCHEMA','VIDEO_STORE','FRED');
  DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','SKIP');
  DBMS_DATAPUMP.SET_PARALLEL ( h1, 16 );
  DBMS_DATAPUMP.START_JOB(h1);
 percent_done := 0;
  job_state := 'UNDEFINED';
  while (job_state != 'COMPLETED') and (job_state != 'STOPPED') loop
    dbms_datapump.get_status(h1,
           dbms_datapump.ku$_status_job_error +
           dbms_datapump.ku$_status_job_status +
           dbms_datapump.ku$_status_wip,-1,job_state,sts);
    js := sts.job_status;
     if js.percent_done != percent_done
    then
      dbms_output.put_line('*** Job percent done = ' ||
                           to_char(js.percent_done));
      percent_done := js.percent_done;
    end if;
       if (bitand(sts.mask,dbms_datapump.ku$_status_wip) != 0)
    then
      le := sts.wip;
    else
      if (bitand(sts.mask,dbms_datapump.ku$_status_job_error) != 0)
      then
        le := sts.error;
      else
        le := null;
      end if;
    end if;
    if le is not null
    then
      ind := le.FIRST;
      while ind is not null loop
        dbms_output.put_line(le(ind).LogText);
        ind := le.NEXT(ind);
      end loop;
    end if;
  end loop;
  dbms_output.put_line('Job has completed');
  dbms_output.put_line('Final job state = ' || job_state);
  dbms_datapump.detach(h1);
END;
/