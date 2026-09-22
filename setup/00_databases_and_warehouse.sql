/*

Este script crea la infraestructura mínima para reproducir, en cualquier cuenta de Snowflake,
la arquitectura de un desarrollo BI real (versión anonimizada y didáctica).

Equivalencias con un proyecto real (nombres cambiados por mocks):
  - RETAIL_LAKE.SALES_SHARING   <-> capa compartida de orígenes (p.ej. UNIFIED_DATA.*_SHARING)
  - ACME.ACME_BI_DATA           <-> capa de datos BI: tablas FACT, procedimientos, tasks, streams
  - ACME.ACME_BI                <-> capa pública de vistas para PowerBI
  - PLATFORM.GOVERNANCE         <-> capa de plataforma: log de ETL, tags, control de accesos
  - ACME_PIPELINE_WH            <-> warehouse dedicado a la ejecución de los pipelines


====================================================================================================
*/

-- Warehouse de ejecución de pipelines ----------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS ACME_PIPELINE_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse para la ejecución de los pipelines del bootcamp ACME_RETAIL';

-- Base de datos de orígenes (capa compartida / lake) --------------------------------------------
CREATE DATABASE IF NOT EXISTS RETAIL_LAKE
    COMMENT = 'Mock de la capa de orígenes compartidos (equivalente a un lake / *_SHARING)';
CREATE SCHEMA IF NOT EXISTS RETAIL_LAKE.SALES_SHARING
    COMMENT = 'Orígenes de datos de ventas compartidos por otros equipos';

-- Base de datos del proyecto BI -----------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ACME
    COMMENT = 'Base de datos del proyecto BI de ACME_RETAIL';
CREATE SCHEMA IF NOT EXISTS ACME.ACME_BI_DATA
    COMMENT = 'Capa de datos: tablas FACT, procedimientos, tasks y streams';
CREATE SCHEMA IF NOT EXISTS ACME.ACME_BI
    COMMENT = 'Capa pública de vistas para informes de PowerBI';

-- Base de datos de plataforma / gobierno --------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PLATFORM
    COMMENT = 'Mock de la capa de plataforma / gobierno del dato';
CREATE SCHEMA IF NOT EXISTS PLATFORM.GOVERNANCE
    COMMENT = 'Log de ejecuciones ETL, tags de sensibilidad y control de accesos';



