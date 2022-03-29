# ArgoCD Repository for Jenkins Deployment

## Overview

This repository uses Helm to deploy Jenkins. The following resources were used in setting up this repository:

* [Deploying Jenkins on Amazon EKS with Amazon EFS](https://aws.amazon.com/blogs/storage/deploying-jenkins-on-amazon-eks-with-amazon-efs/)
* [Kubernetes page on jenkins.io](https://www.jenkins.io/doc/book/installing/kubernetes/)

## Create an EKS Cluster

1. Create an EKS cluster using your preferred mechanism. For example:
    ```
    eksctl.exe create cluster --name kube-demo --region us-west-1 --zones us-west-1b,us-west-1c --managed --nodegroup-name mynodegroup
    ```

1. Test access to the cluster
    ```
    kubectl.exe get svc
    ```

## Deploy ArgoCD to the cluster

1. Create a namespace and deploy ArgoCD
    ```
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```
1. Change ArgoCD service type to load balancer
    kubectl patch svc argocd-server -n argocd --patch-file service-patch.yaml

1. Wait for all ArgoCD pods to be running
    ```
    kubectl get pods -n argocd
    ```
1. Get url to access the ArgoCD console
    ```
    kubectl get service argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
    ```
1. Get ArgoCD `admin` user's password
    ```
    powershell -Command "[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}')))"
    ```
* Navigate to the url and enter `admin` for username and the password returned by the previous command. Note, load balancer may take some time to be provisioned.


## Create an Amazon EFS file system

1. Run the following powershell script to create an EFS file system and the necessary security group and access point to access EFS. The script also deploys the Amazon EFS CSI driver to your Amazon EKS cluster:
    ```
    .\createEFSVolume.ps1 "kube-demo" "us-west-1"
    ```

## Update jenkins-argocd repository to reference the new EFS file system

1. Copy the value of "Volume Handle" emitted by the script (e.g. fs-09d9303836dd1f422::fsap-001b3fa0c5e4a452c) and paste it as the value of `volumeHandle` in the `values.yaml file.`. E.g.:
    ```
    volumeHandle: "fs-09d9303836dd1f422::fsap-001b3fa0c5e4a452c"
    ```
1. Push changes to the repo so that argocd will see the change in values.yaml.

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

## TODO: Add Cleanup