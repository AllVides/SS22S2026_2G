
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select fecha_fk
from "sgfood"."marts"."fact_ventas"
where fecha_fk is null



  
  
      
    ) dbt_internal_test