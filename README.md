# ArgoCD Repository for Jenkins Deployment

## Overview

This repository uses Helm to deploy Jenkins. The following resources were used in setting up this repository:

* [Deploying Jenkins on Amazon EKS with Amazon EFS](https://aws.amazon.com/blogs/storage/deploying-jenkins-on-amazon-eks-with-amazon-efs/)
* [Kubernetes page on jenkins.io](https://www.jenkins.io/doc/book/installing/kubernetes/)



## Create an EKS Cluster

1. Create an EKS cluster using your preferred mechanism. For example:

    ```
    eksctl create cluster --name kube-demo --region us-west-1 --zones us-west-1a,us-west-1b --managed --nodegroup-name mynodegroup
    ```

2. Test access to the cluster
    ```
    kubectl get svc
    ```

## Create an Amazon EFS file system

1. Capture your VPC ID
    ```
    aws ec2 describe-vpcs    
    ```


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
