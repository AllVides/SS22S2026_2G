select
    cast(id_categoria as integer) as id_categoria,
    nullif(trim(nombre), '') as nombre,
    _loaded_at
from {{ source('raw', 'categoria') }}
