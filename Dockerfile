FROM python:3.12.9-bullseye as spark-base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      vim \
      unzip \
      rsync \
      openjdk-11-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Telechargement de Spark

# Variable d'environnement
ENV SPARK_VERSION=3.5.7

# Si aucune valeur n'est fournie, on utilise les valeurs par défaut
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}

ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_HOST=spark-master
# Configuration de l'URL du master
ENV SPARK_MASTER="spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH
ENV PYSPARK_PYTHON=python3

# Ajout de iceberg spark runtime jar 
ENV IJAVA_CLASSPATH=/opt/spark/jars/*

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}
WORKDIR ${SPARK_HOME}

# Téléchargement de  spark
# Voici le lien de la ressource resources: https://dlcdn.apache.org/spark/spark-4.0.1/spark-4.0.1-bin-hadoop3.tgz
# fichier: spark-3.5.5-bin-hadoop3.tgz 
RUN mkdir -p ${SPARK_HOME} \
    && curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory ${SPARK_HOME} --strip-components 1 \
    && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Ajout des binaires de spark au path pour permettre l'éxécution
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Ajout de la config par defaut à tous les noeuds
COPY conf/spark-defaults.conf "$SPARK_HOME/conf/"


FROM spark-base AS pyspark

# Install python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt
RUN pip3 install notebook

FROM pyspark AS pyspark-runner
 
## Delta et Hudi sont des systèmes permettant de gérer des données parquet 
# dans un data lake (S3, HDFS, MinIO, Azure Blob…) comme si c’était une base de données

# iceberg
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.4_2.12/1.4.3/iceberg-spark-runtime-3.4_2.12-1.4.3.jar -Lo /opt/spark/jars/iceberg-spark-runtime-3.4_2.12-1.4.3.jar

# delta 
RUN curl https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar -Lo /opt/spark/jars/delta-core_2.12-2.4.0.jar
RUN curl https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.2.0/delta-spark_2.12-3.2.0.jar -Lo /opt/spark/jars/delta-spark_2.12-3.2.0.jar
RUN curl https://repo1.maven.org/maven2/io/delta/delta-storage/3.2.0/delta-storage-3.2.0.jar -Lo /opt/spark/jars/delta-storage-3.2.0.jar

# hudi
RUN curl https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark3-bundle_2.12/0.15.0/hudi-spark3-bundle_2.12-0.15.0.jar -Lo /opt/spark/jars/hudi-spark3-bundle_2.12-0.15.0.jar

COPY entrypoint.sh .
RUN chmod u+x /opt/spark/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD [ "bash" ]
