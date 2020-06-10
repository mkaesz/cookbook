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

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  pool           = libvirt_pool.fedora.name
}

resource "libvirt_domain" "domain" {
  name = "domain"

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }
}

output "ips" {
  value = libvirt_domain.domain.network_interface.0.addresses
}
