#!/bin/bash

parameters=$#

if [ $# -ne 3 ]
then
echo "This script requires 3 parameter to be passed(image-id,key-name,security-group-id).Please pass the right number of parameters and run the script again."
else
echo -e "\e[1m Lab4 Create Script"
echo -e "Creating 3 micro instances \e[0m"
aws ec2 run-instances --image-id $1 --key-name $2 --security-group-ids $3 --instance-type t2.micro --user-data file://installapp.sh --count 3 --placement AvailabilityZone=us-west-2a
echo -e "New Instances are created"

echo -e "\e[1mWait untill the Instance are in  Running State\e[0m"
instance_id=$(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId]' --filters Name=instance-state-name,Values=pending)
echo $instance_id
aws ec2 wait instance-running --instance-ids $instance_id
echo -e "Wait is completed and instances are now in Running state"

echo -e "\e[1mCreating a Load Balancer\e[0m"
aws elb create-load-balancer --load-balancer-name itmo-544 --listeners Protocol=Http,LoadBalancerPort=80,InstanceProtocol=Http,InstancePort=80 --subnets subnet-1865246e
echo -e "Load balancer is  created successfully"

echo -e "\e[1mRegistering instances with the load balancer \e[0m"
aws elb register-instances-with-load-balancer --load-balancer-name itmo-544 --instances $instance_id
echo -e "Instances are registered to load balancer successfully"

echo -e "\e[1mCreating Autoscaling Launch Configuration\e[0m"
aws autoscaling create-launch-configuration --launch-configuration-name webserver --image-id $1 --key-name $2 --instance-type t2.micro --user-data file://installapp.sh
echo -e "Autoscaling Launch Configuration created successfully"

echo -e "\e[1mCreating Autoscaling Group\e[0m"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name webserverdemo --launch-configuration webserver --availability-zone us-west-2a --max-size 5 --min-size 0 --desired-capacity 1
echo -e "AutoScaling Group Created Successfully"

echo -e "\e[1mAttaching created instances to auto scaling group \e[0m"
aws autoscaling attach-instances --instance-ids $instance_id --auto-scaling-group-name webserverdemo
echo -e "Instances attached to auto-scaling-group successfully"

echo -e "\e[1mAttaching load balancer to auto scaling group\e[0m"
aws autoscaling attach-load-balancers --auto-scaling-group-name webserverdemo --load-balancer-names itmo-544
echo -e "Load balancer attached to auto-scaling-group successfully"
fi
