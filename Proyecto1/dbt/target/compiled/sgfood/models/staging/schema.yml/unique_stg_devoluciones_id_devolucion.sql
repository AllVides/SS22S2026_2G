
    
    

select
    id_devolucion as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_devoluciones"
where id_devolucion is not null
group by id_devolucion
having count(*) > 1


