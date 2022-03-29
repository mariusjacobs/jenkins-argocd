# Script to EFS volume of EKS cluster
# NOTE: This script should be replaced with terraform

param ($eksClusterName = "kube-demo", $region = "us-west-1")

# Function to get the VPC that was created by eksctl for a given cluster
function Get-EksVpcId ([string] $eksClusterName) {
    $vpcs = Get-EC2Vpc

    foreach ($vpc in $vpcs) {
        foreach ($tag in $vpc.Tags) {
            if ($tag.Key -eq "Name" -and $tag.Value -eq "eksctl-$eksClusterName-cluster/VPC" ) {
                return $vpc.VpcId
            }
        }
    }
}

# Function to get the subnet ids for a given VPC (either public or private)
function Get-SubnetIds ([string] $vpcId, [bool] $public) {
    $subnets = Get-EC2Subnet
 
    $result = @()
    foreach ($subnet in $subnets) {
        if ($subnet.VpcId -eq $vpcId -and $subnet.MapPublicIpOnLaunch -eq $public) {
            $result += $subnet.SubnetId

            # Write-Host ($subnet | Format-List | Out-String)
        }
    }
    return $result
}

# Function to get the security group assigned to nodes in the cluster
function Get-NodeSecurityGroup ([string] $vpcId) {
    $securityGroups = Get-EC2SecurityGroup

    foreach ($securityGroup in $securityGroups) {
        if ($securityGroup.GroupName.Contains("ClusterSharedNodeSecurityGroup")) {
            return $securityGroup.GroupId
        }
        # Write-Host ($securityGroup | Format-List | Out-String)
    }
    return "temp"
}
 
# Set the default AWS region
Set-DefaultAWSRegion -Region $region

# Lookup VPC, subnet and security group details for the given EKS cluster
Write-Host "Getting VPC..."
$vpcId = Get-EksVpcId $eksClusterName
Write-Host $vpcId

Write-Host "Getting Subnet..."
$publicSubnetIds = Get-SubnetIds $vpcId $true
$privateSubnetIds = Get-SubnetIds $vpcId $false
$nodeSecurityGroup = Get-NodeSecurityGroup $vpcId

Write-Host "Creating security group..."
$groupId = New-EC2SecurityGroup `
    -VpcId $vpcId `
    -GroupName "efs-mount-sg" `
    -GroupDescription "Amazon EFS for EKS, SG for mount target"

Write-Host "Granting security group ingress..."
Grant-EC2SecurityGroupIngress `
    -GroupId $groupId `
    -IpPermission @( @{ IpProtocol="tcp"; FromPort="2049"; ToPort="2049"; IpRanges="192.168.0.0/16" })

Write-Host "Granting security group ingress..."
$fileSystem = New-EFSFileSystem `
    -CreationToken "creation-token" `
    -PerformanceMode generalPurpose `
    -ThroughputMode bursting 

$fileSystemId = $fileSystem.FileSystemId

Write-Host "Waiting for file system to become available..." -NoNewline

$done = $false
while ($done -ne $true) {
    $fs = Get-EFSFileSystem -FileSystemId $fileSystemId
    if ($fs.LifeCycleState -eq "available") {
        Write-Host "Done." -NoNewline
        $done = $true
    } else {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
}
Write-Host ""

Write-Host "Creating mount targets..."
foreach ($subnetId in $privateSubnetIds) {
    Write-Host "Creating mount target for subnet $subnetId"
    New-EFSMountTarget `
        -FileSystemId $fileSystemId `
        -SubnetId $subnetId `
        -SecurityGroup @( $groupId )
}

Write-Host "Creating access point..."
$accessPoint = New-EFSAccessPoint `
    -FileSystemId $fileSystemId `
    -PosixUser_Uid 1000 `
    -PosixUser_Gid 1000 `
    -RootDirectory_Path "/jenkins" `
    -CreationInfo_OwnerUid 1000 `
    -CreationInfo_OwnerGid 1000 `
    -CreationInfo_Permission "777" 

$fsId = $accessPoint.FileSystemId
$apId = $accessPoint.AccessPointId

# Deploy the Amazon EFS CSI driver to your Amazon EKS cluster
kubectl.exe apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

Write-Host "Volume Handle:"
Write-Host "$fsId::$apId"

