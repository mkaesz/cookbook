# Access a key in Consul
data "consul_keys" "app" {
  key {
    name    = "ami"
    path    = "service/app/launch_ami"
    default = "ami-1234"
  }
}
