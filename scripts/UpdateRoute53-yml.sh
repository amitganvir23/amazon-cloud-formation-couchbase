#!/bin/bash

echo "Running UpdateRoute53.sh"
stackName=$1

yum install epel-release -y
curl -O https://bootstrap.pypa.io/get-pip.py
export PATH=~/.local/bin:$PATH
python get-pip.py --user
pip install awscli --upgrade --user
pip install boto

yum install ansible --enablerepo=epel -y

echo stackName \'$stackName\'

region=$2
zone_name=glp-test.com
rec_name=test.glp-test.com
#ec2_tag_key=Name
#ec2_tag_value=Couchbase-${stackName}-ServerRally
#ec2_tag_value=Couchbase-${stackName}-Server

ec2_tag_key=Couchbase-Cluster
ec2_tag_value=${stackName}

my_inventory=myhosts

cat > $my_inventory <<EOF
[localhost]
localhost ansible_connection=local ansible_python_interpreter=python
EOF

echo "-----------------------"
echo -e "zone_name=$zone_name \nRegion=$region \nRecorName=$rec_name \nec2_tag_key=$ec2_tag_key \nec2_tag_value=$ec2_tag_value\nzone_id=$zone_id \nstackName=$stackName"
echo "-----------------------"

cat > route53.yml <<EOF
---
- hosts: localhost
  vars:
       - REGION: ${region}
       - zone_name: ${zone_name}
       - rec_name: ${rec_name}
       - ec2_tag_key: ${ec2_tag_key}
       - ec2_tag_value: ${ec2_tag_value}

  tasks:
   - name: Collecting Private IP address
     shell: "aws --region {{REGION}} ec2 describe-instances --filters \"Name=tag:{{ec2_tag_key}},Values={{ec2_tag_value}}\" \"Name=network-interface.addresses.private-ip-address,Values=*\" --query 'Reservations[*].Instances[*].{InstanceId:InstanceId,PrivateDnsName:PrivateDnsName,State:State.Name, IP:NetworkInterfaces[0].PrivateIpAddress}'|grep -w IP|awk '{print $2}'|tr -d ','|tr -d '\"'"
     register: private_ips

   - name: Updatading route 53
     route53:
      state: present
      overwrite: true
      private_zone: true
      zone: "{{zone_name}}"
      record: "{{rec_name}}"
      type: A
      ttl: 30
      value: "{{private_ips.stdout_lines}}"

EOF
ansible-playbook -i $my_inventory route53.yml -vv
