FROM ubuntu:18.04
ARG BDS_Eula
ARG BDS_Version

ENV EULA=$BDS_Eula
ENV VERSION=$BDS_Version

RUN apt-get update && apt-get install -y \
    curl \
    libcurl4 \
    libssl1.0.0 \
    wget \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /minecraft && \
    mkdir -p /minecraft/server

# Copy the startup script
COPY *.sh /minecraft/

WORKDIR /minecraft/

EXPOSE 19132
EXPOSE 19133

ENTRYPOINT ["./bedrock-entrypoint.sh", "/minecraft/"]

# create volumes for settings that need to be persisted.
VOLUME /minecraft/server/worlds /minecraft/server/config /minecraft/server/backups