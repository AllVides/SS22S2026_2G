-- Regla de negocio (casos_calidad: "Devolución superior a venta"):
-- lo devuelto por venta+producto nunca supera lo vendido.
-- El test pasa si la consulta devuelve 0 filas.
with vendido as (
    select id_venta, id_producto, sum(cantidad) as unidades_vendidas
    from "sgfood"."intermediate"."int_ventas_detalle"
    group by 1, 2
),
devuelto as (
    select id_venta, id_producto, sum(cantidad) as unidades_devueltas
    from "sgfood"."intermediate"."int_devoluciones"
    group by 1, 2
)
select
    d.id_venta,
    d.id_producto,
    v.unidades_vendidas,
    d.unidades_devueltas
from devuelto as d
inner join vendido as v
    on v.id_venta = d.id_venta
    and v.id_producto = d.id_producto
where d.unidades_devueltas > v.unidades_vendidas