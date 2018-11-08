#!/bin/sh
set -o nounset -o errexit

# Deploy a version to a specific OpenShift environment. Used by the Deploy stage of the Jenkinsfile.
# Usage: ./run-deploy.sh staging latest 1

APP_NAME=tutorial
ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}
NUM_REPLICAS=${3:-1}

IMAGESTREAM=`oc get imagestream ${APP_NAME} -o='jsonpath={.status.dockerImageRepository}'`

# workaround for https://github.com/kubernetes/kubernetes/issues/34413
if oc get hpa/${APP_NAME}-${ENVIRONMENT} > /dev/null 2>&1
then
  oc delete hpa/${APP_NAME}-${ENVIRONMENT}
fi

oc process ${APP_NAME} \
  -p VERSION=${VERSION} \
  -p ENVIRONMENT=${ENVIRONMENT} \
  -p DOCKER_REGISTRY="${IMAGESTREAM}:${VERSION}" \
  -p NUM_REPLICAS=${NUM_REPLICAS} \
  -o yaml | oc apply -f -
