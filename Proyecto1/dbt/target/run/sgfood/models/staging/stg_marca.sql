
  create view "sgfood"."staging"."stg_marca__dbt_tmp"
    
    
  as (
    select
    cast(id_marca as integer) as id_marca,
    nullif(trim(nombre), '') as nombre,
    _loaded_at
from "sgfood"."raw"."marca"
  );