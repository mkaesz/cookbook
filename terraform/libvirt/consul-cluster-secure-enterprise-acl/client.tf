resource "libvirt_volume" "volume_client" {
  name           = "volume-consul-client-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.consul_clients
}

resource "tls_cert_request" "consul_client" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "${var.consul_datacenter}-client-consul-${count.index}",
    "client.${var.consul_datacenter}.consul",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.consul_datacenter}-client-consul-${count.index}"
    organization = "mskmania"
  }

  count          = var.consul_clients
}

resource "tls_locally_signed_cert" "consul_client" {
  cert_request_pem = tls_cert_request.consul_client[count.index].cert_request_pem

  ca_key_algorithm   = tls_private_key.consul_ca.algorithm
  ca_private_key_pem = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count          = var.consul_clients
}

data "template_file" "consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "${var.consul_datacenter}-client-consul-${count.index}"
    consul_cluster_nodes = jsonencode(values(local.consul_cluster_servers_expanded))
    gossip_password = base64encode(random_string.consul_gossip_password.result)
    datacenter = var.consul_datacenter
    consul_default_token = random_uuid.consul_default_token[count.index].result
  }
  count = var.consul_clients
}

data "template_file" "user_data_client" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "${var.consul_datacenter}-client-consul-${count.index}"
    consul_config = base64encode(data.template_file.consul_client_config[count.index].rendered)
    ca_file = base64encode(tls_self_signed_cert.consul_ca.cert_pem)
    cert_file = base64encode(tls_locally_signed_cert.consul_client[count.index].cert_pem)
    key_file = base64encode(tls_private_key.consul.private_key_pem)
  }
  count	= var.consul_clients
}

data "template_file" "network_config_client" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit_client" {
  name           = "commoninit-client-${count.index}.iso"
  user_data      = data.template_file.user_data_client[count.index].rendered
  network_config = data.template_file.network_config_client.rendered
  pool           = libvirt_pool.consul.name
  count          = var.consul_clients
}

resource "random_uuid" "consul_default_token" { 
 count          = var.consul_clients
}

resource "libvirt_domain" "consul_client" {
  name = "${var.consul_datacenter}-client-consul-${count.index}"
  count = var.consul_clients

  cloudinit = libvirt_cloudinit_disk.commoninit_client[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_client.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}
provisioner "remote-exec" {
    inline = [
      "consul acl token create -policy-name ${self.name} -secret ${random_uuid.consul_default_token[count.index].result} -description '${self.name}'",
    ]

connection {
  type = "ssh"
  user = "mkaesz"
  host = "dc1-bastion.msk.local"
  private_key = file("~/.ssh/id_rsa")
}
  }

  depends_on = [
    consul_acl_policy.agent_client_policy,
  ]

}

output "clients" {
  value = libvirt_domain.consul_client.*.name
}

output "client_ips" {
  value = libvirt_domain.consul_client.*.network_interface.0.addresses
}
