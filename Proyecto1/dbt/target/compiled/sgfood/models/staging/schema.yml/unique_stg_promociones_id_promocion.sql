
    
    

select
    id_promocion as unique_field,
    count(*) as n_records

from "sgfood"."staging"."stg_promociones"
where id_promocion is not null
group by id_promocion
having count(*) > 1


