
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_producto
from "sgfood"."marts"."dim_producto"
where id_producto is null



  
  
      
    ) dbt_internal_test