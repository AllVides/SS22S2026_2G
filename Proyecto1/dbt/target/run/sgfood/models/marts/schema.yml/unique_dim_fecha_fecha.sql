
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    fecha as unique_field,
    count(*) as n_records

from "sgfood"."marts"."dim_fecha"
where fecha is not null
group by fecha
having count(*) > 1



  
  
      
    ) dbt_internal_test