select
    cast(id_devolucion as bigint) as id_devolucion,
    cast(fecha as date) as fecha,
    cast(id_venta as bigint) as id_venta,
    cast(id_producto as integer) as id_producto,
    cast(cantidad as integer) as cantidad,
    nullif(trim(motivo), '') as motivo,
    _loaded_at
from "sgfood"."raw"."devoluciones"