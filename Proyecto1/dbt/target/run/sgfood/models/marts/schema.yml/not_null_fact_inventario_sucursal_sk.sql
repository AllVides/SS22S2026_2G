
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sucursal_sk
from "sgfood"."marts"."fact_inventario"
where sucursal_sk is null



  
  
      
    ) dbt_internal_test