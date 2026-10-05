-- Grano: una fila por línea de venta.
select
    i.id_detalle,
    i.id_venta,
    i.fecha as fecha_fk,
    p.producto_sk,
    c.cliente_sk,
    s.sucursal_sk,
    i.canal,
    i.metodo_pago,
    i.estado,
    i.cantidad,
    i.precio_unitario,
    i.descuento,
    i.subtotal_calculado as subtotal
from "sgfood"."intermediate"."int_ventas_detalle" as i
inner join "sgfood"."marts"."dim_producto" as p on p.id_producto = i.id_producto
inner join "sgfood"."marts"."dim_cliente" as c on c.id_cliente = i.id_cliente
inner join "sgfood"."marts"."dim_sucursal" as s on s.id_sucursal = i.id_sucursal