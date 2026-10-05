
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_categoria as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_categoria"
where id_categoria is not null
group by id_categoria
having count(*) > 1



  
  
      
    ) dbt_internal_test