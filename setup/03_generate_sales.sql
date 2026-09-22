/*


Un STREAM solo captura los cambios que ocurren DESPUÉS de haber sido creado. Si las ventas se
insertaran en el setup inicial (antes de que exista el stream), el stream "no las vería" y la primera
carga saldría vacía. Por eso este script:

  - Se ejecuta DESPUÉS de que hayas creado el stream STR_SALES_TICKET_LINE (parte del desarrollo).
  - Simula la "llegada" de ventas nuevas al lake, que es justo lo que el stream debe capturar.


====================================================================================================
*/

USE DATABASE RETAIL_LAKE;
USE SCHEMA RETAIL_LAKE.SALES_SHARING;

-- Comprobación opcional: el stream debe existir ANTES de ejecutar este INSERT.
-- Si esta consulta da error "does not exist", primero crea el stream y vuelve aquí.
SHOW STREAMS LIKE 'STR_SALES_TICKET_LINE' IN SCHEMA ACME.ACME_BI_DATA;

----------------------------------------------------------------------------------------------------
-- Ventas de 2 días para varias tiendas/artículos (dato transaccional que "llega" al lake)
----------------------------------------------------------------------------------------------------
INSERT INTO RETAIL_LAKE.SALES_SHARING.SALES_TICKET_LINE
    (ID_TICKET, ID_TICKET_LINE, ID_STORE, ID_ARTICLE, SALE_DATE, SOLD_UNITS, GROSS_AMOUNT, DISCOUNT_AMOUNT) VALUES
    (900001, 1, 1001, 5001, '2026-06-01', 2, 39.90, 0.00),
    (900001, 2, 1001, 5002, '2026-06-01', 1, 49.95, 5.00),
    (900002, 1, 1002, 5003, '2026-06-01', 3, 89.85, 9.00),
    (900003, 1, 1003, 5005, '2026-06-01', 5, 99.75, 0.00),
    (900004, 1, 1004, 5004, '2026-06-02', 1, 59.90, 0.00),
    (900005, 1, 1001, 5001, '2026-06-02', 4, 79.80, 8.00),
    (900006, 1, 1002, 5002, '2026-06-02', 2, 99.90, 0.00),
    -- Venta en tienda CERRADA (1005): debe quedar EXCLUIDA del FACT por la regla de negocio.
    (900007, 1, 1005, 5003, '2026-06-02', 9, 269.55, 0.00);



