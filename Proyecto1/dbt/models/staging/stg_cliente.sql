select
    cast(id_cliente as integer) as id_cliente,
    nullif(trim(nit), '') as nit,
    nullif(trim(nombre), '') as nombre,
    nullif(trim(tipo_cliente), '') as tipo_cliente,
    nullif(trim(municipio), '') as municipio,
    nullif(trim(departamento), '') as departamento,
    cast(fecha_alta as date) as fecha_alta,
    _loaded_at
from {{ source('raw', 'cliente') }}
