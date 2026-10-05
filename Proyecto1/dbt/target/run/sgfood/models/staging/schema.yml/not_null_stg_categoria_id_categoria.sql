
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_categoria
from "sgfood"."staging"."stg_categoria"
where id_categoria is null



  
  
      
    ) dbt_internal_test