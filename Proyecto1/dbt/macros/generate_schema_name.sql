{# Esquema destino = el de la capa, sin prefijos ni sufijos.
   staging -> staging, intermediate -> intermediate, marts -> marts.
   Sin +schema (tests efímeros, seeds sin config) cae al target.schema. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name else target.schema }}
{%- endmacro %}
