PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE}")" ; cd .. > /dev/null 2>&1 && pwd -P)"

if [ ! -e $PROJECT_DIR/config/database.yml ]; then
  ln -s $PROJECT_DIR/config/database_dev.yml $PROJECT_DIR/config/database.yml
fi

export RAILS_ENV=${RAILS_ENV:-test}
DBCONFIG=$(bundle exec rails runner "print(ActiveRecord::Base.configurations[Rails.env].to_json)")
PGDATABASE=$(echo "$DBCONFIG" | jq -r .database)
PGPORT=$(echo $DBCONFIG | jq -r .port)
PGUSER=$(echo $DBCONFIG | jq -r .username)
PGPASSWORD=$(echo $DBCONFIG | jq -r .password)
J=$(ruby -e "require 'etc'; print((Etc.nprocessors/2.0).ceil) & STDOUT.flush")
echo "PGDATABASE=$PGDATABASE"
echo "PGPORT=$PGPORT"
echo "PGUSER=$PGUSER"
echo "PGPASSWORD=$PGPASSWORD"
echo "J=$J"


function terminate_connections {
psql -d template1  <<SQL
  SELECT pg_terminate_backend(pg_stat_activity.pid) 
    FROM pg_stat_activity 
    WHERE pg_stat_activity.datname = '$PGDATABASE' 
      AND pid <> pg_backend_pid();
SQL
}

function set_dev_and_debug_values {
psql -d $PGDATABASE << 'SQL'

  INSERT INTO people (first_name, last_name, subtype) VALUES ('root', 'localhost', 'Person') ON CONFLICT DO NOTHING;

  INSERT INTO users (email, person_id) 
    SELECT  'root@localhost', people.id
    FROM people WHERE first_name = 'root' AND last_name = 'localhost'
    ON CONFLICT DO NOTHING;

  INSERT INTO admins (user_id) 
    SELECT users.id FROM users 
    WHERE users.email = 'root@localhost'
    ON CONFLICT DO NOTHING;

  UPDATE users 
    SET 
      is_deactivated = false,
      login = 'admin_localhost',
      password_digest = '$2a$12$7m8yn13DwAz13YG8Pseyq.rSNl5GYrv0RoZG2dc42LXZYRbz.r5IK'
    WHERE email = 'root@localhost';

SQL
echo '# The database has been adjusted for debugging and development'
echo "# you can sign in as 'root@localhost' with the password 'secret' "
}

# vi: ft=sh
