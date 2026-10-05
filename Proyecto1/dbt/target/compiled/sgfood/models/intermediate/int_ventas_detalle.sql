-- Grano: una línea de venta enriquecida (joins + reglas de negocio).
-- Incluye TODOS los estados (trazabilidad); el filtrado es decisión de consumo.
-- subtotal_calculado permite auditar subtotal fuente (test singular).
select
    d.id_detalle,
    d.id_venta,
    v.fecha,
    v.id_cliente,
    v.id_sucursal,
    v.canal,
    v.metodo_pago,
    v.estado,
    d.id_producto,
    p.sku,
    p.nombre as producto,
    c.nombre as categoria,
    m.nombre as marca,
    d.cantidad,
    d.precio_unitario,
    d.descuento,
    d.subtotal as subtotal_fuente,
    round(d.cantidad * d.precio_unitario * (1 - d.descuento), 2) as subtotal_calculado
from "sgfood"."staging"."stg_venta_detalle" as d
inner join "sgfood"."staging"."stg_venta" as v on v.id_venta = d.id_venta
inner join "sgfood"."staging"."stg_producto" as p on p.id_producto = d.id_producto
left join "sgfood"."staging"."stg_categoria" as c on c.id_categoria = p.id_categoria
left join "sgfood"."staging"."stg_marca" as m on m.id_marca = p.id_marca