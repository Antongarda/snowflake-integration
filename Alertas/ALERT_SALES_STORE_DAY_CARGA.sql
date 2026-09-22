/*
====================================================================================================
 ALERTA: ejecución de la carga del FACT de ventas
 Regla: ALERT_SALES_STORE_DAY_CARGA.sql
====================================================================================================

*/

WITH EJECUCIONES_EXITOSAS AS (
    SELECT STATE, TASK_NAME, SCHEMA_NAME, END_TIME
    FROM PLATFORM.GOVERNANCE.ETL_EVENT_LOG 
    WHERE TASK_NAME='TSK_LOAD_FACT_AGGR_SALES_STORE_DAY'
    AND STATE = 'SUCCESS'
    AND END_TIME> DATEADD ( MINUTE, -60, CURRENT_TIMESTAMP())
)
SELECT 
    'ERROR' as ALERTA,
    'Sin carga exitosa' as MENSAJE,
    CURRENT_TIMESTAMP() as CHECK_TIME
FROM EJECUCIONES_EXITOSAS 
HAVING COUNT(*)=0;

