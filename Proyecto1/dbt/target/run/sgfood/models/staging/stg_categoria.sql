
  create view "sgfood"."staging"."stg_categoria__dbt_tmp"
    
    
  as (
    select
    cast(id_categoria as integer) as id_categoria,
    nullif(trim(nombre), '') as nombre,
    _loaded_at
from "sgfood"."raw"."categoria"
  );