
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_marca
from "sgfood"."staging"."stg_marca"
where id_marca is null



  
  
      
    ) dbt_internal_test