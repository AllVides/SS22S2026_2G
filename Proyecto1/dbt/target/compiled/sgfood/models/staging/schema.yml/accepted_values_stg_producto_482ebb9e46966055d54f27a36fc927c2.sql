
    
    

with all_values as (

    select
        unidad_medida as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_producto"
    group by unidad_medida

)

select *
from all_values
where value_field not in (
    'botella','caja','paquete','unidad'
)


