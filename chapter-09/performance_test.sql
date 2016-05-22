/*  ****************************************************************************
--------------------------------------------------------------------------------
FILENAME:   ch_09_performance_test.sql
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
CREATE TABLE rental_item_fact
(
  person_id       INTEGER
, item_id         INTEGER
, order_id        INTEGER
, promo_id        INTEGER
, currency_id     INTEGER
, date_key        DATE
, order_line      INTEGER
, item_qty        INTEGER
, item_price      NUMBER
, line_total      NUMBER
)
PARALLEL 32
TABLESPACE fio_001
;
 
DECLARE
  CURSOR C IS
    WITH order_line AS
    (
      SELECT  ROUND ( DBMS_RANDOM.VALUE ( 1, 5000000        )) person_id
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 10000          )) item_id
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 20000000       )) order_id
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 100            )) promo_id
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 5              )) currency_id
           ,  SYSDATE - ROUND ( DBMS_RANDOM.VALUE ( 1, 1825 )) date_key
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 10             )) order_line
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 10             )) item_qty
           ,  ROUND ( DBMS_RANDOM.VALUE ( 1, 150 ), 4        ) item_price
        FROM  iterator_100000000_32p
    )
    SELECT  ol.*
         ,  ol.item_qty * ol.item_price line_total
      FROM  order_line ol;
 
  TYPE UDT_RIF IS TABLE OF c%rowtype
    INDEX BY PLS_INTEGER;
   
  lv_rif udt_rif;
BEGIN
  OPEN C;
    LOOP
      FETCH C BULK COLLECT
       INTO lv_rif
      LIMIT 1000;
       
      FORALL A IN 1 .. LV_RIF.COUNT
        INSERT /*+ APPEND */ INTO rental_item_fact
        VALUES
        (
          lv_rif(a).person_id
        , lv_rif(a).item_id
        , lv_rif(a).order_id
        , lv_rif(a).promo_id
        , lv_rif(a).currency_id
        , lv_rif(a).date_key
        , lv_rif(a).order_line
        , lv_rif(a).item_qty
        , lv_rif(a).item_price
        , lv_rif(a).line_total
        );
       
      EXIT WHEN C%notfound;
    END LOOP;
  CLOSE C;
  COMMIT;
END;
/
 
CREATE BIGFILE TABLESPACE SAS_001 
    DATAFILE 
        '/u01/admin/SaS/SAS_001.DBF' SIZE 107374182400 AUTOEXTEND ON NEXT 10737418240 MAXSIZE 214748364800 
    DEFAULT COMPRESS FOR OLTP 
    ONLINE 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
 
drop index rif_person_id_bmix;
drop index rif_item_id_bmix;
drop index rif_order_id_bmix;
drop index rif_promo_id_bmix;
drop index rif_currency_id_bmix;
drop index rif_date_key_bmix;
 
create bitmap index rif_person_id_bmix on rental_item_fact ( person_id ) tablespace SAS_001;
create bitmap index rif_item_id_bmix on rental_item_fact ( item_id ) tablespace SAS_001;
create bitmap index rif_order_id_bmix on rental_item_fact ( order_id ) tablespace SAS_001;
create bitmap index rif_promo_id_bmix on rental_item_fact ( promo_id ) tablespace SAS_001;
create bitmap index rif_currency_id_bmix on rental_item_fact ( currency_id ) tablespace SAS_001;
create bitmap index rif_date_key_bmix on rental_item_fact ( date_key ) tablespace SAS_001;
 
DECLARE
  CURSOR C IS
    SELECT  owner
         ,  index_name
      FROM  dba_indexes
     WHERE  owner = 'ADMJMH'
       AND  table_name = 'RENTAL_ITEM_FACT'
       AND  index_type = 'BITMAP';
 
  lv_sql VARCHAR2(4000);
  lv_job VARCHAR2(30);
BEGIN
  FOR R IN C LOOP
    lv_sql := ' begin execute immediate ''alter index $1.$2 rebuild nologging compute statistics tablespace fio_001''; end;';
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$1', r.owner );
    lv_sql := REGEXP_REPLACE ( lv_sql, '\$2', r.index_name );
    lv_job := r.index_name||TO_CHAR ( SYSDATE, 'HHMISS' );
 
    DBMS_OUTPUT.PUT_LINE ( lv_sql );
     
    DBMS_SCHEDULER.CREATE_JOB
    (
      JOB_NAME   => lv_job
    , JOB_TYPE   => 'PLSQL_BLOCK'
    , JOB_ACTION => lv_sql
    , ENABLED    => true
    , AUTO_DROP  => true
    );
  END LOOP;
END;
/
 
select * from dba_scheduler_jobs where owner = 'ADMJMH';
select * from dba_scheduler_running_jobs where owner = 'ADMJMH';
select substr ( to_char ( run_duration, 'HH:MI:SS.FF' ), 5 ) parallel_fio, dsjrd.* from dba_scheduler_job_run_details dsjrd where owner = 'ADMJMH' order by req_start_date, job_name;
select index_name, tablespace_name, distinct_keys, status from dba_indexes where owner = 'ADMJMH' and index_name like 'RIF%';
 
 
BEGIN
  dbms_scheduler.purge_log;
END;
/