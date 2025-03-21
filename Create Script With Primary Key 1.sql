/*--SET SERVEROUTPUT ON;
--GET_TBL_NAME_WITH_PKEY
DECLARE
CreateScript CLOB:='CREATE TABLE ';
BEGIN

    FOR A IN (SELECT A.UI_TABLENAME SRC_TBL,A.UI_TABLENAME||'_MID' DEST_TBL,B.CONS  FROM PROJINT3.ED_EY_TABLES_CONFIG A
             LEFT JOIN (SELECT A.TABLE_NAME,LISTAGG(B.COLUMN_NAME,',') WITHIN GROUP(ORDER BY TO_NUMBER(B.POSITION)) CONS 
              FROM USER_CONSTRAINTS A JOIN USER_CONS_COLUMNS B ON A.TABLE_NAME = B.TABLE_NAME AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME WHERE A.CONSTRAINT_TYPE = 'P'
              GROUP BY A.TABLE_NAME) B ON A.UI_TABLENAME||'_MID' = B.TABLE_NAME
)
    LOOP
        CreateScript:='CREATE TABLE '||A.DEST_TBL||'(';
        FOR A1 IN (SELECT COLUMN_NAME,CASE WHEN DATA_TYPE LIKE '%DATE%' OR DATA_TYPE LIKE '%TIME%' THEN DATA_TYPE 
                                                ELSE DATA_TYPE||'('||
                                                    CASE WHEN DATA_TYPE = 'NUMBER' 
                                                         THEN DATA_LENGTH ELSE CHAR_LENGTH 
                                                    END||')' 
                                      END DATA_TYPE 
                    FROM ALL_TAB_COLS WHERE OWNER = 'ONECONNECT' AND TABLE_NAME = A.SRC_TBL ORDER BY TO_NUMBER(COLUMN_ID))
        LOOP
            CreateScript:=CreateScript||A1.COLUMN_NAME||' '||A1.DATA_TYPE||',';
        END LOOP;
--        DBMS_OUTPUT.PUT_LINE(CreateScript);
        CreateScript:=CreateScript||'CONSTRAINT '||A.DEST_TBL||'_PK PRIMARY KEY ('||A.CONS||'));';
        DBMS_OUTPUT.PUT_LINE(CreateScript);
    END LOOP;
    
END;*/



--SET SERVEROUTPUT ON;
--GET_TBL_NAME_WITH_PKEY
DECLARE
CreateScript CLOB:='CREATE TABLE ';
BEGIN

    FOR A IN (SELECT A.SRC_TBL,A.DEST_TBL,B.CONS FROM
                (SELECT 'PERSONAL_INFO' SRC_TBL,'PERSONAL_INFO_MID' DEST_TBL  FROM DUAL) A/*Update the name of the table for which the script is required*/
                LEFT JOIN (SELECT A.TABLE_NAME,LISTAGG(B.COLUMN_NAME,',') WITHIN GROUP(ORDER BY TO_NUMBER(B.POSITION)) CONS 
                FROM USER_CONSTRAINTS A JOIN USER_CONS_COLUMNS B ON A.TABLE_NAME = B.TABLE_NAME AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME WHERE A.CONSTRAINT_TYPE = 'P'
                GROUP BY A.TABLE_NAME) B ON A.SRC_TBL = B.TABLE_NAME
)
    LOOP
        CreateScript:='CREATE TABLE '||A.DEST_TBL||'(';
        FOR A1 IN (SELECT COLUMN_NAME,CASE WHEN DATA_TYPE LIKE '%DATE%' OR DATA_TYPE LIKE '%TIME%' THEN DATA_TYPE 
                                                ELSE DATA_TYPE||'('||
                                                    CASE WHEN DATA_TYPE = 'NUMBER' 
                                                         THEN DATA_LENGTH ELSE CHAR_LENGTH 
                                                    END||')' 
                                      END DATA_TYPE 
                    FROM ALL_TAB_COLS WHERE OWNER = USER/*need to Change Owner USER or etcetera..*/ AND TABLE_NAME = A.SRC_TBL ORDER BY TO_NUMBER(COLUMN_ID))
        LOOP
            CreateScript:=CreateScript||A1.COLUMN_NAME||' '||A1.DATA_TYPE||',';
        END LOOP;
--        DBMS_OUTPUT.PUT_LINE(CreateScript);
        CreateScript:=CreateScript||'CONSTRAINT '||A.DEST_TBL||'_PK PRIMARY KEY ('||A.CONS||'));';
		DBMS_OUTPUT.PUT_LINE('DROP TABLE ' ||A.DEST_TBL||';');
        DBMS_OUTPUT.PUT_LINE(CreateScript);
    END LOOP;
    
END;

-----------------------------------------------------------------------------------------

--UPDATED SCRIPT WITH PRIMARY KEY 
--SET SERVEROUTPUT ON;
--GET_TBL_NAME_WITH_PKEY
DECLARE
CreateScript CLOB;

BEGIN
     FOR A IN (WITH CTE_SRC_TBL AS 
                    (SELECT TABLE_NAME SRC_TBL, WORK_TBL_NAME DEST_TBL FROM TBL_UPD_DYNAMIC_INSERT WHERE PROJECT_ID='2000288')/*Update the name of the table for which the script is required*/
                    ,CTE_COLUMN_TBL AS (SELECT ATC.TABLE_NAME,LISTAGG(ATC.COLUMN_NAME ||' '||CASE WHEN ATC.DATA_TYPE LIKE '%DATE%' OR ATC.DATA_TYPE LIKE '%TIMESTAMP%' THEN ATC.DATA_TYPE
                                                               ELSE ATC.DATA_TYPE ||'('||
                                                               CASE WHEN ATC.DATA_TYPE LIKE '%NUMBER%' OR ATC.DATA_TYPE LIKE'%FLOAT%' THEN ATC.DATA_LENGTH
                                                               ELSE ATC.CHAR_LENGTH
                                                               END ||')'
                                                               END,',') WITHIN GROUP (ORDER BY ATC.COLUMN_ID)COLUMN_DET
                                             FROM ALL_TAB_COLS ATC
                                             JOIN CTE_SRC_TBL CST ON CST.SRC_TBL=ATC.TABLE_NAME
                                             WHERE OWNER=USER AND ATC.TABLE_NAME=CST.SRC_TBL AND ATC.USER_GENERATED='YES' GROUP BY ATC.TABLE_NAME),
                    CTE_CONS_COLUMNS AS (SELECT A.TABLE_NAME,LISTAGG(B.COLUMN_NAME,',') WITHIN GROUP(ORDER BY TO_NUMBER(B.POSITION)) CONS 
                                    FROM USER_CONSTRAINTS A 
                                    JOIN CTE_SRC_TBL C ON C.SRC_TBL=A.TABLE_NAME
                                    JOIN USER_CONS_COLUMNS B ON A.TABLE_NAME = B.TABLE_NAME AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME 
                                    WHERE A.CONSTRAINT_TYPE = 'P' AND A.TABLE_NAME=C.SRC_TBL
                                    GROUP BY A.TABLE_NAME)                         
                    SELECT A.SRC_TBL,A.DEST_TBL,B.COLUMN_DET,C.CONS  FROM CTE_SRC_TBL A
                    JOIN CTE_COLUMN_TBL B ON B.TABLE_NAME=A.SRC_TBL
                    JOIN CTE_CONS_COLUMNS C ON C.TABLE_NAME= A.SRC_TBL)
                
        LOOP
         CreateScript:='CREATE TABLE '||A.DEST_TBL||' ('||A.COLUMN_DET||',CONSTRAINT '||A.DEST_TBL||'_PK PRIMARY KEY ('||A.CONS||'));';
         DBMS_OUTPUT.PUT_LINE(CreateScript) ;
        END LOOP;
END;


----------------------------------------------------------------------------------------

--SET SERVEROUTPUT ON;
DECLARE
CreateScript CLOB;

BEGIN
     FOR A IN (WITH CTE_SRC_TBL AS 
                (SELECT TABLE_NAME SRC_TBL, WORK_TBL_NAME DEST_TBL FROM TBL_UPD_DYNAMIC_INSERT WHERE PROJECT_ID='2000288')/*Update the name of the table for which the script is required*/
                ,CTE_COLUMN_TBL AS (SELECT ATC.TABLE_NAME,LISTAGG(ATC.COLUMN_NAME ||' '||CASE WHEN ATC.DATA_TYPE LIKE '%DATE%' OR ATC.DATA_TYPE LIKE '%TIMESTAMP%' THEN ATC.DATA_TYPE
                                                           ELSE ATC.DATA_TYPE ||'('||
                                                           CASE WHEN ATC.DATA_TYPE LIKE '%NUMBER%' OR ATC.DATA_TYPE LIKE'%FLOAT%' THEN ATC.DATA_LENGTH
                                                           ELSE ATC.CHAR_LENGTH
                                                           END ||')'
                                                           END,',') WITHIN GROUP (ORDER BY ATC.COLUMN_ID)COLUMN_DET,PC.CONS
                                         FROM ALL_TAB_COLS ATC
                                         JOIN CTE_SRC_TBL CST ON CST.SRC_TBL=ATC.TABLE_NAME
                                         JOIN (SELECT A.TABLE_NAME,LISTAGG(B.COLUMN_NAME,',') WITHIN GROUP(ORDER BY TO_NUMBER(B.POSITION)) CONS 
                                                FROM USER_CONSTRAINTS A JOIN USER_CONS_COLUMNS B ON A.TABLE_NAME = B.TABLE_NAME AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME 
                                                WHERE A.CONSTRAINT_TYPE = 'P' GROUP BY A.TABLE_NAME)PC ON PC.TABLE_NAME=ATC.TABLE_NAME
                                         WHERE OWNER=USER AND ATC.TABLE_NAME=CST.SRC_TBL AND ATC.USER_GENERATED='YES' GROUP BY ATC.TABLE_NAME,PC.CONS)                         
                SELECT A.SRC_TBL,A.DEST_TBL,B.COLUMN_DET,B.CONS  FROM CTE_SRC_TBL A
                JOIN CTE_COLUMN_TBL B ON B.TABLE_NAME=A.SRC_TBL)
                
        LOOP
         CreateScript:='CREATE TABLE '||A.DEST_TBL||' ('||A.COLUMN_DET||',CONSTRAINT '||A.DEST_TBL||'_PK PRIMARY KEY ('||A.CONS||'));';
         DBMS_OUTPUT.PUT_LINE(CreateScript) ;
        END LOOP;
END;