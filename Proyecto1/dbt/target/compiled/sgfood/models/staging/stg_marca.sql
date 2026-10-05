select
    cast(id_marca as integer) as id_marca,
    nullif(trim(nombre), '') as nombre,
    _loaded_at
from "sgfood"."raw"."marca"