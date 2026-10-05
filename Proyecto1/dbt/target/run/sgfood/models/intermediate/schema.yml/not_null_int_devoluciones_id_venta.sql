
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_venta
from "sgfood"."intermediate"."int_devoluciones"
where id_venta is null



  
  
      
    ) dbt_internal_test