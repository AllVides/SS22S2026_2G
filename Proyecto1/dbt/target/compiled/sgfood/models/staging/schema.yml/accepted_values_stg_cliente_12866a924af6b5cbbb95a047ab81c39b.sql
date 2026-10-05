
    
    

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


