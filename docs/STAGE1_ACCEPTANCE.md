# Stage 1 acceptance checklist

Stage 1 is considered complete only when all of these pass on a clean test server:

- [ ] txAdmin accepts the hosted `recipe.yaml`.
- [ ] txAdmin downloads the Cfx resources, oxmysql and HimotheeCore.
- [ ] txAdmin creates/connects the selected MySQL/MariaDB database.
- [ ] `001_schema.sql` and `002_seed.sql` complete without error.
- [ ] `server.cfg` contains the txAdmin-generated endpoints, license key and DB connection string.
- [ ] `oxmysql` starts before `himo_core`.
- [ ] `himo_core` logs `Database ready. Schema version 1.`.
- [ ] A player can connect and gets one `himo_accounts` record.
- [ ] Reconnecting with the same license reuses the same account.
- [ ] `/himocreate` creates a character, metadata, cash, bank and unemployed job.
- [ ] `/himoload` only loads characters owned by the connected account.
- [ ] Character load populates replicated state keys.
- [ ] Disconnect/reconnect leaves persistent database data intact.
- [ ] Money removal cannot make a balance negative.
- [ ] Audit records are written for character creation/load/drop.
- [ ] A database with schema version below 1 is rejected by the core health check.
