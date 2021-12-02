#!/bin/bash
mkdir /opt/IBM/
cd /opt/IBM/
response=$(curl -so checksum.txt -w "%{http_code}" https://raw.githubusercontent.com/IBM-Cloud/vpc-migration-tools/main/v2v-discovery-tool-rmm/checksum.txt)
if [ "$response" -eq "200" ]; then
    echo "checksum.txt file download successfully, http response code is: $response" >/var/log/discovery_download_script.log
else
    echo "Failed downloading file checksum.txt, http response code is $response" >>/var/log/discovery_download_script.log
    exit 1
fi
response=$(curl -so config.ini -w "%{http_code}" https://raw.githubusercontent.com/IBM-Cloud/vpc-migration-tools/main/v2v-discovery-tool-rmm/config.ini)
if [ "$response" -eq "200" ]; then
    echo "config.ini file download successfully, http response code is: $response" >>/var/log/discovery_download_script.log
else
    echo "Failed downloading file config.ini, http response code is $response" >>/var/log/discovery_download_script.log
    exit 1
fi
response=$(curl -so discoveryTool -w "%{http_code}" https://raw.githubusercontent.com/IBM-Cloud/vpc-migration-tools/main/v2v-discovery-tool-rmm/discoveryTool)
if [ "$response" -eq "200" ]; then
    echo "discoveryTool file download successfully, http response code is: $response" >>/var/log/discovery_download_script.log
else
    echo "Failed downloading file discoveryTool, http response code is $response" >>/var/log/discovery_download_script.log
    exit 1
fi
echo "Updating discovery permission" >>/var/log/discovery_download_script.log
chmod +x discoveryTool
discoverytoolchecksum=($(awk 'NR==1 {print $1}' checksum.txt))
configinichecksum=($(awk 'NR==2 {print $1}' checksum.txt))
discoveryTool_cksum="$(cksum discoveryTool | awk '{print $1}')"
configini_cksum="$(cksum config.ini | awk '{print $1}')"
if [ "$discoverytoolchecksum" -eq "$discoveryTool_cksum" ]; then
    echo "checksum discoveryTool match" >>/var/log/discovery_download_script.log
else
    echo "checksum discovery Tool not match" >>/var/log/discovery_download_script.log
fi
if [ "$configinichecksum" -eq "$configini_cksum" ]; then
    echo "checksum config.ini match" >>/var/log/discovery_download_script.log
else
    echo "checksum config.ini Tool not match" >>/var/log/discovery_download_script.log
fi
