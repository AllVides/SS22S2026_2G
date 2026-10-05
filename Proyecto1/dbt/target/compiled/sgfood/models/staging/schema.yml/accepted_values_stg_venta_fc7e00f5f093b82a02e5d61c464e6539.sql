
    
    

with all_values as (

    select
        canal as value_field,
        count(*) as n_records

    from "sgfood"."staging"."stg_venta"
    group by canal

)

select *
from all_values
where value_field not in (
    'Mayorista','Televenta','Tienda','Web'
)


