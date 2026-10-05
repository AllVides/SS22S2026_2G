
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        metodo_pago as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_venta"
    group by metodo_pago

)

select *
from all_values
where value_field not in (
    'Crédito','Efectivo','Tarjeta','Transferencia'
)



  
  
      
    ) dbt_internal_test