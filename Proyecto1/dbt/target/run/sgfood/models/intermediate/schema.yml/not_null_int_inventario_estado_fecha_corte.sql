
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select fecha_corte
from "sgfood"."intermediate"."int_inventario_estado"
where fecha_corte is null



  
  
      
    ) dbt_internal_test