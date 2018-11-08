#!/bin/sh
set -o nounset -o errexit
cd `dirname $0`

# Installs the build pipeline for a given branch (default: master) in your currently selected OpenShift project
# See: README.md

APP_NAME=tutorial
BRANCH=${1:-master}

# Github SSH Key
oc create secret generic github-secret --from-file=ssh-privatekey=id_rsa --dry-run -o yaml | oc apply -f -

# Newrelic License
oc create secret generic newrelic-license-secret \
    --from-literal=newrelic-license="newrelic-license" \
    --dry-run -o yaml | oc apply -f -

# Newrelic API Key
oc create secret generic newrelic-api-secret \
    --from-literal=newrelic-key="newrelic-key" \
    --dry-run -o yaml | oc apply -f -

# Sonarqube Token
oc create secret generic sonarqube-token-secret \
    --from-literal=sonarqube-token="sonarqube-token" \
    --dry-run -o yaml | oc apply -f -

# Apply and execute the OpenShift template
oc apply -f openshift-template.yml
oc process ${APP_NAME}-pipeline BRANCH=${BRANCH} | oc apply -f -
oc start-build ${APP_NAME}-pipeline
