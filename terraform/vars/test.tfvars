vaultAddress = "http://localhost:8200"
vaultToken   = "test"

boundary = {
  config = {
    env = "test"

    docker = [
      {
        name = "rabbitmq"
        network = {
          subnet  = "172.19.1.32/28"
          ipRange = "172.19.1.32/28"
          gateway = "172.19.1.33"
        }
        imageName = "rabbitmq:4.1.2-management-alpine"
        networkAdvanced = [
          {
            name = "rabbitmq"
          }
        ]
        # env = [
        #   "RABBITMQ_DEFAULT_USER=dev",
        #   "RABBITMQ_DEFAULT_PASS=dev"
        # ]
      },
      {
        name = "nginx"
        network = {
          subnet  = "172.19.1.0/28"
          ipRange = "172.19.1.0/28"
          gateway = "172.19.1.1"
        }
        imageName = "nginx:1.27.5"
        networkAdvanced = [
          {
            name = "nginx"
          },
          {
            name = "rabbitmq"
          },
          {
            name = "vault-test"
          }
        ]
        mounts = [
          {
            source = "/vagrant/source/nginx/conf.d/default-test.conf"
            target = "/etc/nginx/conf.d/default.conf"
            type   = "bind"
          }
        ]
        ports = [
            {
            internal = "80"
            external = "8081"
            }
        ]
      },
    ]
  }
}
