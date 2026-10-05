
    
    

with child as (
    select sucursal_sk as from_field
    from "sgfood"."marts"."fact_inventario"
    where sucursal_sk is not null
),

parent as (
    select sucursal_sk as to_field
    from "sgfood"."marts"."dim_sucursal"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


