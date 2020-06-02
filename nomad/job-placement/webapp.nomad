job "webapp" {
  datacenters = ["dc1"]

  group "webapp" {
    count = 6

    task "server" {
      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }

      driver = "docker"

      config {
        image = "hashicorp/demo-webapp-lb-guide"
      }

      resources {
        cpu    = 20
        memory = 678

        network {
          mbits = 10
          port  "http"{}
        }
      }

      service {
        name = "webapp"
        port = "http"

        tags = [
          "traefik.tags=service",
          "traefik.frontend.rule=PathPrefixStrip:/myapp",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}

