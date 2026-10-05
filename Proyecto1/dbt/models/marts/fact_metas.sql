-- Grano: mes x sucursal. periodo 'YYYY-MM' -> DATE (día 1 del mes).
select
    date_trunc('month', to_date(periodo, 'YYYY-MM'))::date as periodo,
    s.sucursal_sk,
    m.meta_ventas,
    m.meta_unidades
from {{ ref('stg_metas_ventas') }} as m
inner join {{ ref('dim_sucursal') }} as s on s.id_sucursal = m.id_sucursal
