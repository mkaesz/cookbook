job "sleep" {
  datacenters = ["dc1"]
  type        = "service"
  priority    = 40
  namespace = "default"

  task "sleep" {
    driver = "exec"

    config {
      command = "/bin/sleep"
      args    = ["60"]
    }
  }
}

