-- Espejo limpio de raw.sucursal: recorte, casteo y '' -> NULL.
select
    cast(id_sucursal as integer) as id_sucursal,
    nullif(trim(nombre), '') as nombre,
    nullif(trim(ciudad), '') as ciudad,
    nullif(trim(departamento), '') as departamento,
    _loaded_at
from {{ source('raw', 'sucursal') }}
