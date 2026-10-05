
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_promocion
from "sgfood"."staging"."stg_promociones"
where id_promocion is null



  
  
      
    ) dbt_internal_test