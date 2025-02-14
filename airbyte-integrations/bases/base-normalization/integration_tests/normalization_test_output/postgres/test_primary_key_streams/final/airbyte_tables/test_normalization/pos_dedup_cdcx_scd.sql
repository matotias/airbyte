

  create  table "postgres".test_normalization."pos_dedup_cdcx_scd__dbt_tmp"
  as (
    
with __dbt__CTE__pos_dedup_cdcx_ab1 as (

-- SQL model to parse JSON blob stored in a single column and extract into separated field columns as described by the JSON Schema
select
    jsonb_extract_path_text(_airbyte_data, 'id') as "id",
    jsonb_extract_path_text(_airbyte_data, 'name') as "name",
    jsonb_extract_path_text(_airbyte_data, '_ab_cdc_lsn') as _ab_cdc_lsn,
    jsonb_extract_path_text(_airbyte_data, '_ab_cdc_updated_at') as _ab_cdc_updated_at,
    jsonb_extract_path_text(_airbyte_data, '_ab_cdc_deleted_at') as _ab_cdc_deleted_at,
    jsonb_extract_path_text(_airbyte_data, '_ab_cdc_log_pos') as _ab_cdc_log_pos,
    _airbyte_emitted_at
from "postgres".test_normalization._airbyte_raw_pos_dedup_cdcx as table_alias
-- pos_dedup_cdcx
),  __dbt__CTE__pos_dedup_cdcx_ab2 as (

-- SQL model to cast each column to its adequate SQL type converted from the JSON schema type
select
    cast("id" as 
    bigint
) as "id",
    cast("name" as 
    varchar
) as "name",
    cast(_ab_cdc_lsn as 
    float
) as _ab_cdc_lsn,
    cast(_ab_cdc_updated_at as 
    float
) as _ab_cdc_updated_at,
    cast(_ab_cdc_deleted_at as 
    float
) as _ab_cdc_deleted_at,
    cast(_ab_cdc_log_pos as 
    float
) as _ab_cdc_log_pos,
    _airbyte_emitted_at
from __dbt__CTE__pos_dedup_cdcx_ab1
-- pos_dedup_cdcx
),  __dbt__CTE__pos_dedup_cdcx_ab3 as (

-- SQL model to build a hash column based on the values of this record
select
    md5(cast(
    
    coalesce(cast("id" as 
    varchar
), '') || '-' || coalesce(cast("name" as 
    varchar
), '') || '-' || coalesce(cast(_ab_cdc_lsn as 
    varchar
), '') || '-' || coalesce(cast(_ab_cdc_updated_at as 
    varchar
), '') || '-' || coalesce(cast(_ab_cdc_deleted_at as 
    varchar
), '') || '-' || coalesce(cast(_ab_cdc_log_pos as 
    varchar
), '')

 as 
    varchar
)) as _airbyte_pos_dedup_cdcx_hashid,
    tmp.*
from __dbt__CTE__pos_dedup_cdcx_ab2 tmp
-- pos_dedup_cdcx
),  __dbt__CTE__pos_dedup_cdcx_ab4 as (

-- SQL model to prepare for deduplicating records based on the hash record column
select
  row_number() over (
    partition by _airbyte_pos_dedup_cdcx_hashid
    order by _airbyte_emitted_at asc
  ) as _airbyte_row_num,
  tmp.*
from __dbt__CTE__pos_dedup_cdcx_ab3 tmp
-- pos_dedup_cdcx from "postgres".test_normalization._airbyte_raw_pos_dedup_cdcx
)-- SQL model to build a Type 2 Slowly Changing Dimension (SCD) table for each record identified by their primary key
select
    "id",
    "name",
    _ab_cdc_lsn,
    _ab_cdc_updated_at,
    _ab_cdc_deleted_at,
    _ab_cdc_log_pos,
  _airbyte_emitted_at as _airbyte_start_at,
  lag(_airbyte_emitted_at) over (
    partition by "id"
    order by _airbyte_emitted_at is null asc, _airbyte_emitted_at desc, _airbyte_emitted_at desc
  ) as _airbyte_end_at,
  case when lag(_airbyte_emitted_at) over (
    partition by "id"
    order by _airbyte_emitted_at is null asc, _airbyte_emitted_at desc, _airbyte_emitted_at desc, _ab_cdc_updated_at desc, _ab_cdc_log_pos desc
  ) is null and _ab_cdc_deleted_at is null  then 1 else 0 end as _airbyte_active_row,
  _airbyte_emitted_at,
  _airbyte_pos_dedup_cdcx_hashid
from __dbt__CTE__pos_dedup_cdcx_ab4
-- pos_dedup_cdcx from "postgres".test_normalization._airbyte_raw_pos_dedup_cdcx
where _airbyte_row_num = 1
  );