
    
    

with all_values as (

    select
        estado as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_venta"
    group by estado

)

select *
from all_values
where value_field not in (
    'ANULADA','COMPLETADA','PENDIENTE'
)


