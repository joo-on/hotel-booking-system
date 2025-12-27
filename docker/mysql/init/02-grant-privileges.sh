#!/bin/sh
set -e

if [ -n "${MYSQL_USER:-}" ] && [ -n "${MYSQL_PASSWORD:-}" ]; then
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
GRANT ALL PRIVILEGES ON property.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ari.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON booking.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON payment.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON coupon.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON membership.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON search.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
fi
