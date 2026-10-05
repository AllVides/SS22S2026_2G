
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id_proveedor
from "sgfood"."staging"."stg_proveedores_precios"
where id_proveedor is null



  
  
      
    ) dbt_internal_test