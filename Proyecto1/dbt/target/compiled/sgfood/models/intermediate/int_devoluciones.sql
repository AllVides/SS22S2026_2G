-- Devoluciones con sucursal heredada de su venta (el CSV no la trae).
select
    d.id_devolucion,
    d.fecha,
    d.id_venta,
    v.id_sucursal,
    d.id_producto,
    d.cantidad,
    d.motivo
from "sgfood"."staging"."stg_devoluciones" as d
inner join "sgfood"."staging"."stg_venta" as v on v.id_venta = d.id_venta