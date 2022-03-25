# ArgoCD Repository for Jenkins Deployment

## Features

This repository uses Helm to deploy Jenkins:

## How to deploy an environment?

Run the following commands on your ArgoCD-enabled Kubernetes cluster to deploy an environment.

* Sample "Development" environment:
    ```
    kubectl.exe apply -f https://raw.githubusercontent.com/mariusjacobs/jenkins-argocd/main/application-dev.yaml
    ```

## Access the Jenkins web UI console

* Get url to access console
    ```
    kubectl get service jenkins -n jenkins -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
    ```
* Get `admin` user's password
    ```
    powershell -Command "[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(kubectl -n jenkins get secret jenkins -o jsonpath='{.data.jenkins-admin-password}')))"
    ```
* Navigate to the url and enter `admin` for username and the password returned by the previous command
