#!/bin/sh

cd /tmp/

curl http://192.168.0.171:8088/workspace/images/replicated.tar.gz -o replicated.tar.gz
tar xfv replicated.tar.gz

mkdir -p /opt/tfe/{config,data}

curl http://192.168.0.171:8088/workspace/images/tfe-bundle.airgap -o /opt/tfe/config/tfe-bundle.airgap

sudo rm -rf /tmp/replicated.tar.gz

sudo chown -R hcops:hcops /opt/tfe
