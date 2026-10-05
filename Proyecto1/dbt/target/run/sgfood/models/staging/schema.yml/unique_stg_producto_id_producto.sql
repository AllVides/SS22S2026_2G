
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_producto as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_producto"
where id_producto is not null
group by id_producto
having count(*) > 1



  
  
      
    ) dbt_internal_test