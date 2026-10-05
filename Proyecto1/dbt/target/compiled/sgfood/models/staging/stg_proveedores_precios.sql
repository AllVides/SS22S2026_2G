select
    cast(id_proveedor as integer) as id_proveedor,
    nullif(trim(proveedor), '') as proveedor,
    cast(id_producto as integer) as id_producto,
    cast(costo_proveedor as numeric(12, 2)) as costo_proveedor,
    cast(plazo_dias as integer) as plazo_dias,
    cast(fecha_vigencia as date) as fecha_vigencia,
    _loaded_at
from "sgfood"."raw"."proveedores_precios"