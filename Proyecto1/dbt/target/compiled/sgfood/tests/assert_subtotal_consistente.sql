-- Regla de calidad (casos_calidad: cantidad/descuento/subtotal):
-- ninguna línea con subtotal fuente distinto al recalculado (tolerancia 1ctv).
-- El test pasa si la consulta devuelve 0 filas.
select
    id_detalle,
    subtotal_fuente,
    subtotal_calculado
from "sgfood"."intermediate"."int_ventas_detalle"
where abs(subtotal_fuente - subtotal_calculado) > 0.01