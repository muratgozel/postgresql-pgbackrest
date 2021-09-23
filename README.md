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
    image: ghcr.io/muratgozel/postgresql-pgbackrest:latest
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
If you want store pgbackrest backups on the host machine add a volume:
```yml
- 'pgbackrest_data:/var/lib/pgbackrest'
```

Create a volume under data directory and execute some sql scripts inside of it.
```sh
docker exec postgres01 su-exec postgres psql -h 127.0.0.1 -U postgres -d [DBNAME] -f /data/schema.sql
```

---

Version management of this repository done by [releaser](https://github.com/muratgozel/node-releaser) 🚀
