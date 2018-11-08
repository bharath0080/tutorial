String buildVersion = env.BUILD_NUMBER
String gitCommitMsg = 'Unknown commit'

try {
  String gitCommitId

  /*
   * Pull the sourcecode and metadata from GitHub.
   */
  stage('Checkout') {
    node {
      sh "oc project ${env.PROJECT_NAME}"

      checkout scm
      stash includes: 'openshift/*', name: 'scripts'

      String gitCommitNum = sh(returnStdout: true, script: 'git rev-list HEAD --count').trim()
      String gitShortId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
      buildVersion = gitCommitNum + '-' + gitShortId

      gitCommitId = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
      gitCommitMsg = sh(returnStdout: true, script: 'git log --format=%B -n 1 HEAD').trim()
    }
  }

  /*
   * Update the OpenShift build and deploy templates that will be used by the pipeline.
   */
  stage('Apply Templates') {
    applyTemplates()
  }

  /*
   * Trigger the OpenShift Docker build, and store the resulting image, tagged with the GitHub commit.
   */
  stage('Build Image') {
    build(
      name: 'greetings',
      buildVersion: buildVersion,
      gitCommitId: gitCommitId
    )
  }

  /*
   * Run the unit tests in a standalone pod. Test results will be uploaded to SonarQube.
   */
  // stage('Sonarqube Test') {
  //   test(
  //     name: 'greetings',
  //     buildVersion: buildVersion
  //   )
  // }

  /*
   * Deploy to staging environment.
   */
  stage('Deploy Staging') {
    deploy(
      buildVersion: buildVersion,
      environment: 'staging',
      numReplicas: 1
    )
  }

  /*
   * Load test the staging environment.
   */
  // stage('Load Test Staging') {
  //   loadTest(
  //     buildVersion: buildVersion,
  //     environment: 'staging'
  //   )
  // }

  /*
   * Prompt a developer to make the release.
   */
  // stage('User Input') {
  //   notifyBuild(
  //     message: 'Build is ready for Production',
  //     color: '#0000FF',
  //     emoji: 'shipitparrot',
  //     buildVersion: buildVersion,
  //     gitCommitMsg: gitCommitMsg
  //   )
  //   timeout(time:1, unit:'HOURS') {
  //     input 'Deploy to Production?'
  //   }
  // }

  /*
   * Deploy to production environment.
   */
  // stage('Deploy Production') {
  //   deploy(
  //     buildVersion: buildVersion,
  //     environment: 'production',
  //     numReplicas: 3
  //   )
  // }

  currentBuild.result = 'SUCCESS'
}
catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException flowError) {
  currentBuild.result = 'ABORTED'
}
catch (err) {
  currentBuild.result = 'FAILURE'
  notifyBuild(
    message:  'Build failed',
    color: '#FF0000',
    emoji: 'sadparrot',
    buildVersion: buildVersion,
    gitCommitMsg: gitCommitMsg
  )
  throw err
}
finally {
  if (currentBuild.result == 'SUCCESS') {
    notifyBuild(
      message: 'Production deploy successful',
      color: '#00FF00',
      emoji: 'nyanparrot',
      buildVersion: buildVersion,
      gitCommitMsg: gitCommitMsg
    )
  }
}

def applyTemplates() {
  node {
    unstash 'scripts'
    sh('openshift/run-apply-templates.sh')
  }
}

def build(Map attrs) {
  node {
    boolean imageTagExists = sh(
      returnStatus: true,
      script: "oc get istag ${attrs.name}:${attrs.buildVersion}"
    ) == 0

    if (!imageTagExists) {
      openshiftBuild(
        buildConfig: attrs.name,
        commitID: attrs.gitCommitId,
        waitTime: '3600000'
      )

      openshiftTag(
        sourceStream: attrs.name,
        destinationStream: attrs.name,
        sourceTag: 'latest',
        destinationTag: attrs.buildVersion,
        namespace: env.PROJECT_NAME
      )
    }
  }
}

def test(Map attrs) {
  node {
    unstash 'scripts'
    ansiColor('xterm') {
      sh("./openshift/run-test.sh ${attrs.name} ${attrs.buildVersion}")
    }
  }
}

def deploy(Map attrs) {
  node {
    unstash 'scripts'
    sh("""
      ./openshift/run-deploy.sh ${attrs.environment} ${attrs.buildVersion} ${attrs.numReplicas}
      ./openshift/run-newrelic-notify.sh greetings ${attrs.environment} ${attrs.buildVersion}
    """)

    openshiftVerifyDeployment(
      deploymentConfig: "greetings-${attrs.environment}",
      waitTime: '1800000'
    )
  }
}

def loadTest(Map attrs) {
  node {
    unstash 'scripts'
    ansiColor('xterm') {
      sh("./openshift/run-load-test.sh ${attrs.environment} ${attrs.buildVersion}")
    }
  }
}

def notifyBuild(Map attrs) {
  node {
    String route = sh(returnStdout: true, script: 'oc get route jenkins -o=\'jsonpath={.spec.host}\'').trim()
    String url = "https://${route}/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/console"

    slackSend(
      color: attrs.color,
      message: "_${env.JOB_NAME}_ <${url}|${attrs.buildVersion}>\n*${attrs.message}* :${attrs.emoji}:\n```${attrs.gitCommitMsg}```",
      teamDomain: 'raizv',
      channel: '#notifications',
      token: env.SLACK_TOKEN
    )
  }
}
