
    
    

select
    cliente_sk as unique_field,
    count(*) as n_records

from "sgfood"."marts"."dim_cliente"
where cliente_sk is not null
group by cliente_sk
having count(*) > 1


