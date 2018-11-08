# Tutorial

Django application, utilizing a CI/CD build pipeline with Docker, OpenShift and Jenkins. 

## Installation 

Install Jenkins into the project
```
git clone https://github.com/raizv/jenkins.git
oc project projectName
openshift/install.sh
```

then run [install.sh][install.sh] from the application repo
```
git clone https://github.com/raizv/tutorial.git
openshift/install.sh
```

## CI/CD pipeline
CI/CD pipeline is configured in [Jenkinsfile][Jenkinsfile].

1. *Checkout* - pull source code and metadata from GitHub, assign `buildVersion` variable.

2. *Apply Templates* - create buildConfig and imageStream.

3. *Build Image* - build Docker Image, push to ImageStream and tag it with `buildVersion`, if image with that buildVersion already exist skip build and go to the next step.

4. *DB Migrate* - sync with database `python manage.py migrate`.

5. *Deploy Staging* - deploy to Staging environment, notify Newrelic about deployment and validate that deployment has been successful.

7. *User Input* - optional step, promt developer to make a deployment to production environment. 

8. *Deploy Production* - deploy to Production environment, notify Newrelic about deployment and validate that deployment has been successful.

9. *Notification to Slack* - send notification message with build details to specified Slack channel.

## Openshift Install Script

[install.sh][install.sh] takes parameter BRANCH that allows to provision an application from feature branches in test and demo Openshift projects. Also there is a way to deploy any number of application instances just with changing `APP_NAME` in [install.sh][install.sh], [openshift-template][openshift-template] and `run-*.sh` scripts.

Every triggered build in a pipeline has it's own `buildVersion`:
```
gitCommitNum = git rev-list HEAD --count
gitShortId = git rev-parse --short HEAD
buildVersion = gitCommitNum + '-' + gitShortId
```
That `buildVersion` is assigned to docker image and then promotes through Jenkins pipeline, so you always know what version has been deployed to production.


## Openshift Template

[openshift-template][openshift-template] has all necessary objects for provisioning microservice - ImageStream, BuildConfig, DeploymentConfig, Service, Route and AutoScaler. Every change made to a code of application or code related to infrastructure will be applied and tested in CI/CD pipeline. If there is a breaking change - pipeline will fail in `Apply Template` step or in one of `Deployment ...` steps and it will prevent this change to affect production environment.

For debug purposes any step from CI/CD pipeline might be triggered manually by using openshift client
```
oc start-build pipelineName
oc start-build buildName
oc rollout buildVersion dc/deploymentConfig
```
or by executing shell scripts from openshift directory.

### Service is reasonably resilient and a single node failure does not affect end users

DeploymentConfig has a parameter `replicas` - number of instances to run per deployment. It's set to 1 for staging environment and to 3 for production. This paramater might be overwritten in [Jenkinsfile][Jenkinsfile].


### Service can be scaled, preferably automatically, to handle increased loads
`HorizontalPodAutoscaler` specified in [openshift-template][openshift-template] scales up number of instances if current CPU utilization is more than 80% of the requested value.


## Local Development

### Run

Locally, this application is exposed on: http://localhost:8000/ (see [docker-compose.yml][docker-compose]):
```bash
docker-compose up --build web
```

*NOTE*: With great power, comes great responsibility...

[openshift]: ./openshift/README.md
[openshift-template]: ./openshift/openshift-template.yml
[HorizontalPodAutoscaler]: ./openshift/openshift-template.yml
[install.sh]: ./openshift/install.sh
[docker-compose]: ./docker-compose.yml
[jenkinsfile]: ./Jenkinsfile
