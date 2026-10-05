
  
    

  create  table "sgfood"."marts"."fact_metas__dbt_tmp"
  
  
    as
  
  (
    -- Grano: mes x sucursal. periodo 'YYYY-MM' -> DATE (día 1 del mes).
select
    date_trunc('month', to_date(periodo, 'YYYY-MM'))::date as periodo,
    s.sucursal_sk,
    m.meta_ventas,
    m.meta_unidades
from "sgfood"."staging"."stg_metas_ventas" as m
inner join "sgfood"."marts"."dim_sucursal" as s on s.id_sucursal = m.id_sucursal
  );
  