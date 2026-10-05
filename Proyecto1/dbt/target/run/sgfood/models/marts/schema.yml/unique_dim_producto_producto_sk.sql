
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    producto_sk as unique_field,
    count(*) as n_records

from "sgfood"."marts"."dim_producto"
where producto_sk is not null
group by producto_sk
having count(*) > 1



  
  
      
    ) dbt_internal_test