
    
    

select
    id_detalle as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_venta_detalle"
where id_detalle is not null
group by id_detalle
having count(*) > 1


