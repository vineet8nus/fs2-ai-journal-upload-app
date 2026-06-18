const cds = require('@sap/cds');

/**
 * PoC persistence bootstrap. There is no HANA entitlement in this subaccount,
 * so we run on a file-based SQLite inside the (ephemeral) app container. Unlike
 * the dev profile, the production runtime does NOT auto-create tables, so we
 * deploy the schema + CSV seed data once at startup.
 *
 * Swap `db` to HANA HDI when entitlement is available and this hook becomes a no-op.
 */
cds.once('served', async () => {
  const db = cds.requires?.db;
  if (db?.kind !== 'sqlite') return;
  const log = cds.log('bootstrap');
  try {
    await cds.deploy(cds.model).to(cds.db);
    log.info('schema + seed data deployed to sqlite', db.credentials?.url);
  } catch (e) {
    log.error('startup auto-deploy failed:', e.message);
  }
});

module.exports = cds.server;
