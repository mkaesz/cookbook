resource "libvirt_volume" "volume_server" {
  name           = "volume-consul-server-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.consul_cluster_size
}

resource "tls_cert_request" "consul_server" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "${var.consul_datacenter}-server-consul-${count.index}",
    "server.${var.consul_datacenter}.consul",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.consul_datacenter}-server-consul-${count.index}"
    organization = "mskmania"
  }

  count          = var.consul_cluster_size
}

resource "tls_locally_signed_cert" "consul_server" {
  cert_request_pem = tls_cert_request.consul_server[count.index].cert_request_pem

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
  count          = var.consul_cluster_size
}

data "template_file" "consul_server_config" {
  template = "${file("${path.module}/templates/consul-server.json.tpl")}"
  vars = {
    node_name = "${var.consul_datacenter}-server-consul-${count.index}"
    cluster_size = var.consul_cluster_size
    consul_cluster_nodes = jsonencode(values(local.consul_cluster_nodes_expanded))
    gossip_password = base64encode(random_string.consul_gossip_password.result)
    datacenter = var.consul_datacenter
}
count = var.consul_cluster_size
}

data "template_file" "user_data_server" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "${var.consul_datacenter}-server-consul-${count.index}"
    consul_config = base64encode(data.template_file.consul_server_config[count.index].rendered)
    ca_file = base64encode(tls_self_signed_cert.consul_ca.cert_pem)
    cert_file = base64encode(tls_locally_signed_cert.consul_server[count.index].cert_pem)
    key_file = base64encode(tls_private_key.consul.private_key_pem)
  }
  count	= var.consul_cluster_size
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit_server" {
  name           = "commoninit-server-${count.index}.iso"
  user_data      = data.template_file.user_data_server[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.consul.name
  count          = var.consul_cluster_size
}

resource "libvirt_domain" "consul_server" {
  name = "${var.consul_datacenter}-server-consul-${count.index}"
  count = var.consul_cluster_size

  cloudinit = libvirt_cloudinit_disk.commoninit_server[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_server.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}

}

output "servers" {
  value = libvirt_domain.consul_server.*.name
}

output "server_ips" {
  value = libvirt_domain.consul_server.*.network_interface.0.addresses
}
