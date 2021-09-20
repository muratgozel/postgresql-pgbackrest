#!/usr/bin/env bash

usermod -u $PGUSER_UID $PGUSER
groupmod -g $PGUSER_GID $PGUSER

pgconf="$PGDATA/postgresql.conf"
hbaconf="$PGDATA/pg_hba.conf"

# create db cluster if it's not exist
if [[ ! -f $PGDATA/PG_VERSION ]]; then
  initdb --encoding=UTF8 --locale=C -D $PGDATA

  echo "listen_addresses = '*'" >> $pgconf
  echo "port = $PGPORT" >> $pgconf
  echo "max_connections = 100" >> $pgconf
  echo "unix_socket_directories = '/var/run/postgresql'" >> $pgconf
  echo "shared_buffers = 128MB" >> $pgconf

  echo "host all all all trust" >> $hbaconf
fi

# init pgbackrest
if ! grep -q "pgbackrest" "$pgconf"; then
  pg_ctl start -o "-p $PGPORT -k /var/run/postgresql" -D $PGDATA

  echo "wal_level = replica" >> $pgconf
  echo "max_wal_size = 1GB" >> $pgconf
  echo "min_wal_size = 80MB" >> $pgconf
  echo "archive_mode = on" >> $pgconf
  echo "archive_command = 'pgbackrest --stanza=app archive-push %p'" >> $pgconf
  echo "max_wal_senders = 3" >> $pgconf
  echo "log_line_prefix = ''" >> $pgconf
  echo "log_timezone = 'Etc/UTC'" >> $pgconf

  pgbackrest --stanza=app --pg1-port=$PGPORT --log-level-console=info stanza-create
  pg_ctl restart -o "-p $PGPORT -k /var/run/postgresql" -D $PGDATA

  pgbackrest --stanza=app --pg1-port=$PGPORT --log-level-console=info check
  pgbackrest_check_result=$?

  if [ $pgbackrest_check_result -ne 0 ]; then
    echo "pgbackrest check failed."
    exit $pgbackrest_check_result
  fi

  pg_ctl stop -o "-p $PGPORT -k /var/run/postgresql" -D $PGDATA
fi

# start postgresql server
exec "$@"
