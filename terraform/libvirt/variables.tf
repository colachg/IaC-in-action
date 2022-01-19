variable "libvirt" {
  description = "libvirtd address"
  default     = "192.168.1.2:22"
}

variable "ubuntu_20_img_url" {
  description = "ubuntu 20.04 image"
  default     = "https://mirrors.ustc.edu.cn/ubuntu-cloud-images/focal/current/focal-server-cloudimg-amd64-disk-kvm.img"
}

variable "vm_hostname" {
  description = "vm hostname"
  default     = "terraform-kvm"
}


variable "counts" {
  description = "count of instances"
  default     = "2"
}
