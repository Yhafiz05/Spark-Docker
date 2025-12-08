#!/bin/bash

# Charge les variables d'environnement Spark si nécessaire
. "/opt/spark/sbin/spark-config.sh"
. "/opt/spark/bin/load-spark-env.sh"

MODE=$1
echo "Spark execution mode: $MODE"

if [ "$MODE" == "master" ];
then
    echo "Starting Master..."
    # On lance la classe Master directement pour garder le processus au premier plan
    exec /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master \
        --ip $SPARK_MASTER_HOST \
        --port 7077 \
        --webui-port 8080

elif [[ "$MODE" =~ "worker" ]];
then
    echo "Starting Worker..."
    # On lance la classe Worker directement
    exec /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker \
        spark://spark-master:7077 \
        --webui-port 8081

elif [ "$MODE" == "history" ]
then
    echo "Starting History Server..."
    exec /opt/spark/bin/spark-class org.apache.spark.deploy.history.HistoryServer

else
    echo "Unknown SPARK_EXECUTION_MODE: $MODE"
    exit 1
fi