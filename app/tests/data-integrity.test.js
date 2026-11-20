const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const context = { window: {} };
const source = fs.readFileSync(path.join(__dirname, '..', 'data.js'), 'utf8');
vm.runInNewContext(source, context, { filename: 'data.js' });
const DATA = context.window.DATA;
const collections = ['p1', 'p2', 'p3', 'p4', 'p5'];

test('les cinq espaces et leurs tableaux sont présents', () => {
  assert.deepEqual(Object.keys(DATA.spaces).sort(), ['P1', 'P2', 'P3', 'P4', 'P5']);
  for (const key of collections) assert.ok(Array.isArray(DATA[key]), `${key} doit être un tableau`);
});

test('inventaire de référence V7.1 : 532 ressources', () => {
  const counts = Object.fromEntries(collections.map(k => [k, DATA[k].length]));
  assert.deepEqual(counts, { p1: 42, p2: 383, p3: 31, p4: 10, p5: 66 });
  assert.equal(collections.reduce((sum, k) => sum + DATA[k].length, 0), 532);
});

test('les identifiants des ressources sont uniques entre les cinq espaces', () => {
  const ids = collections.flatMap(k => DATA[k].map(item => item.id));
  assert.equal(ids.length, new Set(ids).size, 'un identifiant est dupliqué');
  assert.ok(ids.every(id => typeof id === 'string' && id.length > 0));
});

test('les tranches d’âge sont continues de 8 à 100 ans', () => {
  const groups = [...DATA.ageGroups].sort((a, b) => a.min - b.min);
  assert.equal(groups[0].min, 8);
  assert.equal(groups.at(-1).max, 100);
  for (let i = 1; i < groups.length; i++) {
    assert.equal(groups[i - 1].max + 1, groups[i].min, 'trou ou chevauchement entre tranches');
  }
});

test('les références d’âge des ressources P1 existent', () => {
  const valid = new Set(DATA.ageGroups.map(group => group.code));
  for (const item of DATA.p1) {
    for (const age of item.ages || []) assert.ok(valid.has(age), `${item.id}: tranche inconnue ${age}`);
  }
});
