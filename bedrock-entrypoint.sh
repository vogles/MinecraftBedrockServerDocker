#!/bin/bash

if [[ $EULA != "true" ]]; then

    echo
    echo "EULA must be set to true to indicate agreement with the Minecraft End User License"
    echo "See https://minecraft.net/terms"
    echo
    echo "Current value is '${EULA}'"
    echo

    exit 1
fi

set -e

function getVersion()
{
    version=$1

    if [[ -z $version ]]; then
        version=latest
    fi

    case ${version} in
        1.12|previous)
            version=1.12.0.28
            ;;
        *)
            version=$( \
                curl -v --silent https://www.minecraft.net/en-us/download/server/bedrock/ 2>&1 | \
                grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | \
                sed 's#.*/bedrock-server-##' | sed 's/.zip//')
    esac

    echo $version
}

function downloadAndUnzip()
{
    version=$1
    unzipPath=$2

    downloadUrl="https://minecraft.azureedge.net/bin-linux/bedrock-server-${version}.zip"
    downloadPath="${MINECRAFT_PATH}/$(basename "$downloadUrl")"

    echo "Downloading Minecraft Bedrock server version ${VERSION} ..."
    wget $downloadUrl -O $downloadPath --progress=bar
    #curl $downloadUrl -o $downloadPath

    if [[ ! -d $unzipPath ]]; then
        mkdir $unzipPath
    else
        pushd $unzipPath

        #remove only binaries to allow for an upgrade of those
        rm -f bedrock_server *.so
    fi

    if [[ -e $downloadPath ]]; then
        unzip -n -q $downloadPath -d $unzipPath
        rm $downloadPath
    else
        echo "Can't find $downloadPath"
    fi
}

function copyConfigFile()
{
    filename=$1

    # if the file exists in the config folder then copy the config
    if [ -e ./config/$filename ]; then
        cp ./config/$filename ./$filename
    
    # if there is a default config then copy that to both locations
    else
        cp ./$filename ./config/$filename
    fi
}

function backupWorlds()
{
    backupDir=$1

    if [ -d "worlds" ]; then
        echo "Backing up server (to backups folder)"
        tar -pzvcf $backupDir/$(date +%Y.%m.%d.%H.%M.%S).tar.gz worlds
    fi
}

cd $1
MINECRAFT_PATH=$(pwd)
SERVER_DIR="${MINECRAFT_PATH}/server"
BACKUPS_DIR="${SERVER_DIR}/backups"
VERSION=$(getVersion ${VERSION})

echo "Version: ${VERSION}"

if [[! -d $SERVER_DIR ]]; then
    mkdir -p $SERVER_DIR
fi

cd $SERVER_DIR
backupWorlds $BACKUPS_DIR
downloadAndUnzip $VERSION ${SERVER_DIR}


if [[ ! -d ./config ]]; then
    mkdir ./config
fi

copyConfigFile server.properties
copyConfigFile permissions.json
copyConfigFile whitelist.json

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
exec ./bedrock_server