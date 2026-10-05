
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cliente_sk
from "sgfood"."marts"."dim_cliente"
where cliente_sk is null



  
  
      
    ) dbt_internal_test