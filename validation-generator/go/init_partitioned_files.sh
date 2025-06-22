#!/bin/bash
#
# This is script is vibe coded 🤷
#
# ⚠️ YOU DON'T NEED TO LAUNCH THIS SCRIPT DURING THE NIGHT CLAZZ
# We used it to fill the bucket
# We would like to compare response times for equivalent requests to DuckLake

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------
# Date de début pour la génération des données (format YYYY-MM-DD).
START_DATE="2024-06-01"

# Nombre total de jours à générer (ex: 366 pour une année complète avec année bissextile).
NUM_DAYS=366

# Chemin vers le script Go.
GO_SCRIPT="./main.go"

# Répertoire de base pour les données (le script y créera validations.json).
DATA_DIR="../../data"

# Répertoire de base pour les partitions Parquet.
HIVE_BASE_DIR="${DATA_DIR}/validations"

# Fichier JSON temporaire généré par le script Go.
JSON_OUTPUT_FILE="${DATA_DIR}/validations.json"

# Définition des volumes de validations.
# ⚠️ IT CAN BE A LOT
MIN_VALIDATIONS=1000
MAX_VALIDATIONS=100000000
WEEKDAY_MIN=5000000
WEEKDAY_MAX=25000000
WEEKEND_MIN=200000
WEEKEND_MAX=1500000

#-------------------------------------------------------------------------------
# SCRIPT - Ne pas modifier en dessous de cette ligne
#-------------------------------------------------------------------------------

# Quitte le script si une commande échoue.
set -e

echo "Démarrage de la génération des données Parquet..."
echo "Période : ${NUM_DAYS} jours à partir du ${START_DATE}"
echo "----------------------------------------------------"

# S'assurer que le répertoire de données existe.
mkdir -p "$DATA_DIR"

# Détecter le système d'exploitation une seule fois.
OS_TYPE=$(uname)

for i in $(seq 0 $(($NUM_DAYS - 1))); do
    # Calcul de date compatible pour Linux (GNU) et macOS (BSD).
    current_date=""
    year=""
    month=""
    day=""
    day_of_week=""
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # Syntaxe pour macOS / BSD
        read year month day day_of_week <<< $(date -v+${i}d -j -f "%Y-%m-%d" "$START_DATE" "+%Y %m %d %u")
    else
        # Syntaxe pour Linux / GNU
        read year month day day_of_week <<< $(date -d "$START_DATE + $i days" "+%Y %m %d %u")
    fi
    current_date="${year}-${month}-${day}"

    # --- Logique pour déterminer le nombre de validations ---
    num_validations=0
    
    # Génère un nombre aléatoire entre 0 et 999.
    random_event=$((RANDOM % 1000))

    if [[ $random_event -eq 1 ]]; then
        num_validations=$MAX_VALIDATIONS
        echo "INFO: Événement RARE - Pic d'activité maximal !"
    elif [[ $random_event -eq 2 ]]; then
        num_validations=$MIN_VALIDATIONS
        echo "INFO: Événement RARE - Jour férié/très faible activité !"
    elif [[ $day_of_week -ge 6 ]]; then
        # Weekend
        range=$(($WEEKEND_MAX - $WEEKEND_MIN))
        num_validations=$(($WEEKEND_MIN + (RANDOM % $range)))
    else
        # Jour de semaine
        range=$(($WEEKDAY_MAX - $WEEKDAY_MIN))
        num_validations=$(($WEEKDAY_MIN + (RANDOM % $range)))
    fi

    echo "Traitement du ${current_date} (Jour de la semaine: ${day_of_week})"
    echo " -> Nombre de validations à générer : ${num_validations}"

    # --- Création de la structure de répertoires Hive ---
    partition_dir="${HIVE_BASE_DIR}/year=${year}/month=${month}/day=${day}"
    mkdir -p "$partition_dir"
    echo " -> Création du répertoire : ${partition_dir}"

    # --- Étape 1: Génération du fichier JSON ---
    echo " -> Génération de ${JSON_OUTPUT_FILE}..."
    go run "$GO_SCRIPT" "$num_validations" "$current_date"
    if [ $? -ne 0 ]; then
        echo "ERREUR: La génération du fichier JSON a échoué pour le ${current_date}."
        exit 1
    fi

    # --- Étape 2: Conversion de JSON vers Parquet ---
    parquet_file="${partition_dir}/validations.parquet"
    echo " -> Conversion en Parquet vers ${parquet_file}..."
    
    duckdb -c "COPY (FROM '${JSON_OUTPUT_FILE}') TO '${parquet_file}' (FORMAT 'PARQUET');"
    if [ $? -ne 0 ]; then
        echo "ERREUR: La conversion en Parquet a échoué pour le ${current_date}."
        exit 1
    fi
    
    # --- Étape 3: Nettoyage ---
    rm "$JSON_OUTPUT_FILE"
    echo " -> Fichier JSON temporaire supprimé."
    echo "----------------------------------------------------"

done

echo "Opération terminée avec succès."
echo "Toutes les données ont été générées et stockées dans ${HIVE_BASE_DIR}"
