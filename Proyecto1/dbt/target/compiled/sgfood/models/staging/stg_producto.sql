select
    cast(id_producto as integer) as id_producto,
    nullif(trim(sku), '') as sku,
    nullif(trim(nombre), '') as nombre,
    cast(id_categoria as integer) as id_categoria,
    cast(id_marca as integer) as id_marca,
    nullif(trim(unidad_medida), '') as unidad_medida,
    cast(costo_base as numeric(12, 2)) as costo_base,
    cast(precio_lista as numeric(12, 2)) as precio_lista,
    cast(activo as boolean) as activo,
    _loaded_at
from "sgfood"."raw"."producto"