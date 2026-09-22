/*

Reproduce, de forma simplificada, los servicios transversales que en un proyecto real ofrece la
plataforma de datos y que TODO desarrollo BI utiliza:

  1) ETL_EVENT_LOG           -> log de ejecuciones (inicio/fin/estado) de las cargas.
  2) P_ETL_EVENT_START/END   -> procedimientos para registrar inicio y fin de una carga.
  3) TAG SENSITIVITY_TYPE    -> etiqueta de sensibilidad (OPCIONAL, solo Enterprise; va comentada).
  4) ROLE_STORE_ACCESS       -> tabla de permisos para SIMULAR la seguridad a nivel de fila.
                                (La vista V_STORE_ACCESS se crea en 02, porque depende de DIM_STORE.)

En el proyecto real estos objetos viven en esquemas de arquitectura/plataforma y son de solo
lectura para el equipo BI. Aquí se crean como mock para poder ejecutar y alertar el pipeline.
====================================================================================================
*/

USE DATABASE PLATFORM;
USE SCHEMA PLATFORM.GOVERNANCE;

----------------------------------------------------------------------------------------------------
-- 1) LOG DE EJECUCIONES ETL
----------------------------------------------------------------------------------------------------
-- Cada carga registra aquí una fila al empezar (STATE='RUNNING') y la actualiza al terminar
-- (STATE='SUCCESS' o 'ERROR'). El alertado consulta esta tabla para saber si una task ha corrido.

CREATE TABLE IF NOT EXISTS PLATFORM.GOVERNANCE.ETL_EVENT_LOG (
    EVENT_ID      NUMBER(38,0) AUTOINCREMENT,
    OBJECT_NAME   VARCHAR,          -- objeto que se está cargando (p.ej. la tabla FACT)
    TASK_NAME     VARCHAR,          -- nombre de la task que lanza la carga
    SCHEMA_NAME   VARCHAR,          -- esquema del objeto/task
    STATE         VARCHAR,          -- RUNNING | SUCCESS | ERROR
    START_TIME    TIMESTAMP_LTZ,
    END_TIME      TIMESTAMP_LTZ,
    ROWS_AFFECTED NUMBER(38,0),
    MESSAGE       VARCHAR
);

----------------------------------------------------------------------------------------------------
-- 2) PROCEDIMIENTOS DE REGISTRO DE EVENTOS
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PLATFORM.GOVERNANCE.P_ETL_EVENT_START(OBJECT_NAME VARCHAR)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
DECLARE
    NEW_EVENT_ID NUMBER;
    SCHEMA_PART  VARCHAR;
BEGIN
    -- Extrae el nombre de esquema del objeto totalmente cualificado (DB.SCHEMA.OBJETO)
    SCHEMA_PART := SPLIT_PART(:OBJECT_NAME, '.', 2);

    INSERT INTO PLATFORM.GOVERNANCE.ETL_EVENT_LOG (OBJECT_NAME, SCHEMA_NAME, STATE, START_TIME)
    VALUES (:OBJECT_NAME, :SCHEMA_PART, 'RUNNING', CURRENT_TIMESTAMP());

    NEW_EVENT_ID := (SELECT MAX(EVENT_ID) FROM PLATFORM.GOVERNANCE.ETL_EVENT_LOG);
    RETURN NEW_EVENT_ID;
END;
$$
;

CREATE OR REPLACE PROCEDURE PLATFORM.GOVERNANCE.P_ETL_EVENT_END(
    EVENT_ID NUMBER, TASK_NAME VARCHAR, STATE VARCHAR, ROWS_AFFECTED NUMBER, MESSAGE VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE PLATFORM.GOVERNANCE.ETL_EVENT_LOG
       SET END_TIME      = CURRENT_TIMESTAMP(),
           TASK_NAME     = :TASK_NAME,
           STATE         = :STATE,
           ROWS_AFFECTED = :ROWS_AFFECTED,
           MESSAGE       = :MESSAGE
     WHERE EVENT_ID = :EVENT_ID;
    RETURN 'OK';
END;
$$
;

----------------------------------------------------------------------------------------------------
-- 3) TAG DE SENSIBILIDAD (GOBIERNO DEL DATO)  --  [OPCIONAL: SOLO SNOWFLAKE ENTERPRISE EDITION]
----------------------------------------------------------------------------------------------------
-- En el proyecto real las tablas y vistas se etiquetan con su nivel de sensibilidad.
-- OJO: el "object tagging" (CREATE TAG / SET TAG) es una feature de ENTERPRISE EDITION.
-- En una cuenta trial STANDARD estas sentencias FALLAN, por eso van COMENTADAS por defecto.
-- Si tu cuenta es Enterprise Edition y quieres practicarlo, descomenta este bloque y también los
-- "ALTER ... SET TAG" de la tabla FACT y de la vista. Si no, trátalo como material teórico.
/*
CREATE TAG IF NOT EXISTS PLATFORM.GOVERNANCE.SENSITIVITY_TYPE
    COMMENT = 'Nivel de sensibilidad del dato: PUBLICA | DEPARTAMENTAL | RESTRINGIDA';
*/

----------------------------------------------------------------------------------------------------
-- 4) ENTITLEMENTS PARA SEGURIDAD A NIVEL DE FILA  --  [SIMULACIÓN, ejecutable en CUALQUIER edición]
----------------------------------------------------------------------------------------------------
-- En el proyecto real la seguridad de fila se hace con una ROW ACCESS POLICY (feature ENTERPRISE).
-- Como en una cuenta trial Standard eso no está disponible, aquí la SIMULAMOS con SQL estándar:
-- una tabla de permisos + una vista de entitlements a la que la vista pública se une con un JOIN.
-- Esto funciona en cualquier edición y se puede probar de verdad en el laboratorio.
CREATE TABLE IF NOT EXISTS PLATFORM.GOVERNANCE.ROLE_STORE_ACCESS (
    ROLE_NAME VARCHAR,
    ID_STORE  NUMBER(38,0)   -- NULL = acceso a todas las tiendas
);

-- Por defecto: SYSADMIN y ACCOUNTADMIN ven todas las tiendas (ID_STORE = NULL).
MERGE INTO PLATFORM.GOVERNANCE.ROLE_STORE_ACCESS t
USING (SELECT 'SYSADMIN' AS ROLE_NAME UNION ALL SELECT 'ACCOUNTADMIN') s
   ON t.ROLE_NAME = s.ROLE_NAME
 WHEN NOT MATCHED THEN INSERT (ROLE_NAME, ID_STORE) VALUES (s.ROLE_NAME, NULL);

-- Concede acceso total al ROL ACTUAL (sea cual sea) para que el ejercicio "funcione solo",
-- independientemente del rol con el que el alumno ejecute el bootcamp.
INSERT INTO PLATFORM.GOVERNANCE.ROLE_STORE_ACCESS (ROLE_NAME, ID_STORE)
SELECT CURRENT_ROLE(), NULL
WHERE NOT EXISTS (
    SELECT 1 FROM PLATFORM.GOVERNANCE.ROLE_STORE_ACCESS WHERE ROLE_NAME = CURRENT_ROLE()
);

-- NOTA: la vista de entitlements V_STORE_ACCESS se crea en 02_mock_sources.sql, porque necesita
-- que YA exista el maestro de tiendas RETAIL_LAKE.SALES_SHARING.DIM_STORE (dependencia de orden).
