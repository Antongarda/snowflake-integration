/*
# [PUBLIC] ACME.ACME_BI_DATA.FACT_AGGR_SALES_STORE_DAY

## Descripción
Tabla FACT que almacena las ventas agregadas por día, tienda y sección de producto.


## Columnas
- ID_DATE:     Fecha de venta
- ID_STORE:    Tienda (solo tiendas ABIERTAS)
- ID_SECTION:  Sección de producto
- SOLD_UNITS:  Unidades vendidas
- NET_AMOUNT:  Importe neto vendido (bruto - descuento)

## Granularidad
 Tenemos una fila para cada (ID_DATE, ID_STORE, ID_SECTION)

##Origen 
Migración de datos de la tabla : RETAIL_LAKE.SALES_SHARING.SALES_TICKET_LINE 

##Versiones
17-09-2026 : Versión Inicial

*/

CREATE TRANSIENT TABLE IF NOT EXISTS ACME.ACME_BI_DATA.FACT_AGGR_SALES_STORE_DAY(
    ID_DATE DATE,
    ID_STORE NUMBER(38,0),
    ID_SECTION NUMBER(38,0),
    SOLD_UNITS NUMBER(38,0),
    NET_AMOUNT NUMBER(38,2)
)

