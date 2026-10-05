
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select producto_sk
from "sgfood"."marts"."fact_devoluciones"
where producto_sk is null



  
  
      
    ) dbt_internal_test