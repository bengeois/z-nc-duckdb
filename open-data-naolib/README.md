# Open Data Naolib

## Base locale

Initialiser la base de données

```shell
sh init_db.sh
```

L'attacher

```sql
ATTACH 'chemin/vers/open-data-naolib.duckdb' as naolib;
SHOW ALL TABLES;
```

## Base distante

L'attacher

```sql
ATTACH 'https://url/vers/open-data-naolib.duckdb' as naolib;
SHOW ALL TABLES;
```
