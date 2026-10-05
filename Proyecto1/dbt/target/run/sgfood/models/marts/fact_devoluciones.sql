
  
    

  create  table "sgfood"."marts"."fact_devoluciones__dbt_tmp"
  
  
    as
  
  (
    select
    i.id_devolucion,
    i.fecha as fecha_fk,
    i.id_venta,
    p.producto_sk,
    i.cantidad,
    i.motivo
from "sgfood"."intermediate"."int_devoluciones" as i
inner join "sgfood"."marts"."dim_producto" as p on p.id_producto = i.id_producto
  );
  