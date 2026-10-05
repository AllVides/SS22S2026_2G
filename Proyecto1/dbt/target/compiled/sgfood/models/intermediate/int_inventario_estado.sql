-- Foto de inventario con banderas de negocio para reporte directo.
select
    fecha_corte,
    id_sucursal,
    id_producto,
    stock_disponible,
    stock_minimo,
    stock_maximo,
    lote,
    fecha_vencimiento,
    (stock_disponible < stock_minimo) as flag_stock_bajo,
    (fecha_vencimiento < fecha_corte) as flag_vencido,
    (fecha_vencimiento - fecha_corte) as dias_para_vencer
from "sgfood"."staging"."stg_inventario_bodega"