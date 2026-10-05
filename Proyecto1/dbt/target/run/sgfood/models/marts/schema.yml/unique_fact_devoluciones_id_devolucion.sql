
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_devolucion as unique_field,
    count(*) as n_records

from "sgfood"."marts"."fact_devoluciones"
where id_devolucion is not null
group by id_devolucion
having count(*) > 1



  
  
      
    ) dbt_internal_test