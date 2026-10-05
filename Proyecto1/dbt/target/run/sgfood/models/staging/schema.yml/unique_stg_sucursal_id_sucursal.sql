
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_sucursal as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_sucursal"
where id_sucursal is not null
group by id_sucursal
having count(*) > 1



  
  
      
    ) dbt_internal_test