CREATE USER "{{name}}" WITH ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
ALTER USER "{{name}}" WITH SUPERUSER;

