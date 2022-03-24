# ArgoCD Repository for Jenkins Deployment

## Features

This repository uses Helm to deploy Jenkins:

## How to deploy an environment?

Run the following commands on your ArgoCD-enabled Kubernetes cluster to deploy an environment.

* Sample "Development" environment:
    ```
    kubectl.exe apply -f https://raw.githubusercontent.com/mariusjacobs/jenkins-argocd/main/application-dev.yaml
    ```

