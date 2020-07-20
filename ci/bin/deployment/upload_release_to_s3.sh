#!/usr/bin/env bash
set -e -x -o pipefail

if [ -z "$S3_BUCKET" ]
then
      echo "\$S3_BUCKET is empty";
      exit 1;
fi

if [ -z "$LOCAL_BUILD_PATH" ]
then
      echo "\$LOCAL_BUILD_PATH is empty";
      exit 1;
fi

if [ -z "$LOCAL_BUILD_PATH" ]
then
      echo "\$LOCAL_BUILD_PATH is empty";
      exit 1;
fi

zip -r "${RELEASE_FOLDER}/stable/playbook.zip" roles **/*.yml *.cfg *.txt
mc mirror "${LOCAL_BUILD_PATH}" "default/${S3_BUCKET}/${RELEASE_FOLDER}/${RELEASE_VERSION}/" --overwrite
mc mirror "${LOCAL_BUILD_PATH}" "default/${S3_BUCKET}/${RELEASE_FOLDER}/stable/" --overwrite
