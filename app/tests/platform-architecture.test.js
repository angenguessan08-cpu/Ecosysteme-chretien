const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const migration = fs.readFileSync(path.join(__dirname, '../../database/migrations/001_platform_core.sql'), 'utf8');
const docs = fs.readFileSync(path.join(__dirname, '../../docs/ARCHITECTURE_CIBLE_V1.md'), 'utf8');

test('le socle central est additif et ne remplace pas les tables V7.x', () => {
  assert.match(migration, /MIGRATION ADDITIVE/i);
  assert.doesNotMatch(migration, /drop\s+table/i);
});

test('toutes les tables centrales activent RLS', () => {
  const tables = ['platform_profiles','platform_roles','platform_user_roles','churches','church_memberships','content_items','content_versions','content_reviews','content_reports','platform_audit_log'];
  for (const table of tables) assert.match(migration, new RegExp(`alter table public\\.${table} enable row level security`, 'i'), `${table} doit activer RLS`);
});

test('aucune politique permissive globale ni accès anon n’est introduit', () => {
  assert.doesNotMatch(migration, /using\s*\(\s*true\s*\)\s*with\s*check\s*\(\s*true\s*\)/i);
  assert.match(migration, /from anon/i);
});

test('la taxonomie d’âge reste explicitement non imposée', () => {
  assert.match(migration, /age_group_code text,\s*-- reference versionnee a definir/i);
  assert.match(docs, /0–7 \/ 8–100/);
});

test('les contenus sont versionnés et soumis à publication centrale', () => {
  assert.match(migration, /create table if not exists public\.content_versions/i);
  assert.match(migration, /status='PUBLISHED'/i);
  assert.match(migration, /content_reviews/i);
});

test('la migration ne stocke pas de mot de passe applicatif', () => {
  assert.doesNotMatch(migration, /password_hash|password\s+text/i);
  assert.match(migration, /references auth\.users\(id\)/i);
});
