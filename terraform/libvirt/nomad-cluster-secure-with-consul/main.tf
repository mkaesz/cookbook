provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_pool" "nomad" {
  name = "nomad"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-nomad"
}
resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

resource "libvirt_volume" "volume_nomad_server" {
  name           = "volume-nomad-server-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.nomad_cluster_size
}

resource "libvirt_volume" "volume_nomad_worker" {
  name           = "volume-nomad-worker-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.nomad_workers
}

data "template_file" "nomad_server_config" {
  template = "${file("${path.module}/templates/nomad-server.hcl.tpl")}"
  vars = {
    cluster_size = var.nomad_cluster_size
  }
  count = var.nomad_cluster_size
}

data "template_file" "nomad_server_consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "nomad-server-${count.index}"
  }
  count = var.nomad_cluster_size
}

data "template_file" "nomad_client_consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "nomad-worker-${count.index}"
  }
  count = var.nomad_workers
}

data "template_file" "nomad_client_config" {
  template = "${file("${path.module}/templates/nomad-client.hcl.tpl")}"
  count = var.nomad_workers
}

data "template_file" "user_data_nomad_server" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "nomad-server-${count.index}"
    nomad_file_name = "nomad-server.hcl"
    nomad_config = base64encode(data.template_file.nomad_server_config[count.index].rendered)
    consul_client_config = base64encode(data.template_file.nomad_server_consul_client_config[count.index].rendered)
    ca_cert = base64encode(file("${path.module}/consul-ca.pem"))
  }
  count	= var.nomad_cluster_size
}

data "template_file" "user_data_nomad_client" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "nomad-worker-${count.index}"
    nomad_file_name = "nomad-worker.hcl"
    nomad_config = base64encode(data.template_file.nomad_client_config[count.index].rendered)
    consul_client_config = base64encode(data.template_file.nomad_client_consul_client_config[count.index].rendered)
    ca_cert = base64encode(file("${path.module}/consul-ca.pem"))
  }
  count	= var.nomad_workers
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit_nomad_server" {
  name           = "commoninit-nomad-server-${count.index}.iso"
  user_data      = data.template_file.user_data_nomad_server[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.nomad.name
  count          = var.nomad_cluster_size
}

resource "libvirt_cloudinit_disk" "commoninit_nomad_worker" {
  name           = "commoninit-nomad-worker-${count.index}.iso"
  user_data      = data.template_file.user_data_nomad_client[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.nomad.name
  count          = var.nomad_workers
}

resource "libvirt_domain" "nomad_server" {
  name = "nomad-server-${count.index}"
  count = var.nomad_cluster_size

  cloudinit = libvirt_cloudinit_disk.commoninit_nomad_server[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_nomad_server.*.id, count.index)
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

resource "libvirt_domain" "nomad_worker" {
  name = "nomad-worker-${count.index}"
  count = var.nomad_workers

  cloudinit = libvirt_cloudinit_disk.commoninit_nomad_worker[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_nomad_worker.*.id, count.index)
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

output "nomad-servers" {
  value = libvirt_domain.nomad_server.*.name
}

output "nomad-server-ips" {
  value = libvirt_domain.nomad_server.*.network_interface.0.addresses
}

output "nomad-workers" {
  value = libvirt_domain.nomad_worker.*.name
}

output "nomad-workers-ips" {
  value = libvirt_domain.nomad_worker.*.network_interface.0.addresses
}
