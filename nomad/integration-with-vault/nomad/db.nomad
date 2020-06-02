job "database" {
  datacenters = ["instruqt"]

  group "db" {
    task "server" {
      driver = "docker"

      config {
        image = "pgryzan/demo-db:latest"
        port_map {
          db = 5432
        }
      }

      resources {
        network {
          port "db" {
            static = 5432
          }
        }
      }

      service {
        name = "database"
        port = "db"

        check {
          type     = "tcp"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}

