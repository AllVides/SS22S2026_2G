
    
    

select
    id_marca as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_marca"
where id_marca is not null
group by id_marca
having count(*) > 1


