select
    row_number() over (order by id_sucursal)::integer as sucursal_sk,
    id_sucursal,
    nombre,
    ciudad,
    departamento
from {{ ref('stg_sucursal') }}
