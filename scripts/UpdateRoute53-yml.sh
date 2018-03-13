#!/bin/bash

echo "Running UpdateRoute53.sh"

stackName=$1

yum install –y epel-release
curl -O https://bootstrap.pypa.io/get-pip.py
export PATH=~/.local/bin:$PATH
python get-pip.py --user
pip install awscli --upgrade --user
pip install boto

yum install ansible --enablerepo=epel -y

echo stackName \'$stackName\'



if [ $( grep -cw ansible_connection /etc/ansible/hosts) -eq "0" ];then
cat >>/etc/ansible/hosts <<EOF
[localhost]
localhost ansible_connection=local ansible_python_interpreter=python
EOF
fi

region=ap-south-1
zone_name=glp-test.com
rec_name=test.glp-test.com
ec2_tag_key=Name
ec2_tag_value=Couchbase-${stackName}-Server

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
  - ec2_remote_facts:
     region: "{{REGION}}"
     filters:
      instance-state-name: running
      "tag:Name": "{{ec2_tag_value}}"
    register: ec2_remote_facts

  - set_fact: private_ip="{{private_ip|default([])+[item.private_ip_address]}}"
    with_items: "{{ ec2_remote_facts.instances }}"

  - name: Updatading route 53
    route53:
     state: present
     overwrite: true
     private_zone: true
     zone: "{{zone_name}}"
     record: "{{rec_name}}"
     type: A
     ttl: 30
     value: "{{private_ip}}"
EOF
ansible-playbook route53.yml
