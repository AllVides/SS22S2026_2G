-- SCD tipo 1: recarga total; surrogate entero determinista por id_producto.
select
    row_number() over (order by p.id_producto)::integer as producto_sk,
    p.id_producto,
    p.sku,
    p.nombre,
    c.nombre as categoria,
    m.nombre as marca,
    p.unidad_medida,
    p.costo_base,
    p.precio_lista,
    p.activo
from {{ ref('stg_producto') }} as p
left join {{ ref('stg_categoria') }} as c on c.id_categoria = p.id_categoria
left join {{ ref('stg_marca') }} as m on m.id_marca = p.id_marca
