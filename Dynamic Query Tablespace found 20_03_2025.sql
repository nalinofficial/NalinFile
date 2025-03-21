DROP TABLE DB_ALL_TABLES_SPACE;
CREATE TABLE DB_ALL_TABLES_SPACE (
COUNTRY_NAME NVARCHAR2(50),
TOTAL_TABLES_COUNT NVARCHAR2(50),
SPACE_OCCUPIED_TABLE_COUNT NVARCHAR2(50),
TABLESPACE_OCCUPIED_BY_GB NUMBER,
LAST_ANALYSED_DATE DATE
);

CREATE TABLE TBL_LIST_GREATER_THAN_GB (
COUNTRY_NAME NVARCHAR2(50),
TABLE_NAME NVARCHAR2(50),
TABLESPACE_OCCUPIED_BY_GB NUMBER,
STATUS NVARCHAR2(100),
LAST_ANALYSED_DATE DATE
);

CREATE TABLE DBA_COUNTRY_DB_LINKS(
COUNTRY_NAME       NVARCHAR2(50),  
LINK_NAME          NVARCHAR2(100), 
SCHEMA_NAME        NVARCHAR2(50),  
TABLE_NAME         NVARCHAR2(100),
CONSTRAINT DBA_COUNTRY_DB_LINKS_PK PRIMARY KEY (COUNTRY_NAME))

-----------------------------------------------------------------------------------------------------------------------------------------------
/*Note:* Every Time Replace the Project Name */
--SET SERVEROUTPUT ON;
DECLARE
    InsertScript  CLOB;
	Project_Name Nvarchar2(50):='UMG - ';
BEGIN
    --DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE DB_ALL_TABLES_SPACE');
	  EXECUTE IMMEDIATE('TRUNCATE TABLE DB_ALL_TABLES_SPACE');
	  
    FOR A IN (SELECT COUNTRY_NAME, LINK_NAME,SCHEMA_NAME FROM DBA_COUNTRY_DB_LINKS ) 
	LOOP
        InsertScript := 'INSERT INTO DB_ALL_TABLES_SPACE 
                  SELECT '''||Project_Name || UPPER(A.COUNTRY_NAME) || '''COUNTRY_NAME,B.TOTAL_TABLES_COUNT, COUNT(*) SPACE_OCCUPIED_TABLE_COUNT,
                  SUM(A.BYTES) / (1024 * 1024 * 1024) AS TABLESPACE_OCCUPIED_BY_GB,CURRENT_DATE LAST_ANALYSED_DATE
                  FROM '||CASE WHEN UPPER(A.COUNTRY_NAME) IN ('ONECONNECT','DASHBOARDPROD','EIBP19C','EIBQ19C','ONECONNECT_PROD')THEN ' USER_SEGMENTS ' ELSE 'USER_SEGMENTS@' END || UPPER(A.LINK_NAME)||' A 
                  LEFT JOIN (SELECT ''' || UPPER(A.COUNTRY_NAME) || ''',COUNT(*)TOTAL_TABLES_COUNT 
                             FROM ALL_TABLES 
                             WHERE OWNER='||CASE WHEN UPPER(A.COUNTRY_NAME) IN ('ONECONNECT','DASHBOARDPROD','EIBP19C','EIBQ19C','ONECONNECT_PROD')THEN 'USER' ELSE ''''||UPPER(A.SCHEMA_NAME)||'''' END||'
                            )B ON 1=1 
                  WHERE SEGMENT_TYPE=''TABLE'' GROUP BY B.TOTAL_TABLES_COUNT ';
        --DBMS_OUTPUT.PUT_LINE (InsertScript);
        EXECUTE IMMEDIATE InsertScript;
        COMMIT;

    END LOOP;
END;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--LOAD_INSERT_MORETN_TBl_GB
--SET SERVEROUTPUT ON;
DECLARE
    InsertScript  CLOB;
    Project_Name Nvarchar2(50):='UMG - ';
	
BEGIN
		--DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE TBL_LIST_GREATER_THAN_GB');
	      EXECUTE IMMEDIATE('TRUNCATE TABLE TBL_LIST_GREATER_THAN_GB');
		  
    FOR A IN (SELECT COUNTRY_NAME, LINK_NAME,SCHEMA_NAME FROM DBA_COUNTRY_DB_LINKS ) 
	LOOP
        InsertScript := 'INSERT INTO TBL_LIST_GREATER_THAN_GB
                            SELECT 
                            COUNTRY_NAME,TABLE_NAME,TABLESPACE_OCCUPIED_BY_GB,
                            ''The Tables are available in Greater than ''||ROUND(TABLESPACE_OCCUPIED_BY_GB,2)||'' Gb''STATUS, 
                            LAST_ANALYSED_DATE 
                            FROM (SELECT '''||Project_Name || UPPER(A.COUNTRY_NAME) ||'''COUNTRY_NAME,SEGMENT_NAME TABLE_NAME,
                            SUM(BYTES) / (1024 * 1024 * 1024) AS TABLESPACE_OCCUPIED_BY_GB ,CURRENT_DATE LAST_ANALYSED_DATE 
                            FROM '||CASE WHEN UPPER(A.COUNTRY_NAME) IN ('ONECONNECT','DASHBOARDPROD','EIBP19C','EIBQ19C','ONECONNECT_PROD')THEN ' USER_SEGMENTS ' ELSE 'USER_SEGMENTS@' END || UPPER(A.LINK_NAME)||' A 
                            GROUP BY SEGMENT_NAME
                                 )
                            WHERE TABLESPACE_OCCUPIED_BY_GB>1
                  
                        ';
        --DBMS_OUTPUT.PUT_LINE (InsertScript);
        EXECUTE IMMEDIATE InsertScript;
        COMMIT;

    END LOOP;
END;
/