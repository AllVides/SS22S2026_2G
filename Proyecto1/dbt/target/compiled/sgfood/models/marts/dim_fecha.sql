-- Calendario continuo entre la mínima y máxima fecha de los hechos.
-- nombre_mes en español vía arreglo (determinista, sin depender del locale).
with limites as (
    select min(fecha) as ini, max(fecha) as fin
    from (
        select fecha from "sgfood"."staging"."stg_venta"
        union all
        select fecha_corte from "sgfood"."staging"."stg_inventario_bodega"
        union all
        select fecha from "sgfood"."staging"."stg_devoluciones"
    ) t
),
dias as (
    select (generate_series(ini, fin, interval '1 day'))::date as fecha
    from limites
)
select
    fecha,
    extract(year from fecha)::integer as anio,
    extract(month from fecha)::integer as mes,
    (array['enero','febrero','marzo','abril','mayo','junio','julio',
           'agosto','septiembre','octubre','noviembre','diciembre'])
        [extract(month from fecha)] as nombre_mes,
    extract(quarter from fecha)::integer as trimestre,
    extract(isodow from fecha)::integer as dia_semana,
    (extract(isodow from fecha) in (6, 7)) as es_fin_semana
from dias