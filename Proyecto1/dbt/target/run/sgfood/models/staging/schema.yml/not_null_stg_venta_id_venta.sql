
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_venta
from "sgfood"."staging"."stg_venta"
where id_venta is null



  
  
      
    ) dbt_internal_test