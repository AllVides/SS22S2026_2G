
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        motivo as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_devoluciones"
    group by motivo

)

select *
from all_values
where value_field not in (
    'Cliente desistió','Empaque defectuoso','Error de despacho','Producto dañado','Vencimiento cercano'
)



  
  
      
    ) dbt_internal_test