#!/bin/bash
 
mkdir -p /opt/IBM/{VMware,HyperV}
 
if [[ $? -ne 0 ]]
then
echo "Failed while creating directory /opt/IBM/VMware and /opt/IBM/HyperV"
exit 1
else
echo "Directory /opt/IBM/VMware and /opt/IBM/HyperV created"
fi
 
cd /opt/IBM/VMware
 
for f in checksum.txt config.ini discoveryTool
do
  response=$(curl -so ${f} -w "%{http_code}" https://raw.githubusercontent.com/IBM-Cloud/vpc-migration-tools/rmm-v2v-h2v-discoverytool/v2v-discovery-tool-rmm/VMware/${f})
   if [ "$response" -eq "200" ]; then
    echo "${f} download complete - /opt/IBM/VMware, http response code is: $response" >>/var/log/discovery_download_script.log
   else
    echo "Failed downloading  ${f} to /opt/IBM/VMware, http response code is $response" >>/var/log/discovery_download_script.log
    exit 1
   fi
done
 
echo "Updating /opt/IBM/VMware/discoveryTool permission" >>/var/log/discovery_download_script.log
chmod +x discoveryTool
 
discoverytoolchecksum=($(awk 'NR==1 {print $1}' checksum.txt))
configinichecksum=($(awk 'NR==2 {print $1}' checksum.txt))
discoveryTool_cksum="$(cksum discoveryTool | awk '{print $1}')"
configini_cksum="$(cksum config.ini | awk '{print $1}')"
 
if [ "$discoverytoolchecksum" -eq "$discoveryTool_cksum" ]; then
    echo "checksum /opt/IBM/VMware/discoveryTool found match" >>/var/log/discovery_download_script.log
else
    echo "checksum /opt/IBM/VMware/discoveryTool mismatch" >>/var/log/discovery_download_script.log
fi
if [ "$configinichecksum" -eq "$configini_cksum" ]; then
    echo "checksum /opt/IBM/VMware/config.ini found match" >>/var/log/discovery_download_script.log
else
    echo "checksum /opt/IBM/VMware/config.ini mismatch" >>/var/log/discovery_download_script.log
fi
 

cd /opt/IBM/HyperV
if [[ $? -ne 0 ]]
then
echo "Failed fetching directory /opt/IBM/Hyper-V"
exit 1
else
#  echo "cd /opt/IBM/Hyper-V"
cd /opt/IBM/HyperV
fi
 
for f in checksum.txt config.ini discoveryTool
do
  response=$(curl -so ${f} -w "%{http_code}" https://raw.githubusercontent.com/IBM-Cloud/vpc-migration-tools/rmm-v2v-h2v-discoverytool/v2v-discovery-tool-rmm/HyperV/${f})
   if [ "$response" -eq "200" ]; then
    echo "${f} download complete - /opt/IBM/HyperV, http response code is: $response" >>/var/log/discovery_download_script.log
   else
    echo "Failed downloading ${f} to /opt/IBM/HyperV, http response code is $response" >>/var/log/discovery_download_script.log
    exit 1
   fi
done
 
echo "Updating /opt/IBM/HyperV/discoveryTool permission" >>/var/log/discovery_download_script.log
chmod +x discoveryTool
 
discoverytoolchecksum=($(awk 'NR==1 {print $1}' checksum.txt))
configinichecksum=($(awk 'NR==2 {print $1}' checksum.txt))
discoveryTool_cksum="$(cksum discoveryTool | awk '{print $1}')"
configini_cksum="$(cksum config.ini | awk '{print $1}')"
 
if [ "$discoverytoolchecksum" -eq "$discoveryTool_cksum" ]; then
    echo "checksum /opt/IBM/HyperV/discoveryTool found match" >>/var/log/discovery_download_script.log
else
    echo "checksum /opt/IBM/HyperV/discoveryTool mismatch" >>/var/log/discovery_download_script.log
fi
if [ "$configinichecksum" -eq "$configini_cksum" ]; then
    echo "checksum opt/IBM/HyperV/config.ini found match" >>/var/log/discovery_download_script.log
else
    echo "checksum /opt/IBM/HyperV/config.ini mismatch" >>/var/log/discovery_download_script.log
fi
