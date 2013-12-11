#!/bin/bash

set -x
export AWS_DEFAULT_REGION=ap-northeast-1

# role format : nat-{instanceid}
while read hostname ip role
do
  peerinstanceid=$(echo ${role} | sed -e 's/nat-//')
done
myinstanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)

routetableid=$(aws ec2 describe-route-tables | jq -r '.RouteTables[] | select(.Routes[].InstanceId == "'${peerinstanceid}'") | .RouteTableId')

if [ -z "${routetableid}" ]; then
    echo 'no failover executed'
    exit 0
fi

aws ec2 delete-route --route-table-id ${routetableid} --destination-cidr-block 0.0.0.0/0
aws ec2 create-route --route-table-id ${routetableid} --destination-cidr-block 0.0.0.0/0 --instance-id ${myinstanceid}
