
  
    

  create  table "sgfood"."marts"."dim_sucursal__dbt_tmp"
  
  
    as
  
  (
    select
    row_number() over (order by id_sucursal)::integer as sucursal_sk,
    id_sucursal,
    nombre,
    ciudad,
    departamento
from "sgfood"."staging"."stg_sucursal"
  );
  