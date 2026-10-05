
    
    

with child as (
    select cliente_sk as from_field
    from "sgfood"."marts"."fact_ventas"
    where cliente_sk is not null
),

parent as (
    select cliente_sk as to_field
    from "sgfood"."marts"."dim_cliente"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


