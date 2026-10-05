
  create view "sgfood"."staging"."stg_inventario_bodega__dbt_tmp"
    
    
  as (
    select
    cast(fecha_corte as date) as fecha_corte,
    cast(id_sucursal as integer) as id_sucursal,
    cast(id_producto as integer) as id_producto,
    cast(stock_disponible as integer) as stock_disponible,
    cast(stock_minimo as integer) as stock_minimo,
    cast(stock_maximo as integer) as stock_maximo,
    nullif(trim(lote), '') as lote,
    cast(fecha_vencimiento as date) as fecha_vencimiento,
    _loaded_at
from "sgfood"."raw"."inventario_bodega"
  );