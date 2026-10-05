
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subtotal_calculado
from "sgfood"."intermediate"."int_ventas_detalle"
where subtotal_calculado is null



  
  
      
    ) dbt_internal_test