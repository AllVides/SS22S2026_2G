
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select periodo
from "sgfood"."marts"."fact_metas"
where periodo is null



  
  
      
    ) dbt_internal_test