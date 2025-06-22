# Simulate pg and s3

For local components use:
```shell
docker compose up
```

## Local database (postgres)

```sql
CREATE OR REPLACE SECRET secret_pg (
    TYPE POSTGRES,
    HOST 'localhost',
    PORT 5432,
    DATABASE 'pgadmin',
    USER 'pgadmin',
    PASSWORD 'pgadmin'
);
-- DETACH pg;
ATTACH '' AS pg (TYPE POSTGRES, SECRET secret_pg);
```

You can read and write tables in the database:
```sql
create table pg.life as select 42 as id;
from pg.life;
```

## Local Cloud Storage (minio)

```sql
CREATE OR REPLACE SECRET secret_minio (
    TYPE s3,
    KEY_ID 'minioadmin',
    SECRET 'minioadmin',
    REGION 'us-east-1',
    URL_STYLE 'path',
    USE_SSL false,
    ENDPOINT '127.0.0.1:9000'
);
```

Connect to [localhost:9001](http://localhost:9001/browser) and add a file to the bucket `bucket` or use DuckDB to write a file to it:
```sql
copy (select 42 as id) to 's3://bucket/life.parquet';
from 's3://bucket/life.parquet';
```

## Local DuckLake (minio + postgres)

```sql
CREATE OR REPLACE SECRET secret_minio (
    TYPE s3,
    KEY_ID 'minioadmin',
    SECRET 'minioadmin',
    REGION 'us-east-1',
    URL_STYLE 'path',
    USE_SSL false,
    ENDPOINT '127.0.0.1:9000'
);
CREATE OR REPLACE SECRET secret_ducklake_pg (
    TYPE POSTGRES,
    HOST 'localhost',
    PORT 5432,
    DATABASE 'ducklake_catalog',
    USER 'pgadmin',
    PASSWORD 'pgadmin'
);
CREATE OR REPLACE SECRET secret_ducklake (
    TYPE DUCKLAKE,
    METADATA_PATH '',
    DATA_PATH 's3://ducklake/',
    METADATA_PARAMETERS MAP {'TYPE': 'postgres', 'SECRET': 'secret_ducklake_pg'}
);
-- DETACH ducklake;
ATTACH 'ducklake:secret_ducklake' AS ducklake;
```

But you can choose another [Catalog Database](https://ducklake.select/docs/stable/duckdb/usage/choosing_a_catalog_database) (DuckDB, SQLite, ...) and another [Storage](https://ducklake.select/docs/stable/duckdb/usage/choosing_storage) (local files, ...).

## Remote Cloud Storage

```sql
CREATE OR REPLACE SECRET secret_gcs (
    TYPE gcs,
    KEY_ID '🤫 is given to you at the Night Clazz 🤫',
    SECRET '🤫 is given to you at the Night Clazz 🤫'
);
```

Keep in mind that this works with other [Cloud Storage](https://duckdb.org/docs/stable/guides/network_cloud_storage/overview).

Then you can read the files stored on Cloud Storage:
```shell
duckdb -c "select count(*) 'gs://bucket/path/to/file.parquet'";
duckdb -c "select count(*) 's3://bucket/path/to/file.parquet'";
...
```
