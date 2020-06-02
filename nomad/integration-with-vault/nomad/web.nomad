job "web" {
  datacenters = ["instruqt"]

  group "demo" {

    task "server" {
      driver = "docker"

      affinity {
        attribute = "${node.unique.name}"
        value     = "hashistack-client-1"
        weight    = 100
      }

      vault {
        policies = ["access-tables"]
      }

      config {
        image = "pgryzan/demo-web:latest"
        port_map {
          http = 3000
        }
      }

      template {
        data = <<EOT
{{ with service "database" }}
{{ with index . 0 }}
  DB_HOST="{{ .Address }}"
  DB_PORT="{{ .Port }}"
{{ end }}
{{ end }}
{{ with secret "database/creds/accessdb" }}
  DB_USERNAME="{{ .Data.username }}"
  DB_PASSWORD="{{ .Data.password }}"
{{ end }}
        EOT
        destination = "secrets/file.env"
        env         = true
      }

      resources {
        network {
          port "http" {
            static = 3000
          }
        }
      }

      service {
        name = "web"
        port = "http"
        tags = [
          "urlprefix-/",
        ]
        check {
          type     = "tcp"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}

