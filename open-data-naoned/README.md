# Open Data Naoned

## Fichier local

Télécharger le fichier

```shell
sh init_file.sh
```

Le lire

```sql
FROM 'chemin/vers/open-data-naoned-quartiers.parquet' as quartiers; 
```

## Fichier distant

```shell
duckdb -c "FROM read_parquet('https://data.nantesmetropole.fr/api/explore/v2.1/catalog/datasets/244400404_quartiers-communes-nantes-metropole/exports/parquet');"
```

```sql
FROM read_parquet('https://data.nantesmetropole.fr/api/explore/v2.1/catalog/datasets/244400404_quartiers-communes-nantes-metropole/exports/parquet');
```
