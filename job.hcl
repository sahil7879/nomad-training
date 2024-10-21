job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 3

    network {
      port "web" {
        to = 80
      }
    }

    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}