
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_detalle
from "sgfood"."marts"."fact_ventas"
where id_detalle is null



  
  
      
    ) dbt_internal_test