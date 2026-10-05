
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    id_detalle as unique_field,
    count(*) as n_records

from "sgfood"."marts"."fact_ventas"
where id_detalle is not null
group by id_detalle
having count(*) > 1



  
  
      
    ) dbt_internal_test