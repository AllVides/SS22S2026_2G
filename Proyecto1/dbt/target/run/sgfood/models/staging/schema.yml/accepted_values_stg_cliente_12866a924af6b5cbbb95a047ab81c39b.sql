
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        tipo_cliente as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_cliente"
    group by tipo_cliente

)

select *
from all_values
where value_field not in (
    'Mayorista','Minorista','Restaurante','Tienda de barrio'
)



  
  
      
    ) dbt_internal_test