# Database migrations

Version 1 is the Stage 1 foundation contained in `../001_schema.sql`.

Future updates will add monotonic migration files here, e.g.:

- `0002_progression.sql`
- `0003_qualifications.sql`

Every migration must insert its version/name into `himo_schema_migrations` only after its schema changes succeed.
