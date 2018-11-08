#!/bin/sh
set -o nounset -o errexit
cd `dirname $0`

# Applies the OpenShift templates and processes them for your currently configured branch
# Usage: ./run-apply-templates.sh

APP_NAME=tutorial
CURRENT_BRANCH=`oc get bc ${APP_NAME}-pipeline -o='jsonpath={.spec.source.git.ref}'`

oc apply -f openshift-template.yml
oc process ${APP_NAME}-pipeline BRANCH=${CURRENT_BRANCH} | oc apply -f -
