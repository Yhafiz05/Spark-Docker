FROM apache/spark:3.5.1-scala2.12-java11-ubuntu

USER root

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install jupyter pyspark && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

EXPOSE 8888

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
