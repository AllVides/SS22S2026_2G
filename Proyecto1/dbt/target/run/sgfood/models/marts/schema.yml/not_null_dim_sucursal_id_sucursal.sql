
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_sucursal
from "sgfood"."marts"."dim_sucursal"
where id_sucursal is null



  
  
      
    ) dbt_internal_test