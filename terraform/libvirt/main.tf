provider "libvirt" {
  uri = "qemu+ssh://root@${var.libvirt}/system?keyfile=$HOME/.ssh/id_rsa&sshauth=privkey"
}

#resource "libvirt_pool" "ubuntu" {
#  name = "data"
#  type = "dir"
#  path = "/data"
#}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "volume" {
  name   = "volume-${count.index}"
  pool   = "data"
  source = var.ubuntu_20_img_url
  format = "qcow2"
  count  = var.counts
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "data"
}

# Create the machine
resource "libvirt_domain" "ubuntu" {
  count  = var.counts
  name   = "ubuntu-${count.index}"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}


output "ip" {
  value = libvirt_domain.ubuntu.*.network_interface.0.addresses
  # value = libvirt_domain.domain-ubuntu.network_interface[0]
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
