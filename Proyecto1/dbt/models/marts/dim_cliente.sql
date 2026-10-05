select
    row_number() over (order by id_cliente)::integer as cliente_sk,
    id_cliente,
    nit,
    nombre,
    tipo_cliente,
    municipio,
    departamento,
    fecha_alta
from {{ ref('stg_cliente') }}
