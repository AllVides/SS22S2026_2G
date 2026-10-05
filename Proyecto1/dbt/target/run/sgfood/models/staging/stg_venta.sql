
  create view "sgfood"."staging"."stg_venta__dbt_tmp"
    
    
  as (
    select
    cast(id_venta as bigint) as id_venta,
    cast(fecha as date) as fecha,
    cast(id_cliente as integer) as id_cliente,
    cast(id_sucursal as integer) as id_sucursal,
    nullif(trim(canal), '') as canal,
    nullif(trim(metodo_pago), '') as metodo_pago,
    nullif(trim(estado), '') as estado,
    _loaded_at
from "sgfood"."raw"."venta"
  );