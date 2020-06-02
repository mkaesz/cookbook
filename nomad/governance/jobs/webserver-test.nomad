job "webserver-test" {
  datacenters = ["dc1"]
  type        = "service"
  priority    = 40
  namespace = "qa"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "webserver" {
    count = 2

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - web - #
    task "webserver" {
      driver = "docker"

      config {
        # "httpd" is not an allowed image
        image = "httpd"
        port_map = {
          http = 80
        }
      }

      service {
        name = "webserver-test"
        tags = ["test", "webserver", "qa"]
        port = "http"
      }

      resources {
        cpu = 250 # Mhz
        memory = 512 # MB
        network {
          mbits = 10
          port "http" {}
        }
      }
    } # - end task - #
  } # - end group - #
}

