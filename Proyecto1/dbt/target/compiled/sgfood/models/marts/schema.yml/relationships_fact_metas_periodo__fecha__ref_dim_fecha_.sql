
    
    

with child as (
    select periodo as from_field
    from "sgfood"."marts"."fact_metas"
    where periodo is not null
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


