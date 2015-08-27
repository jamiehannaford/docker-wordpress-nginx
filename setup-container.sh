#!/bin/bash

os_type=$(uname)
path="$os_type/amd64/rack"

if [[ "$os_type" == "Windows" ]]; then
  path="$path.exe"
fi

if [ -z "$RS_CONTAINER" ]; then
  echo "RS_CONTAINER variable not set"
  exit 1
fi

if [ -z "$RS_REGION" ]; then
  echo "RS_REGION variable not set"
  exit 1
fi

curl -sO https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.0-beta.1/$path
chmod +x ./rack

./rack files container create --name $RS_CONTAINER --region $RS_REGION

curl -sO https://wordpress.org/latest.zip
unzip latest.zip

cd wordpress
../rack files object upload-dir --container $RS_CONTAINER --dir wp-content/themes/ --recurse --region $RS_REGION
../rack files object upload-dir --container $RS_CONTAINER --dir wp-includes/ --recurse --region $RS_REGION

cd ..
rm -rf wordpress
rm latest.zip
