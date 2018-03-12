#!/bin/bash

echo "Running UpdateRoute53.sh"


stackName=$1

echo stackName \'$stackName\'

region=ap-south-1
zone_name=glp-test.com
rec_name=test.glp-test.com
ec2_tag_key=Name
ec2_tag_value=Couchbase-${stackName}-Server
zone_id=$(aws route53 list-hosted-zones|grep -B 1 $zone_name|grep "Id"|head -n 1|awk '{print $2}'|cut -d '/' -f 3|tr -d '"'|tr -d ',')
zone_id=$zone_id


c1()
{
ip1=$(cat ip_list |tr '\n' ' '|awk '{print $1}')
echo "{\"Comment\": \"A new record set for the zone.\", \"Changes\":[{\"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${rec_name}.\", \"Type\": \"A\", \"TTL\": 30, \"ResourceRecords\": [{\"Value\": \""$ip1"\"}]}}]}" > test.json
aws --region $region route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://test.json
}

c2()
{
ip1=$(cat ip_list |tr '\n' ' '|awk '{print $1}')
ip2=$(cat ip_list |tr '\n' ' '|awk '{print $2}')
echo "{\"Comment\": \"A new record set for the zone.\", \"Changes\":[{\"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${rec_name}.\", \"Type\": \"A\", \"TTL\": 30, \"ResourceRecords\": [{\"Value\": \""$ip1"\"},{\"Value\": \""$ip2"\"}]}}]}" > test.json
aws --region $region route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://test.json
}

c3()
{
ip1=$(cat ip_list |tr '\n' ' '|awk '{print $1}')
ip2=$(cat ip_list |tr '\n' ' '|awk '{print $2}')
ip3=$(cat ip_list |tr '\n' ' '|awk '{print $3}')
echo "{\"Comment\": \"A new record set for the zone.\", \"Changes\":[{\"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${rec_name}.\", \"Type\": \"A\", \"TTL\": 30, \"ResourceRecords\": [{\"Value\": \""$ip1"\"},{\"Value\": \""$ip2"\"},{\"Value\": \""$ip3"\"}]}}]}" > test.json
aws --region $region route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://test.json
}


c4()
{
ip1=$(cat ip_list |tr '\n' ' '|awk '{print $1}')
ip2=$(cat ip_list |tr '\n' ' '|awk '{print $2}')
ip3=$(cat ip_list |tr '\n' ' '|awk '{print $3}')
ip4=$(cat ip_list |tr '\n' ' '|awk '{print $4}')
echo "{\"Comment\": \"A new record set for the zone.\", \"Changes\":[{\"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${rec_name}.\", \"Type\": \"A\", \"TTL\": 30, \"ResourceRecords\": [{\"Value\": \""$ip1"\"},{\"Value\": \""$ip2"\"},{\"Value\": \""$ip3"\"},{\"Value\": \""$ip4"\"}]}}]}" > test.json
aws --region $region route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file://test.json
}

aws --region $region route53 list-resource-record-sets --hosted-zone-id $zone_id --query "ResourceRecordSets[?Name == '${rec_name}.']"
aws --region $region ec2 describe-instances --filters "Name=tag:${ec2_tag_key},Values=${ec2_tag_value}" "Name=network-interface.addresses.private-ip-address,Values=*" --query 'Reservations[*].Instances[*].{InstanceId:InstanceId,PrivateDnsName:PrivateDnsName,State:State.Name, IP:NetworkInterfaces[0].PrivateIpAddress}'|grep -w IP|awk '{print $2}'|tr -d ','|tr -d '"' > ip_list

ip_count=$(wc -l ip_list|awk '{print $1}')
if [ "$ip_count" == "0" ];then
echo "Cant Find IP's" > route53.error
exit 0
elif [ "$ip_count" == "1" ];then
echo " Adding one IP on Route53"
c1
elif [ "$ip_count" == "2" ];then
 echo " Adding two IP's on Route53"
 c2
elif [ "$ip_count" == "3" ];then
  echo " Adding three IP's on Route53"
  c3
elif [ "$ip_count" == "4" ];then
  echo " Adding Four IP's on Route53"
  c4
else
  echo "Cant Add more than 4 IP's"
  c4

fi
