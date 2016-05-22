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
05/22/2014  JMH         To show users how the jarow_winkler function works.
****************************************************************************  */
-- place the englishWordList.dat in your data_pump_dir "or" create a new
-- directory.
 
CREATE TABLE EW (COLUMN1 VARCHAR2(20)) 
ORGANIZATION EXTERNAL 
( 
  TYPE ORACLE_LOADER 
  DEFAULT DIRECTORY DATA_PUMP_DIR 
  LOCATION 
  ( 
    DATA_PUMP_DIR: 'englishWordList.dat'
  ) 
) 
REJECT LIMIT unlimited;
 
CREATE OR REPLACE FUNCTION compare_me ( thing_1 IN VARCHAR2, thing_2 IN VARCHAR2 )
RETURN NUMBER
PARALLEL_ENABLE
DETERMINISTIC
AS
BEGIN
  RETURN utl_match.jaro_winkler_similarity ( NVL ( thing_1, ' ' ),
  NVL ( thing_2, ' ' ));
END;
/
 
WITH
litmus AS
(
  SELECT  ew1.column1 stuff1
       ,  ew2.column1 stuff2
       ,  compare_me ( ew1.column1, ew2.column1 ) cm
    FROM  ew ew1 cross join ew ew2
   WHERE  SUBSTR ( ew1.column1, 1, 1 ) IN ( 'a', 'A' )
     and  SUBSTR ( ew2.column1, 1, 1 ) IN ( 'a', 'A' )
)
SELECT  *
  FROM  litmus
 WHERE  cm > 95
;
