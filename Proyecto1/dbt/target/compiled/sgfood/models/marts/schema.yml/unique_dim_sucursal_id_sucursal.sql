
    
    

select
    id_sucursal as unique_field,
    count(*) as n_records

from "sgfood"."marts"."dim_sucursal"
where id_sucursal is not null
group by id_sucursal
having count(*) > 1


