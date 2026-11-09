-- Isy — inicialización de PostgreSQL
-- Una sola instancia (un volumen), pero UNA BASE DE DATOS POR MICROSERVICIO
-- para aislamiento lógico. Sin FK entre bases de servicios distintos.
--
-- Se ejecuta automáticamente la primera vez que arranca el contenedor
-- (docker-entrypoint-initdb.d). Si cambias esto, recrea el volumen pgdata.

CREATE DATABASE identity;
CREATE DATABASE ministores;
CREATE DATABASE media;

-- (Futuro / prod) Roles por servicio con mínimo privilegio, por ejemplo:
--   CREATE ROLE identity_user LOGIN PASSWORD '...';
--   GRANT ALL PRIVILEGES ON DATABASE identity TO identity_user;
--   CREATE ROLE ministores_user LOGIN PASSWORD '...';
--   GRANT ALL PRIVILEGES ON DATABASE ministores TO ministores_user;
