/*

Reproduce los orígenes que el equipo BI consumiría de otros equipos. Contienen POCAS filas,
suficientes para validar la lógica de la carga.

  - DIM_STORE          : maestro de tiendas (con estado abierto/cerrado)  -- CON datos semilla
  - DIM_ARTICLE        : maestro de artículos (sección y familia)         -- CON datos semilla
  - SALES_TICKET_LINE  : líneas de ticket de venta (dato transaccional)   -- SE CREA VACÍA

IMPORTANTE:
  - SALES_TICKET_LINE tiene CHANGE_TRACKING = TRUE para poder crear un STREAM sobre ella.
  - Las VENTAS (filas de SALES_TICKET_LINE) NO se cargan aquí, sino en 03_generate_sales.sql, que se
    ejecuta DESPUÉS de crear el stream. Un stream solo captura los cambios posteriores a su creación;
    si insertáramos las ventas ahora, el stream no las vería y la primera carga saldría vacía.
====================================================================================================
*/

USE DATABASE RETAIL_LAKE;
USE SCHEMA RETAIL_LAKE.SALES_SHARING;

----------------------------------------------------------------------------------------------------
-- DIM_STORE: maestro de tiendas
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE RETAIL_LAKE.SALES_SHARING.DIM_STORE (
    ID_STORE        NUMBER(38,0),
    DESC_STORE      VARCHAR,
    ID_COUNTRY      NUMBER(38,0),
    ID_STORE_STATUS NUMBER(38,0)   -- 1 = ABIERTA, 2 = CERRADA
);

INSERT INTO RETAIL_LAKE.SALES_SHARING.DIM_STORE (ID_STORE, DESC_STORE, ID_COUNTRY, ID_STORE_STATUS) VALUES
    (1001, 'ACME Madrid Centro',   34, 1),
    (1002, 'ACME Barcelona Diagonal', 34, 1),
    (1003, 'ACME Lisboa Baixa',     351, 1),
    (1004, 'ACME Paris Rivoli',     33, 1),
    (1005, 'ACME Oporto (cerrada)', 351, 2);   -- tienda cerrada: NO debe entrar en el FACT

----------------------------------------------------------------------------------------------------
-- DIM_ARTICLE: maestro de artículos
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE RETAIL_LAKE.SALES_SHARING.DIM_ARTICLE (
    ID_ARTICLE   NUMBER(38,0),
    DESC_ARTICLE VARCHAR,
    ID_SECTION   NUMBER(38,0),   -- 1 = MUJER, 2 = HOMBRE, 3 = NIÑO
    ID_FAMILY    NUMBER(38,0)
);

INSERT INTO RETAIL_LAKE.SALES_SHARING.DIM_ARTICLE (ID_ARTICLE, DESC_ARTICLE, ID_SECTION, ID_FAMILY) VALUES
    (5001, 'Camiseta básica mujer',  1, 10),
    (5002, 'Vaquero slim mujer',     1, 11),
    (5003, 'Camisa oxford hombre',   2, 20),
    (5004, 'Chaqueta punto hombre',  2, 21),
    (5005, 'Sudadera niño',          3, 30);

----------------------------------------------------------------------------------------------------
-- SALES_TICKET_LINE: líneas de ticket de venta (dato transaccional)
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE RETAIL_LAKE.SALES_SHARING.SALES_TICKET_LINE (
    ID_TICKET       NUMBER(38,0),
    ID_TICKET_LINE  NUMBER(38,0),
    ID_STORE        NUMBER(38,0),
    ID_ARTICLE      NUMBER(38,0),
    SALE_DATE       DATE,
    SOLD_UNITS      NUMBER(38,0),
    GROSS_AMOUNT    NUMBER(38,2),
    DISCOUNT_AMOUNT NUMBER(38,2)
);

-- Habilitamos change tracking para poder construir un STREAM encima (CDC).
ALTER TABLE RETAIL_LAKE.SALES_SHARING.SALES_TICKET_LINE SET CHANGE_TRACKING = TRUE;

-- OJO: la tabla se deja VACÍA a propósito. Las ventas se generan en 03_generate_sales.sql, DESPUÉS
-- de que el alumno haya creado el STREAM, para que este las capture (ver nota de la cabecera).

----------------------------------------------------------------------------------------------------
-- ENTITLEMENTS: vista de seguridad de fila (SIMULACIÓN) -- depende de DIM_STORE, por eso va aquí
----------------------------------------------------------------------------------------------------
-- Devuelve las tiendas visibles para el rol actual. La vista pública V_FACT_AGGR_SALES_STORE_DAY
-- hace INNER JOIN con esta vista para aplicar seguridad a nivel de fila SIN Row Access Policy
-- (es decir, ejecutable en cualquier edición de Snowflake, incluida una trial Standard).
CREATE OR REPLACE VIEW PLATFORM.GOVERNANCE.V_STORE_ACCESS AS
SELECT DISTINCT s.ID_STORE
FROM RETAIL_LAKE.SALES_SHARING.DIM_STORE s
WHERE EXISTS (
    SELECT 1
    FROM PLATFORM.GOVERNANCE.ROLE_STORE_ACCESS a
    WHERE a.ROLE_NAME = CURRENT_ROLE()
      AND (a.ID_STORE IS NULL OR a.ID_STORE = s.ID_STORE)
);
