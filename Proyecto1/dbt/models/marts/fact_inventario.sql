-- Grano: corte x sucursal x producto (foto periódica).
select
    i.fecha_corte,
    s.sucursal_sk,
    p.producto_sk,
    i.stock_disponible,
    i.stock_minimo,
    i.stock_maximo,
    i.lote,
    i.fecha_vencimiento,
    i.flag_stock_bajo,
    i.flag_vencido
from {{ ref('int_inventario_estado') }} as i
inner join {{ ref('dim_sucursal') }} as s on s.id_sucursal = i.id_sucursal
inner join {{ ref('dim_producto') }} as p on p.id_producto = i.id_producto
