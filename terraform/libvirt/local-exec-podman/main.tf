provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_pool" "fedora" {
  name = "fedora"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-fedora"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-cloudinit.raw"
}

resource "libvirt_volume" "volume" {
  name           = "volume"
  base_volume_id = libvirt_volume.os_image.id
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "domain"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.fedora.name
}

resource "libvirt_domain" "domain" {
  name = "hostname"

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${libvirt_domain.domain.name} '{"host":"${libvirt_domain.domain.network_interface.0.addresses.0}","ttl":60}'
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

output "ips" {
  value = libvirt_domain.domain.network_interface.0.addresses
}
