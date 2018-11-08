#!/bin/sh
set -o nounset -o errexit

# Runs `yarn run test` against a container on OpenShift. Used by the Test stage of the Jenkinsfile.
# Usage: ./run-test.sh app_name latest

CONTAINER_NAME=${1}
VERSION=${2:-latest}
IMAGESTREAM=`oc get imagestream ${CONTAINER_NAME} -o='jsonpath={.status.dockerImageRepository}'`

oc run ${CONTAINER_NAME}-${VERSION} \
  --image=${IMAGESTREAM}:${VERSION} \
  --rm=true \
  --attach=true \
  --restart=Never \
  --overrides='{
    "apiVersion":"v1",
    "spec":{
      "containers":[{
        "name": "'${CONTAINER_NAME}'-'${VERSION}'",
        "image": "'${IMAGESTREAM}':'${VERSION}'",
        "command":["python", "/code/manage.py", "migrate", "--noinput"],
        "env":[{
                "name": "DB_NAME", 
                "valueFrom":{
                  "secretKeyRef":{
                      "name": "postgres-secret"
                      "key": "name"
                  }
                }
              },
              "name": "DB_HOST", 
                "valueFrom":{
                  "secretKeyRef":{
                      "name": "postgres-secret"
                      "key": "host"
                  }
                }
              },
              "name": "DB_USER", 
                "valueFrom":{
                  "secretKeyRef":{
                      "name": "postgres-secret"
                      "key": "user"
                  }
                }
              },
              "name": "DB_PASSWORD", 
                "valueFrom":{
                  "secretKeyRef":{
                      "name": "postgres-secret"
                      "key": "password"
                  }
                }
              }]
      }]
    }
  }'
