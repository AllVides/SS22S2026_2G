-- periodo llega como TEXT 'YYYY-MM'; se normaliza a DATE en marts.
select
    nullif(trim(periodo), '') as periodo,
    cast(id_sucursal as integer) as id_sucursal,
    cast(meta_ventas as numeric(14, 2)) as meta_ventas,
    cast(meta_unidades as integer) as meta_unidades,
    _loaded_at
from "sgfood"."raw"."metas_ventas"