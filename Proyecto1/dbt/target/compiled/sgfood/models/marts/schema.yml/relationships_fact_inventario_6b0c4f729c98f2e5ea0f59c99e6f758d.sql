
    
    

with child as (
    select producto_sk as from_field
    from "sgfood"."marts"."fact_inventario"
    where producto_sk is not null
),

parent as (
    select producto_sk as to_field
    from "sgfood"."marts"."dim_producto"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


