#cloud-config
# vim: syntax=yaml
hostname: ${hostname}
users:
  - name: mkaesz
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1pY0voKcNrZrsVbVe0VLDxTDRxfbbjAE3Cv5bIWEcYJwbAYUl0TZ0JkFAoYGCKG9Ml0Ddq+pyrPKlEBWnyblPmiKOwHnwPsjPtjGUuFGNlOcpfgOf5nDEo/OdOIlHrPJYRbTVAmXBSS99MjmJQJdGMwOsIiASU+1wJZtmya7yT9/y3GepoesiCzFwibpzsISa2Jucik6awNcIfrTkMwp3DPunbAESpJf9sGRRlF2LQffEKn1FKL8ECZEjXt8+u600ze5+wKq2ciWcMkZql6yiC38t+pU/+9zM1UYVLRX1s8BweH3AId7Gfa2bMuaaYCmd2xaz8K2YQ5AVE5Mle6l7gpxcGQl8ZXiwrqjlt7SeK0dBpb150K40S+wgzG3CxQ84Ai0sfSdO9dlrbDOJ2efWbhbEWllkOpdlO9lKg4YSBxDkETnTpheUlwxPb5cINkr8dsUhI3o3sJcwOCFqTKnQY/6jkR/urjQEc1xw1c6VGPENo7RZzp0xRG3O7u6BNMc=
power_state:
  delay: "now"
  mode: reboot
  message: Bye Bye
  timeout: 30
  condition: True
write_files:
 - encoding: b64
   content: ${vault_config}
   owner: hcops:hcops
   path: /opt/vault/config/config.hcl
 - encoding: b64
   content: ${vault_ca_file}
   owner: hcops:hcops
   path: /opt/vault/config/vault-ca.pem
   permissions: '0644'
 - encoding: b64
   content: ${vault_cert_file}
   owner: hcops:hcops
   path: /opt/vault/config/${hostname}.crt
   permissions: '0644'
 - encoding: b64
   content: ${vault_key_file}
   owner: hcops:hcops
   path: /opt/vault/config/${hostname}.key
   permissions: '0644'
 - encoding: b64
   content: ${consul_config}
   owner: hcops:hcops
   path: /opt/consul/config/config.json
   permissions: '0644'
 - encoding: b64
   content: ${consul_ca_file}
   owner: hcops:hcops
   path: /opt/consul/config/consul-ca.pem
   permissions: '0644'
 - encoding: b64
   content: ${consul_cert_file}
   owner: hcops:hcops
   path: /opt/consul/config/${hostname}.crt
   permissions: '0644'
 - encoding: b64
   content: ${consul_key_file}
   owner: hcops:hcops
   path: /opt/consul/config/${hostname}.key
   permissions: '0644'
 - path: /etc/environment
   permissions: 0644
   content: |
     VAULT_ADDR=https://dc1-server-vault-0:8501
     CONSUL_HTTP_ADDR=https://dc1-server-consul-0:4646
     VAULT_CACERT=/opt/vault/config/vault-ca.pem
     CONSUL_CACERT=/opt/consul/config/consul-ca.pem
     VAULT_CLIENT_CERT=/opt/vault/config/${hostname}.crt
     CONSUL_CLIENT_CERT=/opt/consul/config/${hostname}.crt
     VAULT_CLIENT_KEY=/opt/vault/config/${hostname}.key
     CONSUL_CLIENT_KEY=/opt/consul/config/${hostname}.key
     VAULT_MODE=${vault_mode}
runcmd:
  - [ systemctl, enable, consul ]
  - [ systemctl, enable, vault ]
