
    
    

select
    id_venta as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_venta"
where id_venta is not null
group by id_venta
having count(*) > 1


