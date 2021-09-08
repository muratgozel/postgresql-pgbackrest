# postgresql-pgbackrest
A docker file that installs postgresql along with pgbackrest. Image size is ~340MB

## Usage
A pgbackrest.conf file is required as you can find a sample of it inside the pgbackrest directory. Refer to the [pgbackrest documentation](https://pgbackrest.org/configuration.html) for configuration options.

This is a docker image and available on docker hub. Just pull it. Sample docker-compose file:
```yaml
version: "3.9"

networks:
  testnet:
    driver: bridge

volumes:
  pgbackrest_logs:
  postgresql_data:

services:
  postgresql:
    container_name: postgres01
    image: muratgozel/postgresql-pgbackrest:latest
    build:
      context: ./postgresql
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - './somedir/pgbackrest:/etc/pgbackrest'
      - 'pgbackrest_logs:/var/log/pgbackrest'
      - 'postgresql_data:/usr/local/pgsql/data'
    networks:
      - testnet
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
```
