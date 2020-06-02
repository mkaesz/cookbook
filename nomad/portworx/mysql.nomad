job "mysql-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "mysql-server" {
    count = 1

    task "mysql-server" {
      driver = "docker"

      env = {
        "MYSQL_ROOT_PASSWORD" = "password"
      }

      config {
        image = "rberlind/mysql-demo:latest"

        port_map {
          db = 3306
        }

        volumes = [
          "mysql:/var/lib/mysql",
        ]

        volume_driver = "pxd"
      }

      resources {
        cpu    = 500
        memory = 1024

        network {
          port "db" {
            static = 3306
          }
        }
      }

      service {
        name = "mysql-server"
        port = "db"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
