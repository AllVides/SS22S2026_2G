
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_marca as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_marca"
where id_marca is not null
group by id_marca
having count(*) > 1



  
  
      
    ) dbt_internal_test