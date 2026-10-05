
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subtotal
from "sgfood"."marts"."fact_ventas"
where subtotal is null



  
  
      
    ) dbt_internal_test