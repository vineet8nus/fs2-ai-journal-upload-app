const cds = require('@sap/cds');

/**
 * PoC persistence note. There is no HANA entitlement in this subaccount, so we
 * run on a file-based SQLite inside the (ephemeral) app container. The schema
 * (incl. draft tables) and CSV seed data are pre-deployed into `db.sqlite` at
 * BUILD time (see mta.yaml before-all: `cds deploy --to sqlite:gen/srv/db.sqlite`),
 * because the production runtime does not auto-create tables.
 *
 * Swap `db` to HANA HDI when entitlement is available; this file can then go.
 */
cds.once('served', async () => {
  if (cds.requires?.db?.kind !== 'sqlite') return;
  const log = cds.log('bootstrap');
  try {
    const n = await cds.db.run(SELECT.one`count(*) as n`.from('journal.upload.GuidanceDocs'));
    log.info('sqlite ready — GuidanceDocs seed rows:', n && n.n);
  } catch (e) {
    log.error('sqlite not seeded (expected pre-deployed db.sqlite):', e.message);
  }
});

module.exports = cds.server;
