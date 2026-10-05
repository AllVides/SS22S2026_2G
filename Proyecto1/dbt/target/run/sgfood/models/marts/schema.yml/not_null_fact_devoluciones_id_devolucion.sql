
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_devolucion
from "sgfood"."marts"."fact_devoluciones"
where id_devolucion is null



  
  
      
    ) dbt_internal_test