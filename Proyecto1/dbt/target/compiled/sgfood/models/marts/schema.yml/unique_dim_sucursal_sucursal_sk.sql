
    
    

select
    sucursal_sk as unique_field,
    count(*) as n_records

from "sgfood"."marts"."dim_sucursal"
where sucursal_sk is not null
group by sucursal_sk
having count(*) > 1


