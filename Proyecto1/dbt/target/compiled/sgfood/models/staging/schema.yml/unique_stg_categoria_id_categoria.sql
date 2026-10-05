
    
    

select
    id_categoria as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_categoria"
where id_categoria is not null
group by id_categoria
having count(*) > 1


