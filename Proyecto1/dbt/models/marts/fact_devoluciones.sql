select
    i.id_devolucion,
    i.fecha as fecha_fk,
    i.id_venta,
    p.producto_sk,
    i.cantidad,
    i.motivo
from {{ ref('int_devoluciones') }} as i
inner join {{ ref('dim_producto') }} as p on p.id_producto = i.id_producto
