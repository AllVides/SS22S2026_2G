
    
    

with child as (
    select fecha_corte as from_field
    from "sgfood"."marts"."fact_inventario"
    where fecha_corte is not null
),

parent as (
    select fecha as to_field
    from "sgfood"."marts"."dim_fecha"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


