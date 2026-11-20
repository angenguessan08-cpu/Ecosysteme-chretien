/* Écosystème Chrétien — Portail Biblique & Spirituel · application (vanilla JS, PWA) */
(function () {
'use strict';
const D = window.DATA, CFG = window.APP_CONFIG || {};
const $ = (s, r) => (r || document).querySelector(s);
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const norm = s => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
const store = {
  get(k, d) { try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch (e) { return d; } },
  set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); return true; } catch (e) { return false; } }
};
const K = { S: 'ec5_settings', P: 'ec5_progress', N: 'ec5_notes', C: 'ec5_cards', Y: 'ec5_sync', R: 'ec5_restore', E: 'ec5_people', A: 'ec5_news' };
// Mode administrateur : le bouton « Sync Local & Cloud » n'apparaît que sur l'appareil où l'on a ouvert l'app avec ?admin=1 (retrait : ?admin=0).
const ADMIN_KEY = 'ec5_admin';
try { const a = new URLSearchParams(location.search).get('admin'); if (a === '1') localStorage.setItem(ADMIN_KEY, '1'); else if (a === '0') localStorage.removeItem(ADMIN_KEY); } catch (e) { /* stockage indisponible */ }
const isAdmin = () => { try { return localStorage.getItem(ADMIN_KEY) === '1'; } catch (e) { return false; } };
const uid = () => (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : 'id-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 9);
const SPACES = ['P1', 'P4', 'P5', 'P2', 'P3'];
const isP = sp => sp === 'P2' || sp === 'P5';
const stripAge = t => String(t || '').replace(/\s*[(\[]\s*\d{1,3}\s*[–—-]\s*\d{1,3}\s*ans\s*[)\]]/gi, '').replace(/\s*·?\s*\b\d{1,3}\s*(?:à|–|-)\s*\d{1,3}\s*ans\b/gi, '').trim();
const SP = D.spaces;
const AGE = Object.fromEntries(D.ageGroups.map(a => [a.code, a.label]));
const TYPE_ICON = { THANKSGIVING: '🙌', REQUEST: '🙏', SPIRITUAL_WARFARE: '🛡️' };
const STATUSES = ['En cours', 'Exaucée', 'Archivée'];

/* ------------------------------------------------------------ state */
let S = Object.assign({ focus: { cat: '', ids: [] }, space: 'P1', view: 'home', text: 0, name: '', ver: 'full', tipsHidden: false, tipsTab: 'all', tipIdx: { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0 }, cycleStart: '', remSent: {} }, store.get(K.S, {}));
S.tab = Object.assign({ P1: 'lib', P2: 'lib', P3: 'lib', P4: 'lib', P5: 'lib' }, S.tab);
S.rem = Object.assign({ P1: {}, P2: {}, P3: {}, P4: {}, P5: {} }, S.rem);
['P1', 'P2', 'P3', 'P4', 'P5'].forEach(k => { S.rem[k] = Object.assign({ on: true, time: '07:00', day: 1 }, S.rem[k]); });
if (!['home', 'global'].includes(S.view)) S.view = 'space';
if (!SPACES.includes(S.space)) S.space = 'P1';
const PRDEF = () => ({ read: {}, quiz: {}, steps: {}, check: {}, prayed: {}, timer: {}, routine: {}, prog: {}, vids: {}, pdimp: {}, anim: {} });
let PR = Object.assign(PRDEF(), store.get(K.P, {}));
let NOTES = store.get(K.N, []);
let CARDS = store.get(K.C, []);
let PEOPLE = store.get(K.E, []);
const savePeople = () => store.set(K.E, PEOPLE);
let NEWS = store.get(K.A, []);
const saveNews = () => store.set(K.A, NEWS);
let SY = Object.assign({ url: CFG.SUPABASE_URL || '', key: CFG.SUPABASE_ANON_KEY || '', auth: null, last: 0 }, store.get(K.Y, {}));
if (CFG.SUPABASE_URL && !SY.url) SY.url = CFG.SUPABASE_URL;
if (CFG.SUPABASE_ANON_KEY && !SY.key) SY.key = CFG.SUPABASE_ANON_KEY;
const F = { P1: {}, P2: {}, P3: {}, P4: {}, P5: {} };
let shown = 24;
const saveS = () => store.set(K.S, S);
// Migration unique : afficher le nouvel accueil à la première ouverture de cette version.
if (!S.homeRouteMigrated) { S.view = 'home'; S.homeRouteMigrated = true; saveS(); }
const saveP = () => store.set(K.P, PR);
const saveN = () => { store.set(K.N, NOTES); updateSide(); };
const saveC = () => store.set(K.C, CARDS);
const saveY = () => store.set(K.Y, SY);

function toast(msg) {
  const el = document.createElement('div'); el.className = 'toast'; el.textContent = msg;
  $('#toasts').appendChild(el); setTimeout(() => el.remove(), 3200);
}
function getP(kind, id) { const e = PR[kind] && PR[kind][id]; return e ? e.v : undefined; }
function setP(kind, id, v) { (PR[kind] = PR[kind] || {})[id] = { v, t: Date.now() }; saveP(); touch(); updateSide(); }

/* ------------------------------------------------------------ data normalisation */
const P2GROUP_ORDER = ['CHILD', 'PARENT', 'MINISTER', 'GENERAL', 'BLESS', 'DELIV'];
const ITEMS = { P1: [], P2: [], P3: [], P4: [], P5: [] };
D.p1.forEach(r => ITEMS.P1.push({ id: r.id, sp: 'P1', grp: r.group, cat: r.cat, sub: r.sub, ex: r.ages || [], title: stripAge(r.title), ref: r.ref, raw: r }));
D.p2.forEach(r => {
  const cat = D.tax.cats[r.cat], sub = D.tax.subs[r.sub];
  ITEMS.P2.push({ id: r.id, sp: 'P2', gk: r.g, grp: D.p2groups[r.g].name, cat: cat.name, sub: sub ? sub.name : '', ex: [r.t], title: r.title || (sub ? sub.name : cat.name), ref: r.ref, raw: r, color: cat.color });
});
(D.p5 || []).forEach(r => {
  const cat = D.tax.cats[r.cat], sub = D.tax.subs[r.sub];
  ITEMS.P5.push({ id: r.id, sp: 'P5', gk: r.g, grp: D.p2groups[r.g].name, cat: cat.name, sub: sub ? sub.name : '', ex: [r.t], title: r.title || sub.name, ref: r.ref, raw: r, color: cat.color });
});
D.p3.forEach(r => ITEMS.P3.push({ id: r.id, sp: 'P3', grp: r.group, cat: r.cat, sub: r.sub, ex: [], title: stripAge(r.title), ref: r.ref, raw: r }));
(D.p4 || []).forEach(r => ITEMS.P4.push({ id: r.id, sp: 'P4', grp: r.group, cat: r.cat, sub: r.sub, ex: [], title: stripAge(r.title), ref: r.ref, raw: r }));
const ALLBYID = {};
Object.values(ITEMS).flat().forEach(i => ALLBYID[i.id] = i);
const PERSO = 'Mes fiches personnelles';
function cardItem(c) {
  return { id: c.id, sp: c.sp, grp: PERSO, cat: 'Fiches personnelles', sub: c.sub || '', ex: [], title: c.title, ref: '', custom: true,
    raw: { id: c.id, sp: c.sp, title: c.title, sections: [{ h: 'Contenu', t: c.text }] } };
}
function items(sp) {
  const own = CARDS.filter(c => c.sp === sp && !c.del).map(cardItem);
  const base = ITEMS[sp];
  own.forEach(o => { if (!ALLBYID[o.id]) ALLBYID[o.id] = o; else ALLBYID[o.id] = o; });
  return base.concat(own);
}
function hay(it) {
  if (it._h) return it._h;
  const r = it.raw; let t = [it.id, it.title, it.ref, it.cat, it.sub, it.grp];
  if (isP(it.sp)) t.push(r.o, r.k);
  else (r.sections || []).forEach(s => { t.push(s.t); if (s.table) t.push(s.table.flat().join(' ')); });
  return (it._h = norm(t.join(' ')));
}
const extraLabel = (sp, k) => D.p2types[k] ? D.p2types[k] : k;

/* ------------------------------------------------------------ personalisation */
const PH = /\{PRENOM\}|\[Mon Pr[ée]nom\]/gi;
// Ordre des lignes sous « Je prie pour » : Enfants → Prière Générale → Prière pour les Bénédictions, puis les autres registres.
const PCATS = {
  CHILD: { l: 'Enfants', one: 'Enfant', grp: 'CHILD' },
  GENERAL: { hid: true, l: 'Prière Générale', one: 'Prière générale', grp: 'GENERAL', cat: 'CAT_11', subs: ["L'Église et le Corps de Christ", 'La Nation et les autorités', 'Les temps actuels et le discernement prophétique', 'La paix sociale', 'Le réveil spirituel'] },
  BLESS: { hid: true, l: 'Prière pour les Bénédictions', one: 'Bénédiction', grp: 'BLESS', cat: 'CAT_12', subs: ["Finances et gestion de l'argent", 'Commerce, entreprises et affaires', 'Voyages et déplacements', 'Projets professionnels et études', 'Faveur et portes ouvertes'] },
  PARENT: { l: 'Parents', one: 'Parent', grp: 'PARENT' },
  MISSION: { l: 'Enfants missionnaires', one: 'Enfant missionnaire', grp: 'MINISTER' },
  AUTRE: { l: 'Autres personnes', one: 'Personne' }
};
const PKEYS = () => Object.keys(PCATS).filter(k => !PCATS[k].hid);
const peopleOf = cat => PEOPLE.filter(p => !p.del && (!cat || p.cat === cat));
const fullName = p => (p.first + ' ' + p.last).trim();
function joinNames(a) { return a.length < 2 ? (a[0] || '') : a.slice(0, -1).join(', ') + ' et ' + a[a.length - 1]; }
// Nom(s) injecté(s) dans toutes les prières : personnes cochées du groupe actif, sinon le prénom saisi.
function focusLabel() {
  const f = S.focus; if (f && f.cat) { const sel = peopleOf(f.cat).filter(p => (f.ids || []).includes(p.id)); if (sel.length) return joinNames(sel.map(p => p.first || p.last)); }
  return S.name.trim();
}
const ptxt = t => String(t).replace(PH, m => focusLabel() || m);
const phtml = t => esc(t).split(/(\{PRENOM\}|\[Mon Pr[ée]nom\])/i).map(p => /^(\{PRENOM\}|\[Mon Pr[ée]nom\])$/i.test(p) ? '<mark>' + esc(focusLabel() || p) + '</mark>' : p).join('');
const p2text = r => S.ver === 'kid' ? r.k : r.o;

/* ------------------------------------------------------------ illustrations (SVG, 100 % hors-ligne) */
const HERO_PHOTOS = Object.assign({ P1: '', P2: '', P3: '', P4: '', P5: '' }, CFG.IMAGES || {}); // URLs facultatives (ex. Unsplash) : si renseignées, elles remplacent l'illustration SVG, avec repli automatique.
function heroSVG(sp) {
  const rays = n => Array.from({ length: n }, (_, i) => { const a = (i / n) * Math.PI * 2; return `<line x1="${900 + Math.cos(a) * 90}" y1="${160 + Math.sin(a) * 90}" x2="${900 + Math.cos(a) * 190}" y2="${160 + Math.sin(a) * 190}" stroke="#fff" stroke-opacity=".28" stroke-width="5" stroke-linecap="round"/>`; }).join('');
  if (sp === 'P1') return `<svg viewBox="0 0 1200 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Lever de soleil sur des collines"><defs><linearGradient id="h1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#064E3B"/><stop offset=".55" stop-color="#10B981"/><stop offset="1" stop-color="#A7F3D0"/></linearGradient></defs><rect width="1200" height="400" fill="url(#h1)"/>${rays(18)}<circle cx="900" cy="160" r="70" fill="#FFE9B8"/><circle cx="900" cy="160" r="105" fill="#fff" fill-opacity=".18"/><path d="M0 300 C200 230 360 330 560 280 S900 230 1200 300 V400 H0Z" fill="#059669" fill-opacity=".75"/><path d="M0 340 C240 290 420 370 640 330 S1000 300 1200 350 V400 H0Z" fill="#064E3B"/><g fill="#fff" fill-opacity=".9"><path d="M1010 90c20-24 46-18 58-2-24-4-34 4-44 16 8-14 0-20-14-14z"/><path d="M1050 120c18-14 34-8 44 6-18-2-24 6-30 14 4-10-2-14-14-20z"/></g><g fill="#fff" fill-opacity=".55"><circle cx="140" cy="70" r="3"/><circle cx="260" cy="120" r="2.4"/><circle cx="420" cy="60" r="3"/><circle cx="560" cy="110" r="2"/></g></svg>`;
  if (sp === 'P2') return `<svg viewBox="0 0 1200 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Famille réunie en prière"><defs><linearGradient id="h2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#78350F"/><stop offset="1" stop-color="#F59E0B"/></linearGradient><radialGradient id="h2g"><stop offset="0" stop-color="#FFE7A8" stop-opacity=".9"/><stop offset="1" stop-color="#FFE7A8" stop-opacity="0"/></radialGradient></defs><rect width="1200" height="400" fill="url(#h2)"/><circle cx="880" cy="190" r="230" fill="url(#h2g)"/><path d="M880 150c-18-34-70-22-60 20 8 30 60 62 60 62s52-32 60-62c10-42-42-54-60-20z" fill="#FFE7A8" fill-opacity=".9" transform="translate(0 -40)"/><g fill="#3B1D07"><circle cx="760" cy="262" r="26"/><path d="M724 400c0-62 16-104 36-104s36 42 36 104z"/><circle cx="880" cy="258" r="26"/><path d="M844 400c0-66 16-108 36-108s36 42 36 108z"/><circle cx="830" cy="318" r="17"/><path d="M806 400c0-40 10-66 24-66s24 26 24 66z"/><circle cx="950" cy="326" r="15"/><path d="M928 400c0-36 10-60 22-60s22 24 22 60z"/><circle cx="1010" cy="290" r="22"/><path d="M978 400c0-54 14-90 32-90s32 36 32 90z"/></g><g fill="#fff" fill-opacity=".5"><circle cx="120" cy="80" r="3"/><circle cx="300" cy="140" r="2.5"/><circle cx="520" cy="70" r="3"/><circle cx="640" cy="130" r="2"/></g></svg>`;
  if (sp === 'P5') return `<svg viewBox="0 0 1200 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Bouclier de lumière et croix"><defs><linearGradient id="h5" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2E1065"/><stop offset="1" stop-color="#7C3AED"/></linearGradient></defs><rect width="1200" height="400" fill="url(#h5)"/>${rays(18)}<path d="M900 70 L1000 105 V190 C1000 250 950 285 900 305 C850 285 800 250 800 190 V105 Z" fill="#F5F3FF" fill-opacity=".92"/><path d="M900 125 V255 M855 175 H945" stroke="#6D28D9" stroke-width="16" stroke-linecap="round"/><g fill="#fff" fill-opacity=".4"><circle cx="150" cy="80" r="3"/><circle cx="330" cy="150" r="2.4"/><circle cx="520" cy="60" r="3"/></g></svg>`;
  if (sp === 'P4') return `<svg viewBox="0 0 1200 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Étoile de lumière au-dessus d'une jeunesse rassemblée"><defs><linearGradient id="h4" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0C4A6E"/><stop offset="1" stop-color="#0EA5E9"/></linearGradient></defs><rect width="1200" height="400" fill="url(#h4)"/>${rays(16)}<path d="M900 80 L925 140 L985 160 L925 180 L900 240 L875 180 L815 160 L875 140 Z" fill="#FFF7E0" fill-opacity=".9"/><g fill="#fff" fill-opacity=".22"><circle cx="260" cy="330" r="34"/><circle cx="340" cy="320" r="40"/><circle cx="430" cy="332" r="32"/><circle cx="520" cy="322" r="38"/></g></svg>`;
  return `<svg viewBox="0 0 1200 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Bible ouverte, lumière et alliance"><defs><linearGradient id="h3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1E1B4B"/><stop offset="1" stop-color="#4F46E5"/></linearGradient><radialGradient id="h3g"><stop offset="0" stop-color="#FFD98A" stop-opacity=".95"/><stop offset="1" stop-color="#FFD98A" stop-opacity="0"/></radialGradient></defs><rect width="1200" height="400" fill="url(#h3)"/><circle cx="880" cy="200" r="240" fill="url(#h3g)"/><path d="M880 180 L700 0 M880 180 L1060 0 M880 180 L880 0" stroke="#FFE8B5" stroke-opacity=".35" stroke-width="6"/><path d="M760 250 C820 225 860 235 880 258 C900 235 940 225 1000 250 V330 C940 308 900 315 880 338 C860 315 820 308 760 330Z" fill="#F7EBD4"/><path d="M880 258 V338" stroke="#B8862E" stroke-width="3"/><g stroke="#B8862E" stroke-width="2" opacity=".6"><path d="M785 262c28-8 52-6 80 6M785 282c28-8 52-6 80 6M785 302c28-8 52-6 80 6M895 268c28-12 52-14 80-6M895 288c28-12 52-14 80-6M895 308c28-12 52-14 80-6"/></g><g fill="none" stroke="#FFD98A" stroke-width="9"><circle cx="835" cy="150" r="34"/><circle cx="895" cy="150" r="34"/></g><g fill="#fff" fill-opacity=".5"><circle cx="150" cy="90" r="3"/><circle cx="330" cy="150" r="2.4"/><circle cx="520" cy="60" r="3"/></g></svg>`;
}
const PAL = { P1: ['#10B981', '#059669', '#34D399', '#0F766E', '#14B8A6'], P2: ['#F59E0B', '#D97706', '#FBBF24', '#EA580C', '#B45309'], P3: ['#4F46E5', '#6366F1', '#4338CA', '#7C3AED', '#3730A3'], P4: ['#0EA5E9', '#0284C7', '#38BDF8', '#0369A1', '#06B6D4'], P5: ['#7C3AED', '#6D28D9', '#8B5CF6', '#4C1D95', '#A78BFA'] };
function hash(s) { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return Math.abs(h); }
const SCENES = ["<g stroke=\"#fff\" stroke-opacity=\".22\" stroke-width=\"4\" stroke-linecap=\"round\"><path d=\"M300 100L360 40M300 100L390 90M300 100L380 150M300 100L240 40\"/></g><circle cx=\"300\" cy=\"100\" r=\"54\" fill=\"#fff\" fill-opacity=\".14\"/><path d=\"M300 62V138M268 92H332\" stroke=\"#fff\" stroke-opacity=\".92\" stroke-width=\"12\" stroke-linecap=\"round\"/><path d=\"M0 170C90 140 170 190 260 160S360 150 400 170V200H0Z\" fill=\"#000\" fill-opacity=\".22\"/>","<circle cx=\"290\" cy=\"96\" r=\"90\" fill=\"#fff\" fill-opacity=\".13\"/><path d=\"M214 118C252 100 280 104 296 122C312 104 340 100 378 118V168C340 152 312 156 296 172C280 156 252 152 214 168Z\" fill=\"#FFF6E0\" fill-opacity=\".95\"/><path d=\"M296 122V172\" stroke=\"#B8862E\" stroke-width=\"3\"/><g stroke=\"#B8862E\" stroke-opacity=\".5\" stroke-width=\"2\"><path d=\"M228 128c20-6 42-4 58 6M228 142c20-6 42-4 58 6M306 134c16-10 38-12 58-6M306 148c16-10 38-12 58-6\"/></g><path d=\"M290 30V90M250 44L276 92M330 44L304 92\" stroke=\"#FFE8B5\" stroke-opacity=\".5\" stroke-width=\"4\" stroke-linecap=\"round\"/>","<circle cx=\"300\" cy=\"90\" r=\"78\" fill=\"#fff\" fill-opacity=\".14\"/><circle cx=\"300\" cy=\"72\" r=\"20\" fill=\"#fff\" fill-opacity=\".92\"/><path d=\"M262 200C262 140 278 104 300 104S338 140 338 200Z\" fill=\"#fff\" fill-opacity=\".88\"/><path d=\"M286 128l14 18 14-18\" stroke=\"#000\" stroke-opacity=\".25\" stroke-width=\"4\" fill=\"none\"/><g fill=\"#fff\" fill-opacity=\".5\"><circle cx=\"60\" cy=\"40\" r=\"3\"/><circle cx=\"150\" cy=\"90\" r=\"2.4\"/><circle cx=\"90\" cy=\"140\" r=\"3\"/></g>","<circle cx=\"310\" cy=\"150\" r=\"56\" fill=\"#FFE9B8\" fill-opacity=\".95\"/><circle cx=\"310\" cy=\"150\" r=\"86\" fill=\"#fff\" fill-opacity=\".14\"/><path d=\"M200 70c26-26 60-18 74 4-26-6-40 4-52 16 10-18 0-26-22-20zM274 74c20-12 38-4 48 12-16-4-26 2-34 10 4-12-4-18-14-22z\" fill=\"#fff\" fill-opacity=\".95\"/><path d=\"M0 170C100 140 180 190 280 160S370 150 400 168V200H0Z\" fill=\"#000\" fill-opacity=\".28\"/>","<circle cx=\"300\" cy=\"100\" r=\"84\" fill=\"#fff\" fill-opacity=\".13\"/><path d=\"M300 36L356 58V108C356 142 330 164 300 176C270 164 244 142 244 108V58Z\" fill=\"#fff\" fill-opacity=\".9\"/><path d=\"M300 70V140M272 98H328\" stroke=\"#000\" stroke-opacity=\".35\" stroke-width=\"10\" stroke-linecap=\"round\"/>","<circle cx=\"290\" cy=\"90\" r=\"90\" fill=\"#FFD98A\" fill-opacity=\".18\"/><g fill=\"#fff\" fill-opacity=\".92\"><rect x=\"236\" y=\"112\" width=\"16\" height=\"64\" rx=\"4\"/><rect x=\"282\" y=\"92\" width=\"18\" height=\"84\" rx=\"4\"/><rect x=\"330\" y=\"120\" width=\"16\" height=\"56\" rx=\"4\"/></g><g fill=\"#FFC857\"><path d=\"M244 88c-9 11-9 20 0 24 9-4 9-13 0-24z\"/><path d=\"M291 66c-10 12-10 22 0 26 10-4 10-14 0-26z\"/><path d=\"M338 96c-9 11-9 20 0 24 9-4 9-13 0-24z\"/></g>"];
function cardArt(it, kick) {
  const base = it.color || PAL[it.sp][hash(it.cat) % 5];
  return `<div class="cimg" style="background:linear-gradient(135deg,${base},color-mix(in srgb,${base} 52%,#0B1220))"><svg viewBox="0 0 400 200" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Illustration">${SCENES[hash(it.cat) % SCENES.length]}</svg>${gB(it.sp)}${kick ? `<span class="ckick">${kick}</span>` : ''}</div>`;
}
/* ------------------------------------------------------------ filtering (cascade, jamais de catégorie vide) */
function match(it, f, upto) {
  const lv = ['grp', 'cat', 'sub', 'ex'];
  for (let i = 0; i < upto; i++) {
    const k = lv[i];
    if (!f[k]) continue;
    if (k === 'ex') { if (!it.ex.includes(f.ex)) return false; } else if (it[k] !== f[k]) return false;
  }
  if (f.q && !hay(it).includes(f.q)) return false;
  return true;
}
function counts(list, f, upto, key) {
  const m = new Map();
  list.forEach(it => { if (!match(it, f, upto)) return; (key === 'ex' ? it.ex : [it[key]]).forEach(v => { if (v) m.set(v, (m.get(v) || 0) + 1); }); });
  return m;
}
function sanitize(sp) {
  const f = F[sp], list = items(sp);
  ['grp', 'cat', 'sub', 'ex'].forEach((k, i) => { if (f[k] && !counts(list, f, i, k).has(f[k])) { f[k] = ''; for (let j = i + 1; j < 4; j++) f[['grp', 'cat', 'sub', 'ex'][j]] = ''; } });
}
function orderKeys(sp, k, m) {
  const keys = [...m.keys()];
  if (isP(sp) && k === 'grp') { const rank = n => P2GROUP_ORDER.findIndex(c => D.p2groups[c].name === n); keys.sort((a, b) => rank(a) - rank(b)); }
  if (k === 'ex' && sp === 'P1') keys.sort((a, b) => D.ageGroups.findIndex(x => x.code === a) - D.ageGroups.findIndex(x => x.code === b));
  if (k === 'ex' && isP(sp)) keys.sort((a, b) => Object.keys(D.p2types).indexOf(a) - Object.keys(D.p2types).indexOf(b));
  if (isP(sp) && (k === 'cat')) keys.sort((a, b) => parseInt(a) - parseInt(b));
  return keys;
}
function grpLabel(sp, g) {
  return g;
}

/* ------------------------------------------------------------ render shell */
const SP_COL = { P1: '#10B981', P2: '#F59E0B', P3: '#4F46E5', P4: '#0EA5E9', P5: '#7C3AED' };
const LOGO = '<svg width="34" height="34" viewBox="0 0 512 512" aria-hidden="true"><path d="M256 104 L292 220 L408 256 L292 292 L256 408 L220 292 L104 256 L220 220 Z" fill="#0B1220" stroke="#FFF7E0" stroke-width="8" stroke-linejoin="round"/><path d="M386 120v64M354 152h64" stroke="#FFF7E0" stroke-width="26" stroke-linecap="round"/><circle cx="168" cy="368" r="18" fill="#FFF7E0" stroke="#0B1220" stroke-width="7"/></svg>';
const TOTAL = Object.values(ITEMS).reduce((n, a) => n + a.length, 0);
const nice = s => { s = String(s || ''); return (s === s.toUpperCase() && /[A-ZÉÈÀ]{3}/.test(s)) ? s.charAt(0) + s.slice(1).toLowerCase().replace(/th[èe]me n°/, 'Thème n°').replace(/\bdieu\b/g, 'Dieu') : s; };
const gB = sp => S.view === 'global' ? `<span class="badge dark">${esc(SP[sp].short)}</span>` : '';
function storeHTML() { return '<span>Stockage local</span><span class="ok"><i></i>Prêt</span>'; }
function updateSide() {
  const np = $('#nb-people'); if (np) { const c = peopleOf().length; np.textContent = c; np.className = c ? 'warn' : ''; }
  const nb = $('#nb-notes'); if (nb) { const c = NOTES.filter(n => !n.del).length; nb.textContent = c; nb.className = c ? 'warn' : ''; }
}
function navHTML() {
  const nsp = SPACES.map(s => `<button class="nv" style="--c:${SP_COL[s]}" data-act="space" data-v="${s}" ${S.view === 'space' && S.space === s ? 'aria-current="true"' : ''}><i class="dot"></i><span>${esc(SP[s].name)}</span><em>${items(s).length}</em></button>`).join('');
  const nn = NOTES.filter(n => !n.del).length;
  return `<div class="brand"><div class="logo">${LOGO}</div><div><b>Écosystème Chrétien</b><small>Portail Biblique &amp; Spirituel</small></div></div>
  <button class="nv home-nav" data-act="home" ${S.view === 'home' ? 'aria-current="true"' : ''}><span>⌂ Accueil général</span></button>
  <div class="sec-t">Espaces</div>${nsp}
  <div class="sec-t">Programme &amp; médias</div>
  <button class="nv" data-act="prog"><span>Programme annuel d'activités</span></button>
  <button class="nv" data-act="videos"><span>Capsules vidéo de sensibilisation</span></button>
  <button class="nv" data-act="anim"><span>Poèmes, sketchs, slams &amp; jeux</span></button>
  <div class="sec-t">Outils &amp; personnel</div>
  <button class="nv" data-act="global" ${S.view === 'global' ? 'aria-current="true"' : ''}><span>Vue Globale Transversale</span></button>
  <button class="nv" data-act="actu"><span>Actualités &amp; Ressources du jour</span></button>
  <button class="nv" data-act="carnet"><span>Carnet personnel</span><em id="nb-notes" class="${nn ? 'warn' : ''}">${nn}</em></button>
  <button class="nv" data-act="registre"><span>Registre de prière</span><em id="nb-people" class="${peopleOf().length ? 'warn' : ''}">${peopleOf().length}</em></button>
  <button class="nv" data-act="guide"><span>Guide d'utilisation</span></button>
  <button class="nv" data-act="about"><span>À propos &amp; Contact</span></button>
  ${isAdmin() ? '<button class="nv" data-act="open-sync"><span>☁ Sync Local &amp; Cloud</span></button>' : ''}
  <div class="store" id="store">${storeHTML()}</div><div class="about"><b>Version 7.0</b> · Louis Segond 1910<br>Stockage local ; synchronisation cloud facultative · fonctionne hors-ligne</div>`;
}
function bottomHTML() {
  const b = (act, v, ic, l, cur) => `<button data-act="${act}" ${v ? `data-v="${v}"` : ''} ${cur ? 'aria-current="true"' : ''}><span class="ic">${ic}</span>${l}</button>`;
  const sp = S.view === 'space' ? S.space : '';
  // Cinq entrées maximum : les autres espaces restent accessibles dans le menu latéral.
  return b('home', '', '⌂', 'Accueil', S.view === 'home') +
    b('space', 'P1', '🌿', 'Promesse', sp === 'P1') +
    b('space', 'P2', '🏡', 'Famille', sp === 'P2') +
    b('global', '', '🧭', 'Vue globale', S.view === 'global') +
    b('carnet', '', '📓', 'Carnet', false);
}
const LIBNAME = { P1: 'Fiches & méditations', P2: 'Sujets de prière', P3: 'Thèmes', P4: 'Thèmes', P5: 'Sujets de prière' };
function crumbHTML() {
  if (S.view === 'home') return '<small>Accueil :</small> Écosystème Chrétien';
  if (S.view === 'global') return '<small>Module :</small> Outils · Vue Globale Transversale';
  return '<small>Module :</small> ' + esc(SP[S.space].name) + ' · ' + (S.tab[S.space] === 'prog' ? 'Programme &amp; rappels' : esc(LIBNAME[S.space]));
}
function setSpace(sp) { S.view = 'space'; S.space = sp; saveS(); shown = 24; render(); }
function render() {
  document.body.dataset.space = S.view === 'global' ? 'G' : S.view === 'home' ? 'H' : S.space;
  document.body.classList.remove('menu');
  $('#side').innerHTML = navHTML(); $('#bottom').innerHTML = bottomHTML();
  $('#crumb').innerHTML = crumbHTML();
  if (S.view === 'home') renderHome(); else if (S.view === 'global') renderGlobal(); else renderSpace();
}
function followHTML() {
  const S0 = CFG.SOCIAL || {}, names = { whatsapp: ['WhatsApp', '💬'], facebook: ['Facebook', '📘'], instagram: ['Instagram', '📸'], tiktok: ['TikTok', '🎵'], x: ['X', '✖'] };
  const links = Object.keys(names).filter(k => /^https:\/\//i.test(S0[k] || '')).map(k => `<a class="sharebtn" style="--c:${(SHARE_NETS.find(s => s.k === k) || {}).c || '#888'}" href="${esc(S0[k])}" target="_blank" rel="noopener noreferrer"><span>${names[k][1]}</span>${names[k][0]}</a>`);
  return links.length ? `<section class="home-section"><div class="home-section-head"><div><span class="home-eyebrow dark">COMMUNAUTÉ</span><h2>Suivez-nous</h2><p>Rejoignez-nous et partagez avec vos proches.</p></div></div><div class="sharegrid follow">${links.join('')}</div></section>` : '';
}
function renderHome() {
  const d = new Date();
  const dateLabel = d.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  const total = Object.values(ITEMS).reduce((n, a) => n + a.length, 0);
  const versePool = Object.values(ITEMS).flat().filter(it => it.ref && it.raw.sections && it.raw.sections.some(x => x.kind === 'verse' || /Texte biblique/i.test(x.h || '')));
  const verseItem = versePool.length ? versePool[Math.abs(dayIndex()) % versePool.length] : null;
  const verseSection = verseItem && verseItem.raw.sections.find(x => x.kind === 'verse' || /Texte biblique/i.test(x.h || ''));
  const verseText = verseSection ? String(verseSection.t || '').split('\n')[0] : 'Ta parole est une lampe à mes pieds, et une lumière sur mon sentier.';
  const verseRef = verseItem ? verseItem.ref : 'Psaume 119:105';
  const spaces = SPACES.map(sp => { const m = SP[sp], n = items(sp).length; return `<button class="home-space" data-act="space" data-v="${sp}" style="--space-color:${SP_COL[sp]}"><span class="home-space-dot"></span><span class="home-space-main"><b>${esc(m.name)}</b><small>${esc(m.tag || '')}</small></span><span class="home-space-count">${n}<small>ressources</small></span></button>`; }).join('');
  const latest = verseItem ? `<article class="home-feature"><div class="home-eyebrow">RESSOURCE À DÉCOUVRIR</div><h3>${esc(verseItem.title)}</h3><p>${esc(verseItem.ref)}</p><button class="btn amber" data-act="space" data-v="${verseItem.sp}">Explorer la ressource</button></article>` : '';
  $('#app').innerHTML = `<section class="home-hero"><div class="home-hero-copy"><span class="home-eyebrow">FOI · FAMILLE · VIE SPIRITUELLE</span><h1>Grandir dans la foi,<br>à chaque étape de la vie.</h1><p>Un espace commun pour découvrir la Bible, prier, apprendre et transmettre les valeurs chrétiennes.</p><div class="home-actions"><button class="btn amber" data-act="space" data-v="P1">Explorer les espaces</button><button class="btn home-outline" data-act="global">Vue transversale</button></div></div><div class="home-verse"><span>PAROLE DU JOUR · ${esc(dateLabel)}</span><blockquote>« ${esc(verseText.replace(/^«|»$/g, '').trim())} »</blockquote><b>${esc(verseRef)}</b></div></section>
  <section class="home-section"><div class="home-section-head"><div><span class="home-eyebrow dark">DÉCOUVRIR</span><h2>Les espaces de l'écosystème</h2><p>Des ressources organisées par grandes dimensions de la vie chrétienne.</p></div><span class="home-total">${total} ressources intégrées</span></div><div class="home-spaces">${spaces}</div></section>
  <section class="home-quick"><button class="home-quick-card" data-act="actu"><span>✦</span><b>Actualités & ressources</b><small>Informations et sujets de sensibilisation.</small></button><button class="home-quick-card" data-act="prog"><span>▦</span><b>Programmes & activités</b><small>Consulter les programmes de la plateforme.</small></button><button class="home-quick-card" data-act="anim"><span>♫</span><b>Créativité & jeux</b><small>Poèmes, sketchs, slams et jeux bibliques.</small></button><button class="home-quick-card" data-act="carnet"><span>▤</span><b>Mon espace personnel</b><small>Retrouver ses notes et son registre de prière.</small></button></section>
  ${latest}${followHTML()}<p class="home-disclaimer">Les ressources proposées accompagnent la lecture personnelle de la Bible. Elles ne remplacent ni l'accompagnement pastoral ni un avis professionnel lorsque celui-ci est nécessaire.</p>`;
}
function heroAside(sp, left) {
  const T = D.tips[sp]; if (!T) return '';
  const r = T.reco[dayIndex() % T.reco.length];
  return `<aside class="hero-aside" aria-label="Repère du jour"><small>⭐ Repère du jour</small><p>${esc(r)}</p><button class="btn amber sm" data-act="tab" data-v="prog">${left ? `🗓 ${left} action${left > 1 ? 's' : ''} du jour` : '🗓 Mon programme'}</button></aside>`;
}
function heroHTML() {
  const sp = S.space, m = SP[sp], list = items(sp);
  const done = list.filter(i => getP(isP(sp) ? 'prayed' : 'read', i.id)).length;
  const art = HERO_PHOTOS[sp] ? `<img src="${esc(HERO_PHOTOS[sp])}" alt="" loading="lazy" onerror="this.outerHTML=window.__hero('${sp}')">` : heroSVG(sp);
  const left = leftIn(sp, 'daily');
  return `<section class="hero" aria-label="${esc(m.name)}"><div class="art">${art}</div><div class="hero-body"><h2>${esc(m.name)}</h2><p>${esc(m.tag)}</p>
  <div class="stats"><div class="stat"><b>${list.length}</b>${isP(sp) ? 'sujets de prière' : sp === 'P3' || sp === 'P4' ? 'thèmes' : 'fiches'}</div><div class="stat"><b>${done}</b>${isP(sp) ? 'sujets priés' : 'fiches lues'}</div><div class="stat"><b>${left}</b>actions du jour restantes</div></div></div>${heroAside(sp, left)}</section>`;
}
window.__hero = heroSVG;
function barHTML() {
  const sp = S.space, T = D.tips[sp], i = S.tipIdx[sp] || 0;
  const cards = [
    ['e', '💡', 'Conseil pratique', T.advice, 'advice'], ['a', '⚠️', 'Point de Vigilance & Alerte', T.alert, 'alert'], ['i', '⭐', 'Recommandation', T.reco, 'reco']
  ].filter(c => S.tipsTab === 'all' || S.tipsTab === c[4]);
  const tab = (v, l) => `<button class="chip" data-act="tiptab" data-v="${v}" aria-pressed="${S.tipsTab === v}">${l}</button>`;
  return `<section class="bar" aria-label="Conseil pratique, point de vigilance et recommandation"><div class="bar-head"><h3>Conseils & repères</h3><div class="chips">${tab('all', 'Les 3')}${tab('advice', '💡')}${tab('alert', '⚠️')}${tab('reco', '⭐')}
  <button class="mini" data-act="tipnext">↻ Autre</button><button class="mini" data-act="tiptoggle" aria-expanded="${!S.tipsHidden}">${S.tipsHidden ? 'Afficher' : 'Masquer'}</button></div></div>
  ${S.tipsHidden ? '' : `<div class="cards3">${cards.map(([c, ic, t, arr, k]) => `<article class="tip ${c}"><span class="ico">${ic}</span><h4>${t}</h4><p>${esc(arr[i % arr.length])}</p><div class="row"><button class="mini" data-act="tipcopy" data-v="${k}">Copier</button><button class="mini" data-act="tipshare" data-v="${k}">Partager</button></div></article>`).join('')}</div>`}</section>`;
}
function subOptions(k, cur) { const c = PCATS[k]; return c && c.subs ? '<option value="">Toutes les sous-rubriques</option>' + c.subs.map(x => `<option value="${esc(x)}" ${x === cur ? 'selected' : ''}>${esc(x)}</option>`).join('') : ''; }
function p5toolsHTML() {
  const lab = focusLabel();
  return `<div class="panel p5tools"><label class="f" for="name-in">Prénom (remplace {PRENOM} dans les prières)</label>
  <div class="pq-row"><div><input type="text" id="name-in" maxlength="40" placeholder="Ex. : Grâce" value="${esc(S.name)}" autocomplete="off"></div><button class="btn ghost" data-act="registre">Mon registre (${peopleOf().length})</button><button class="btn ghost" data-act="pclear2">Effacer</button></div>
  <p class="hint">${lab ? `Toutes les prières mentionnent actuellement : <b>${esc(lab)}</b>.` : 'Aucun prénom actif : « {PRENOM} » reste affiché.'}</p></div>`;
}
function p2toolsHTML() {
  const n = peopleOf().length, lab = focusLabel(), diff = D.p2.filter(r => r.o !== r.k).length;
  return `<div class="panel p2tools p2people">
  <div class="pq"><label class="f" for="pq-name">Nom et prénoms</label>
  <textarea id="pq-name" rows="2" maxlength="600" placeholder="Ex. : KONÉ Grâce Marie  (une personne par ligne pour en ajouter plusieurs)" autocomplete="off"></textarea>
  <div class="pq-row"><div><label class="f" for="pq-cat">Je prie pour</label><select id="pq-cat">${PKEYS().map(k => `<option value="${k}" ${k === REG.cat ? 'selected' : ''}>${PCATS[k].l}</option>`).join('')}</select></div>
  <div id="pq-subbox" ${PCATS[REG.cat].subs ? '' : 'hidden'}><label class="f" for="pq-sub">Sous-rubrique</label><select id="pq-sub">${subOptions(REG.cat, REG.sub)}</select></div>
  <button class="btn" data-act="padd-quick">＋ Enregistrer</button><button class="btn ghost" data-act="pshow">Voir les sujets</button><button class="btn ghost" data-act="registre">Mon registre (${n})</button></div>
  <p class="hint">${lab ? `Toutes les prières mentionnent actuellement : <b>${esc(lab)}</b>. <button class="mini" data-act="pclear2">Effacer</button>` : `Les noms enregistrés remplacent « {PRENOM} » dans toutes les prières. Aucun nom actif pour le moment.`}</p></div>
  <div><label class="f">Formulation des prières</label><div class="seg" role="group" aria-label="Formulation des prières"><button data-act="ver" data-v="full" aria-pressed="${S.ver === 'full'}">Pour eux (« il / elle »)</button><button data-act="ver" data-v="kid" aria-pressed="${S.ver === 'kid'}">Moi-même (« je »)</button></div>
  <p class="hint">« Pour eux » : tu pries pour une personne. « Moi-même » : l'enfant prie à la 1ʳᵉ personne. Seuls ${diff} sujets sur ${D.p2.length} changent de texte ; les autres sont identiques.</p></div>
  <div class="pq-tools"><button class="btn" data-act="timer">⏱ 15 Min avec Dieu</button><button class="btn ghost" data-act="culte">🕯 Culte Familial du Jour</button></div></div>`;
}
function renderSpace() {
  const sp = S.space, tab = S.tab[sp] || 'lib', left = leftIn(sp, 'daily'); $('#crumb').innerHTML = crumbHTML();
  $('#app').innerHTML = heroHTML() +
    `<div class="tabs" role="tablist"><button role="tab" data-act="tab" data-v="lib" aria-selected="${tab === 'lib'}">📚 Bibliothèque<small>${items(sp).length}</small></button><button role="tab" data-act="tab" data-v="prog" aria-selected="${tab === 'prog'}">🗓 Programme &amp; rappels${left ? `<small>${left}</small>` : ''}</button></div>` +
    bannerHTML(sp) + (tab === 'lib' ? libHTML() : programHTML(sp));
  if (tab === 'lib') { renderFilters(); renderList(); }
}
function libHTML() {
  const sp = S.space;
  return barHTML() + (sp === 'P2' ? p2toolsHTML() : sp === 'P5' ? p5toolsHTML() : '') +
    `<div class="lib"><section><div class="toolbar"><div class="count" id="count"></div><div class="chips qf" id="qf" role="group" aria-label="Filtre rapide"></div><div class="chips"><div class="seg" role="group" aria-label="Affichage"><button data-act="lview" data-v="cards" aria-pressed="${S.lview !== 'tree'}">Cartes</button><button data-act="lview" data-v="tree" aria-pressed="${S.lview === 'tree'}">Hiérarchie</button></div><button class="btn ghost sm" data-act="newcard">＋ Ma fiche</button></div></div><div class="searchbar"><label class="sr" for="q-in">Rechercher</label><input type="search" id="q-in" placeholder="Rechercher un mot, un verset…" value="${esc(F[sp].qraw || '')}" autocomplete="off"></div><div class="dd" id="dd"></div><div class="actives" id="actives"></div><div class="grid" id="list"></div><div id="more"></div>${sp === 'P5' ? pdSectionHTML() : ''}</section></div>`;
}
function renderFilters() {
  const sp = S.space, f = F[sp], list = items(sp); sanitize(sp);
  const lv = [['grp', sp === 'P3' || sp === 'P4' ? 'Module' : 'Groupe'], ['cat', 'Catégorie'], ['sub', isP(sp) ? 'Sous-catégorie' : 'Sous-groupe'], ['ex', 'Type de prière']];
  let n = 0;
  lv.forEach(([k, lab], i) => {
    if (k === 'ex' && !isP(sp)) return;
    const m = counts(list, f, i, k); if (!m.size) return;
    if (f[k]) n++;
  });
  let dd = '';
  lv.forEach(([k, lab], i) => {
    if (k === 'ex' && !isP(sp)) return;
    const m = counts(list, f, i, k); if (!m.size) return;
    dd += `<label class="ddf"><span>${lab}</span><select data-k="${k}" aria-label="${lab}" title="${esc(f[k] ? (k === 'ex' ? extraLabel(sp, f[k]) : f[k]) : 'Tous')}"><option value="">Tous (${k === 'ex' ? list.filter(it => match(it, f, 3)).length : [...m.values()].reduce((a, b) => a + b, 0)})</option>` +
      orderKeys(sp, k, m).map(v => `<option value="${esc(v)}" title="${esc(k === 'ex' ? extraLabel(sp, v) : v)}" ${f[k] === v ? 'selected' : ''}>${esc(k === 'ex' ? extraLabel(sp, v) : k === 'grp' ? nice(grpLabel(sp, v)) : nice(v))} (${m.get(v)})</option>`).join('') + '</select></label>';
  });
  const ddEl = $('#dd'); if (ddEl) ddEl.innerHTML = dd;
  
  const pills = [];
  lv.forEach(([k]) => { if (f[k]) pills.push(`<button class="apill" data-act="f" data-k="${k}" data-v="" title="Retirer ce filtre"><span class="apl">${esc(k === 'ex' ? extraLabel(sp, f[k]) : k === 'grp' ? nice(grpLabel(sp, f[k])) : nice(f[k]))}</span><i>✕</i></button>`); });
  if (f.q) pills.push(`<button class="apill" data-act="clearq">« ${esc(f.qraw)} »<i>✕</i></button>`);
  if (pills.length > 1) pills.push('<button class="apill clear" data-act="reset">Tout effacer</button>');
  $('#actives').innerHTML = pills.join('');
}
const QF = {};
const qfKind = sp => isP(sp) ? 'prayed' : 'read';
function qfHTML(sp) {
  const k = qfKind(sp), all = items(sp), n = all.filter(i => getP(k, i.id)).length, cur = QF[sp] || 'all', pr = isP(sp);
  const b = (v, l, c) => `<button class="chip" data-act="qf" data-v="${v}" aria-pressed="${cur === v}">${l} <small>${c}</small></button>`;
  return b('all', 'Tout', all.length) + b('todo', pr ? 'Non priés' : 'Non lus', all.length - n) + b('done', pr ? 'Priés' : 'Lus', n);
}
function renderList() {
  const sp = S.space, f = F[sp], qk = qfKind(sp), qv = QF[sp] || 'all', list = items(sp).filter(it => match(it, f, 4) && (qv === 'all' || (qv === 'done') === !!getP(qk, it.id))), tree = S.lview === 'tree';
  const qb = $('#qf'); if (qb) qb.innerHTML = qfHTML(sp);
  $('#count').innerHTML = list.length + (list.length > 1 ? ' fiches' : ' fiche') + ` <small>sur ${items(sp).length}</small>`;
  const box = $('#list'); box.className = tree ? 'tree' : 'grid';
  if (tree) { box.innerHTML = list.length ? treeHTML(list, sp) : '<div class="empty">Aucune fiche ne correspond. Essaie d\'élargir les filtres.</div>'; $('#more').innerHTML = ''; return; }
  const page = list.slice(0, shown);
  box.innerHTML = page.length ? page.map(cardHTML).join('') : '<div class="empty" style="grid-column:1/-1">Aucune fiche ne correspond. Essaie d\'élargir les filtres.</div>';
  $('#more').innerHTML = list.length > shown ? `<button class="btn ghost more" data-act="more">Afficher plus (${list.length - shown} restantes)</button>` : '';
}
/* Vue hiérarchique : Groupe › Catégorie › Sous-catégorie › lignes de sujets (une ligne chacune) */
const pTxt = it => isP(it.sp) ? ptxt(p2text(it.raw)) : nice(it.title);
function treeHTML(list, sp) {
  const f = F[sp], filt = !!(f.q || f.grp || f.cat || f.sub), G = new Map();
  list.forEach(it => {
    if (!G.has(it.grp)) G.set(it.grp, new Map()); const C = G.get(it.grp);
    if (!C.has(it.cat)) C.set(it.cat, new Map()); const Sb = C.get(it.cat), sk = it.sub || '';
    if (!Sb.has(sk)) Sb.set(sk, []); Sb.get(sk).push(it);
  });
  const cnt = m => { let n = 0; m.forEach(v => { n += Array.isArray(v) ? v.length : cnt(v); }); return n; };
  const row = it => { const t = pTxt(it), k = isP(it.sp) ? 'prayed' : 'read', on = getP(k, it.id); return `<li class="trow"><button class="tl" data-act="open" data-id="${esc(it.id)}" title="${esc(t)}">${esc(t)}</button><span class="tacts"><button data-act="ccopy" data-id="${esc(it.id)}" title="Copier">Copier</button><button data-act="cpray" data-id="${esc(it.id)}" class="${on ? 'on' : ''}" title="${isP(it.sp) ? 'Marquer comme prié' : 'Marquer comme lu'}">${on ? '✓' : (isP(it.sp) ? 'Prié' : 'Lu')}</button></span></li>`; };
  return orderKeys(sp, 'grp', G).map(g => {
    const C = G.get(g), cats = orderKeys(sp, 'cat', C);
    return `<details class="tg" open><summary class="t1" title="${esc(nice(g))}"><span>${esc(nice(g))}</span><small>${cnt(C)}</small></summary>` + cats.map(c => {
      const Sb = C.get(c), nc = cnt(Sb);
      return `<details class="tc" ${filt || nc <= 40 || cats.length === 1 ? 'open' : ''}><summary class="t2" title="${esc(nice(c))}"><span>${esc(nice(c))}</span><small>${nc}</small></summary>` + [...Sb.keys()].map(sk => {
        const arr = Sb.get(sk); if (!sk) return `<ul class="trows">${arr.map(row).join('')}</ul>`;
        return `<details class="ts" ${filt || nc <= 24 ? 'open' : ''}><summary class="t3" title="${esc(sk)}"><span>${esc(sk)}</span><small>${arr.length}</small></summary><ul class="trows">${arr.map(row).join('')}</ul></details>`;
      }).join('') + '</details>';
    }).join('') + '</details>';
  }).join('');
}
function cardHTML(it) {
  const sp = it.sp, r = it.raw, p = isP(sp), id = esc(it.id), done = getP(p ? 'prayed' : 'read', it.id);
  const kick = esc(nice(String(it.cat).replace(/^\d+\.\s*/, '').replace(/^Cat[ée]gorie \d+\s*[:·]\s*/i, ''))) + (it.custom ? ' · PERSO' : '');
  const first = (r.sections && r.sections[r.sections.length > 1 ? 1 : 0] || { t: '' }).t || '';
  const text = p ? phtml(p2text(r)) : esc(first.replace(/\n/g, ' ').slice(0, 260));
  const title = p ? esc(it.title) : esc(nice(it.title));
  return `<article class="card pc${p ? ' p2' : ''}" data-act="open" data-id="${id}" tabindex="0" role="button" aria-label="${esc(it.title)}">${cardArt(it, kick)}<div class="body"><h3>${title}</h3><p class="ex">${text}</p>
  <div class="crow"><button class="cbtn pri" data-act="open" data-id="${id}">Lire</button><button class="cbtn" data-act="ccopy" data-id="${id}">Copier</button><button class="cbtn ${done ? 'on' : ''}" data-act="cpray" data-id="${id}">${done ? '✓ ' : ''}${p ? 'Prié' : 'Lu'}</button></div></div></article>`;
}

/* ------------------------------------------------------------ modal */
let onClose = null;
function openModal(html, close) {
  const m = $('#modal'); m.innerHTML = '<div class="sheet">' + html + '</div>'; m.classList.add('open'); m.scrollTop = 0; onClose = close || null;
  document.body.style.overflow = 'hidden';
}
function closeModal() {
  const m = $('#modal'); m.classList.remove('open'); m.innerHTML = ''; document.body.style.overflow = '';
  if (onClose) { const c = onClose; onClose = null; c(); }
}
const head = (title, tags, mod) => `<div class="sheet-head"><div><div class="modtag">Module : ${mod !== undefined ? mod : title}</div>${tags ? `<div class="chips">${tags}</div>` : ''}<h2>${title}</h2></div><button class="x" data-act="close" aria-label="Fermer">✕</button></div>`;

/* ------------------------------------------------------------ detail */
function lines(t) {
  return String(t || '').split('\n').filter(l => l.trim()).map(l => {
    const m = /^([^:«»]{2,70}) : ([\s\S]*)$/.exec(l);
    if (m) {
      const parts = m[2].split(' | ');
      return parts.length > 1 ? `<p><strong>${esc(m[1])} :</strong></p><ul>${parts.map(p => `<li>${esc(p)}</li>`).join('')}</ul>` : `<p><strong>${esc(m[1])} :</strong> ${esc(m[2])}</p>`;
    }
    return `<p>${esc(l)}</p>`;
  }).join('');
}
function sectionHTML(s) {
  let b;
  if (s.table) {
    const [hd, ...rows] = s.table;
    b = `<div class="tbl-wrap"><table class="cmp"><thead><tr>${hd.map(c => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${rows.map(r => `<tr>${r.map(c => `<td>${esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
  } else if (s.kind === 'verse') {
    const blocks = String(s.t).split('\n\n'), q = blocks[0].split('\n');
    const cite = q.length > 1 ? q.slice(1).join(' ') : '';
    b = `<blockquote class="verse" style="margin:8px 0">${esc(q[0])}${cite ? `<cite>${esc(cite)}</cite>` : ''}</blockquote>` + lines(blocks.slice(1).join('\n'));
  } else if (s.kind === 'prayer') b = `<div class="prayer">${esc(s.t)}</div>`;
  else b = lines(s.t);
  return `<section class="sec"><h3>${esc(s.h)}</h3>${b}</section>`;
}
function detailTips(it) {
  const r = it.raw, T = D.tips[it.sp];
  let a = r.advice, w = r.alert, c = r.reco;
  const h = hash(it.id);
  if (!a) { a = T.advice[h % T.advice.length]; w = T.alert[h % T.alert.length]; c = T.reco[h % T.reco.length]; }
  return `<div class="cards3" style="margin-top:16px"><article class="tip e in-detail"><span class="ico">💡</span><h4>Conseil pratique</h4><p>${esc(a)}</p></article><article class="tip a in-detail"><span class="ico">⚠️</span><h4>Point de Vigilance & Alerte</h4><p>${esc(w)}</p></article><article class="tip i in-detail"><span class="ico">⭐</span><h4>Recommandation</h4><p>${esc(c)}</p></article></div>`;
}
let CUR = null, QZ = null;
function openDetail(id) {
  const it = ALLBYID[id]; if (!it) return;
  CUR = it; QZ = null;
  const r = it.raw, sp = it.sp;
  const tags = `<span class="badge">${esc(SP[sp].name)}</span><span class="badge">${esc(grpLabel(sp, it.grp).replace(/^(GROUPE [A-C]|MODULE \d) · /, ''))}</span>`;
  let b = '';
  if (isP(sp)) {
    b = `<div class="chips" style="margin:6px 0"><span class="badge">${TYPE_ICON[r.t]} ${esc(D.p2types[r.t])}</span><span class="badge">${esc(it.cat)}</span>${it.sub ? `<span class="badge">${esc(it.sub)}</span>` : ''}${r.ref ? `<span class="badge">📖 ${esc(r.ref)}</span>` : ''}</div>
    <div class="seg" style="margin:8px 0" role="group"><button data-act="ver2" data-v="full" aria-pressed="${S.ver === 'full'}">Pour eux (« il / elle »)</button><button data-act="ver2" data-v="kid" aria-pressed="${S.ver === 'kid'}">Moi-même (« je »)</button></div>
    <div class="pray" id="pray">${phtml(p2text(r))}</div>
    ${r.o !== r.k ? '<p class="hint">Ce sujet a deux formulations : bascule entre « Pour eux » et « Moi-même » pour les voir.</p>' : '<p class="hint">Ce sujet est identique dans les deux formulations.</p>'}
    <div class="field" style="margin-top:10px"><label class="f" for="d-name">Prénom (si aucun nom actif dans le registre)</label><input type="text" id="d-name" value="${esc(S.name)}" placeholder="Prénom" maxlength="40"></div>
    <p class="hint">Source : ${esc(r.src)}</p>`;
  } else {
    b = (r.sections || []).map(sectionHTML).join('');
    if (r.quiz) b += '<section class="sec"><h3>Quiz interactif</h3><div id="quiz"></div></section>';
    if (r.steps) b += `<section class="sec"><h3>Mon défi · cases à cocher</h3><div id="steps"></div></section>`;
    if (r.calendar) b += `<section class="sec"><h3>Annexe · Calendrier d'actions</h3><div class="tbl-wrap"><table class="cmp"><thead><tr><th>Période</th><th>Action</th><th>Fiche</th></tr></thead><tbody>${r.calendar.map(c => `<tr><td>${esc(c[0])}</td><td>${esc(c[1])}</td><td>${esc(c[2])}</td></tr>`).join('')}</tbody></table></div></section>`;
    if (r.checklist) b += `<section class="sec"><h3>Ma check-list de transition d'année</h3><div id="check"></div></section>`;
    if (it.custom) b += `<div class="actions"><button class="btn ghost sm" data-act="editcard" data-id="${esc(it.id)}">Modifier</button><button class="btn danger sm" data-act="delcard" data-id="${esc(it.id)}">Supprimer</button></div>`;
  }
  b += detailTips(it);
  const readK = isP(sp) ? 'prayed' : 'read', on = getP(readK, it.id);
  b += `<div class="actions"><button class="btn ${on ? '' : 'ghost'}" data-act="toggleread" id="readbtn">${on ? '✓ ' + (isP(sp) ? 'Prié' : 'Lu / terminé') : (isP(sp) ? 'Marquer comme prié' : 'Marquer comme lu')}</button><button class="btn ghost" data-act="note">📓 Noter dans mon carnet</button><button class="btn ghost" data-act="copyitem">Copier</button><button class="btn ghost" data-act="shareitem">Partager</button></div>`;
  openModal(head(esc(nice(it.title)), tags, esc(SP[sp].name) + ' · ' + esc(LIBNAME[sp])) + `<div class="sheet-body">${it.ref && !isP(sp) ? `<p class="hint">📖 ${esc(it.ref)}</p>` : ''}${b}</div>`, refreshAfter);
  if (r.quiz) { QZ = { i: 0, score: 0, ans: null, done: false }; drawQuiz(); }
  if (r.steps) drawChecks('steps', r.steps, true);
  if (r.checklist) drawChecks('check', r.checklist, false);
}
function itemText(it) {
  if (isP(it.sp)) return ptxt(p2text(it.raw)) + '\n— ' + it.raw.ref;
  return it.title + '\n' + (it.raw.sections || []).map(s => s.h + '\n' + (s.t || '')).join('\n\n');
}
function drawChecks(kind, arr, isChallenge) {
  const id = CUR.id, st = getP(kind, id) || {}, n = Object.values(st).filter(Boolean).length;
  const pct = Math.round(n / arr.length * 100);
  $('#' + kind).innerHTML = `<div class="bar-prog" aria-label="Progression"><i style="width:${pct}%"></i></div><p class="hint">${n} / ${arr.length} accomplis (${pct} %)</p>` +
    arr.map((t, i) => `<label class="chk ${st[i] ? 'on' : ''}"><input type="checkbox" data-act="chk" data-kind="${kind}" data-i="${i}" ${st[i] ? 'checked' : ''}><span>${esc(t)}</span></label>`).join('') +
    (isChallenge && n === arr.length ? `<div class="badge-big">🏅 Badge débloqué : « ${esc(CUR.raw.badge || 'Bravo')} »<div class="hint" style="font-family:var(--sans);font-size:.85rem">Un badge éducatif : il célèbre ta régularité et ta créativité, jamais ta foi.</div></div>` : '');
}
function drawQuiz() {
  const q = CUR.raw.quiz, Z = QZ, box = $('#quiz'); if (!box) return;
  const prev = getP('quiz', CUR.id);
  if (Z.done) {
    const pct = Math.round(Z.score / q.length * 100);
    box.innerHTML = `<div class="badge-big">Score éducatif : ${Z.score} / ${q.length}</div><p>${pct >= 80 ? 'Bravo, belle connaissance de la Parole !' : pct >= 50 ? 'Bien joué ! Relis les fiches de correction pour progresser.' : 'Courage ! Chaque lecture est un pas. Relis les références et réessaie.'}</p><p class="hint">Ce score mesure un apprentissage, jamais ta foi.</p><div class="actions"><button class="btn" data-act="qretry">Recommencer</button></div>`;
    return;
  }
  const cur = q[Z.i];
  box.innerHTML = `${prev ? `<p class="hint">Dernier score : ${prev.score}/${prev.total}</p>` : ''}<p class="hint">Question ${Z.i + 1} sur ${q.length}</p><div class="bar-prog"><i style="width:${Z.i / q.length * 100}%"></i></div><h4 style="font-family:var(--sans);font-size:1.05rem">${esc(cur.q)}</h4>` +
    cur.options.map((o, i) => `<button class="opt ${Z.ans !== null ? (i === cur.correct ? 'good' : i === Z.ans ? 'bad' : '') : ''}" data-act="ans" data-i="${i}" ${Z.ans !== null ? 'disabled' : ''}>${esc(o)}</button>`).join('') +
    (Z.ans !== null ? `<div class="fb"><strong>${Z.ans === cur.correct ? '✓ Bonne réponse.' : '✗ Pas tout à fait.'}</strong> ${esc(cur.feedback)}</div><div class="actions"><button class="btn" data-act="qnext">${Z.i + 1 < q.length ? 'Question suivante' : 'Voir mon score'}</button></div>` : '');
}

/* ------------------------------------------------------------ carnet privé */
let notesFilter = '';
function carnetHTML(editId, pre) {
  const e = editId ? NOTES.find(n => n.id === editId) : null;
  const list = NOTES.filter(n => !n.del && (!notesFilter || n.status === notesFilter)).sort((a, b) => b.updated - a.updated);
  return head('📓 Mon Carnet Personnel 100 % Privé') + `<div class="sheet-body"><div class="lock">🔒 Tes notes sont strictement privées : elles restent sur cet appareil et, si tu actives la synchronisation, sont isolées par compte (RLS). Elles ne sont jamais publiques ni visibles des églises.</div>
  <form id="note-form" data-id="${e ? e.id : ''}"><label class="f" for="n-title">Titre</label><input type="text" id="n-title" maxlength="120" required value="${esc(e ? e.title : (pre && pre.title) || '')}">
  <label class="f" for="n-body" style="margin-top:8px">Mon sujet de prière / ma réflexion</label><textarea id="n-body">${esc(e ? e.body : (pre && pre.body) || '')}</textarea>
  <label class="f" for="n-status" style="margin-top:8px">Statut</label><select id="n-status">${STATUSES.map(s => `<option ${e && e.status === s ? 'selected' : ''}>${s}</option>`).join('')}</select>
  <div class="actions"><button class="btn" type="submit">${e ? 'Enregistrer' : 'Ajouter au carnet'}</button>${e ? '<button class="btn ghost" type="button" data-act="carnet">Annuler</button>' : ''}</div></form>
  <div class="chips" style="margin:16px 0 4px"><button class="chip" data-act="nf" data-v="" aria-pressed="${!notesFilter}">Toutes</button>${STATUSES.map(s => `<button class="chip" data-act="nf" data-v="${s}" aria-pressed="${notesFilter === s}">${s}</button>`).join('')}</div>
  ${list.length ? list.map(n => `<div class="note"><span class="badge ${n.status === 'Exaucée' ? 'ok' : ''}">${esc(n.status)}</span> <span class="hint">${new Date(n.updated).toLocaleDateString('fr-FR')}</span><h4>${esc(n.title)}</h4><pre>${esc(n.body)}</pre><div class="actions" style="margin-top:4px"><button class="btn ghost sm" data-act="nedit" data-id="${n.id}">Modifier</button><button class="btn ghost sm" data-act="nstat" data-id="${n.id}">Statut suivant</button><button class="btn danger sm" data-act="ndel" data-id="${n.id}">Supprimer</button></div></div>`).join('') : '<div class="empty">Aucune note pour le moment.</div>'}</div>`;
}
function openCarnet(editId, pre) { openModal(carnetHTML(editId, pre)); }

/* ------------------------------------------------------------ outils P2 : minuteur & culte familial */
function rng(seed) { return function () { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
function pick(arr, n, r) { const a = arr.slice(), out = []; while (out.length < n && a.length) out.push(a.splice(Math.floor(r() * a.length), 1)[0]); return out; }
const topicsOf = type => D.p2.filter(t => t.t === type);
function dayVerse(seed) {
  const meds = D.p1.filter(x => x.kind === 'meditation'), m = meds[seed % meds.length], s = m.sections[1].t.split('\n');
  return { text: s[0], ref: m.ref, title: m.title };
}
const li = t => `<li>${phtml(S.ver === 'kid' ? t.k : t.o)} <span class="hint">(${esc(t.ref || t.id)})</span></li>`;
const TM = { step: 0, end: 0, left: 300, run: false, iv: null, done: [false, false, false], seed: Date.now() };
const TSTEPS = [['Adoration & actions de grâces', 'THANKSGIVING'], ['Parole & méditation', null], ['Intercession & requêtes', 'REQUEST']];
function timerContent() {
  const r = rng(TM.seed + TM.step * 977), v = dayVerse(Math.floor(TM.seed / 1000) % 97);
  if (TM.step === 0) return '<p><strong>Remercie Dieu</strong> à voix haute ou en silence, puis prie un de ces sujets :</p><ul>' + pick(topicsOf('THANKSGIVING'), 2, r).map(li).join('') + '</ul>';
  if (TM.step === 1) return `<blockquote class="verse">« ${esc(v.text)} »<cite>${esc(v.ref)} · ${esc(v.title)}</cite></blockquote><p>${esc(D.culte.reflexion[Math.floor(r() * D.culte.reflexion.length)])}</p>`;
  return '<p>Présente à Dieu ces requêtes, puis proclame par la foi :</p><ul>' + pick(topicsOf('REQUEST'), 2, r).concat(pick(topicsOf('SPIRITUAL_WARFARE'), 1, r)).map(li).join('') + '</ul>';
}
function timerHTML() {
  const mm = String(Math.floor(TM.left / 60)).padStart(2, '0'), ss = String(TM.left % 60).padStart(2, '0'), C = 2 * Math.PI * 80, off = C * (1 - TM.left / 300);
  return head('⏱ 15 Min avec Dieu') + `<div class="sheet-body"><div class="steps">${TSTEPS.map((s, i) => `<span class="${TM.done[i] ? 'ok' : i === TM.step ? 'on' : ''}">${i + 1} · ${s[0]}</span>`).join('')}</div>
  <div class="ring"><svg width="190" height="190" viewBox="0 0 190 190" aria-hidden="true"><circle cx="95" cy="95" r="80" fill="none" stroke="var(--line)" stroke-width="12"/><circle id="tm-arc" cx="95" cy="95" r="80" fill="none" stroke="var(--sp)" stroke-width="12" stroke-linecap="round" stroke-dasharray="${C}" stroke-dashoffset="${off}"/></svg><div class="t" id="tm-t" role="timer">${mm}:${ss}</div></div>
  <div class="actions" style="justify-content:center"><button class="btn" data-act="tm-toggle" id="tm-btn">${TM.run ? 'Pause' : 'Démarrer'}</button><button class="btn ghost" data-act="tm-next">Étape suivante</button><button class="btn ghost" data-act="tm-reset">Réinitialiser</button><button class="btn ghost" data-act="tm-alt">↻ Autre suggestion</button></div>
  <div id="tm-body" class="sec">${timerContent()}</div><p class="hint">Sessions de 15 minutes terminées : ${Object.keys(PR.timer || {}).length}. Un signal sonore marque chaque étape.</p></div>`;
}
function beep() {
  try { const a = new (window.AudioContext || window.webkitAudioContext)(), o = a.createOscillator(), g = a.createGain(); o.connect(g); g.connect(a.destination); o.frequency.value = 660; g.gain.value = .07; o.start(); setTimeout(() => { o.stop(); a.close(); }, 350); } catch (e) { /* ignore */ }
  try { if (navigator.vibrate) navigator.vibrate([120, 60, 120]); } catch (e) { /* ignore */ }
}
function tmTick() {
  if (!TM.run) return;
  TM.left = Math.max(0, Math.ceil((TM.end - Date.now()) / 1000));
  if (TM.left <= 0) {
    TM.done[TM.step] = true; beep();
    if (TM.step < 2) { TM.step++; TM.left = 300; TM.end = Date.now() + 300000; toast('Étape suivante : ' + TSTEPS[TM.step][0]); }
    else { TM.run = false; clearInterval(TM.iv); setP('timer', String(Date.now()), true); toast('🎉 15 minutes avec Dieu terminées !'); }
    refreshTimer(true); return;
  }
  refreshTimer(false);
}
function refreshTimer(full) {
  if (!$('#tm-t')) { clearInterval(TM.iv); return; }
  if (full) { openModal(timerHTML(), tmStop); return; }
  const mm = String(Math.floor(TM.left / 60)).padStart(2, '0'), ss = String(TM.left % 60).padStart(2, '0');
  $('#tm-t').textContent = mm + ':' + ss; const C = 2 * Math.PI * 80; $('#tm-arc').setAttribute('stroke-dashoffset', C * (1 - TM.left / 300));
}
function tmStop() { TM.run = false; clearInterval(TM.iv); }
function openTimer() { openModal(timerHTML(), tmStop); }
function culteHTML(seed) {
  const r = rng(seed), v = dayVerse(seed % 97), th = pick(topicsOf('THANKSGIVING'), 1, r), rq = pick(topicsOf('REQUEST'), 2, r), wf = pick(topicsOf('SPIRITUAL_WARFARE'), 1, r);
  const ou = D.culte.ouverture[Math.floor(r() * D.culte.ouverture.length)], re = D.culte.reflexion[Math.floor(r() * D.culte.reflexion.length)];
  return head('🕯 Culte Familial du Jour') + `<div class="sheet-body"><p class="hint">${new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })} · environ 20 minutes</p>
  <section class="sec"><h3>1. Ouverture</h3><p>${esc(ou)}</p></section>
  <section class="sec"><h3>2. Parole de Dieu</h3><blockquote class="verse">« ${esc(v.text)} »<cite>${esc(v.ref)}</cite></blockquote><p>${esc(re)}</p></section>
  <section class="sec"><h3>3. Action de grâces</h3><ul>${th.map(li).join('')}</ul></section>
  <section class="sec"><h3>4. Intercession</h3><ul>${rq.concat(wf).map(li).join('')}</ul></section>
  <section class="sec"><h3>5. Bénédiction</h3><div class="prayer">${esc(D.culte.benediction)}</div></section>
  <div class="actions"><button class="btn" data-act="culte-new">↻ Autre proposition</button><button class="btn ghost" data-act="culte-copy">Copier</button><button class="btn ghost" data-act="timer">⏱ 15 Min avec Dieu</button></div></div>`;
}
let CULTE_SEED = 0;
function openCulte(seed) {
  const d = new Date(); CULTE_SEED = seed || (d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate());
  openModal(culteHTML(CULTE_SEED));
}

/* ------------------------------------------------------------ profil, badges, fiches perso */
function badges() {
  const out = [], read = Object.values(PR.read).filter(e => e.v).length, prayed = Object.values(PR.prayed).filter(e => e.v).length;
  const steps = PR.steps['p1-defi-7jours'] && PR.steps['p1-defi-7jours'].v, st = steps ? Object.values(steps).filter(Boolean).length : 0;
  out.push(['🌟 Semeuse de joie', st === 7, 'Terminer le défi de 7 jours']);
  out.push(['📚 Lectrice assidue', read >= 10, 'Lire 10 fiches']);
  out.push(['🙏 Intercesseur fidèle', prayed >= 10, 'Prier 10 sujets']);
  out.push(['🧠 Apprentie de la Parole', Object.keys(PR.quiz).length >= 3, 'Terminer 3 quiz']);
  out.push(['⏱ Rendez-vous avec Dieu', Object.keys(PR.timer).length >= 1, 'Terminer 15 minutes avec Dieu']);
  out.push(['🗓 Cap sur la nouvelle année', ((PR.check['p3-24'] || {}).v ? Object.values(PR.check['p3-24'].v).filter(Boolean).length : 0) >= 12, 'Cocher toute la check-list de fin d\'année']);
  return out;
}
let deferredInstall = null;
function profilHTML() {
  const b = badges(), read = Object.values(PR.read).filter(e => e.v).length, prayed = Object.values(PR.prayed).filter(e => e.v).length;
  return head('👤 Profil & badges') + `<div class="sheet-body"><div class="stats" style="gap:10px"><div class="stat" style="background:var(--sp-s);color:var(--ink);border-color:var(--line)"><b>${read}</b>fiches lues</div><div class="stat" style="background:var(--sp-s);color:var(--ink);border-color:var(--line)"><b>${prayed}</b>sujets priés</div><div class="stat" style="background:var(--sp-s);color:var(--ink);border-color:var(--line)"><b>${Object.keys(PR.quiz).length}</b>quiz terminés</div></div>
  <section class="sec"><h3>Mon prénom</h3><input type="text" id="p-name" value="${esc(S.name)}" maxlength="40" placeholder="Prénom (pour Élan Famille)"><p class="hint">Aucune donnée personnelle n'est envoyée au cloud, sauf ton carnet et ta progression si tu actives la synchronisation.</p></section>
  <section class="sec"><h3>Badges éducatifs</h3>${b.map(x => `<div class="chk ${x[1] ? 'on' : ''}" style="cursor:default"><span><strong>${esc(x[0])}</strong> — ${esc(x[2])}</span></div>`).join('')}<p class="hint">Les badges valorisent la régularité, l'apprentissage et la créativité. La foi et la prière ne sont jamais notées.</p></section>
  <div class="actions"><button class="btn" data-act="open-sync">☁ Synchronisation & sauvegardes</button>${deferredInstall ? '<button class="btn ghost" data-act="install">⬇ Installer l\'application</button>' : ''}</div></div>`;
}
function cardForm(c, sp) {
  const subs = [...new Set(items(sp).map(i => i.sub).filter(Boolean))].slice(0, 60);
  const spOpts = SPACES.map(x => `<option value="${x}" ${x === sp ? 'selected' : ''}>${esc(SP[x].name)}</option>`).join('');
  return head(c ? 'Modifier ma fiche' : 'Nouvelle fiche personnelle') + `<div class="sheet-body">
  <div class="howto"><b>Comment créer une fiche ?</b><ol><li>Choisis l'espace où elle sera classée.</li><li>Donne un <b>titre</b> court (ex. « Prière pour la famille Koné »).</li><li>Rédige le <b>contenu</b> : verset, prière, réflexion ou plan d'action.</li><li>Enregistre : elle apparaît dans la bibliothèque (badge « Perso ») et peut être retrouvée par la recherche.</li></ol></div>
  <form id="card-form" data-id="${c ? c.id : ''}" data-sp="${sp}">
  <label class="f" for="c-sp">Espace</label><select id="c-sp" ${c ? 'disabled' : ''}>${spOpts}</select>
  <label class="f" for="c-sub" style="margin-top:8px">Rubrique (liste déroulante ou saisie libre)</label><input type="text" id="c-sub" list="c-subs" maxlength="80" value="${esc(c ? c.sub || '' : '')}" placeholder="Ex. : Prière du matin"><datalist id="c-subs">${subs.map(x => `<option value="${esc(x)}">`).join('')}</datalist>
  <label class="f" for="c-title" style="margin-top:8px">Titre</label><input type="text" id="c-title" required maxlength="140" value="${esc(c ? c.title : '')}">
  <label class="f" for="c-text" style="margin-top:8px">Contenu</label><textarea id="c-text" required>${esc(c ? c.text : '')}</textarea>
  <div class="actions"><button class="btn" type="submit">Enregistrer</button>${c ? `<button class="btn danger" type="button" data-act="delcard" data-id="${c.id}">Supprimer</button>` : ''}</div>
  <p class="hint">Cette fiche est personnelle (visible uniquement par toi) et se synchronise avec ton compte si le cloud est activé.</p></form></div>`;
}

/* ------------------------------------------------------------ registre de prière (enfants · parents · enfants missionnaires) */
let REG = { cat: 'CHILD', sub: '', edit: null };
function registreHTML() {
  const cat = REG.cat, list = peopleOf(cat), foc = S.focus || { cat: '', ids: [] }, e = REG.edit ? PEOPLE.find(p => p.id === REG.edit) : null;
  const active = foc.cat && peopleOf(foc.cat).some(p => foc.ids.includes(p.id));
  const status = active ? `✅ Actif : toutes les prières mentionnent <b>${esc(focusLabel())}</b> (${esc(PCATS[foc.cat].l)}).` : 'Aucun groupe actif : les prières utilisent le prénom saisi dans « Mon prénom ».';
  return head('Registre de prière') + `<div class="sheet-body">
  <div class="lock">Saisis une fois les noms et prénoms ; ils remplacent automatiquement <b>{PRENOM}</b> dans <b>toutes</b> les prières d'Élan Famille, le minuteur et le culte familial. Données stockées uniquement sur cet appareil.</div>
  <label class="f" for="reg-cat">Je prie pour</label>
  <select id="reg-cat">${PKEYS().map(k => `<option value="${k}" ${k === cat ? 'selected' : ''}>${PCATS[k].l} (${peopleOf(k).length})</option>`).join('')}</select>
  <form id="people-form" data-id="${e ? e.id : ''}"><div class="two"><div><label class="f" for="pp-last">Nom</label><input type="text" id="pp-last" maxlength="60" required value="${esc(e ? e.last : '')}" placeholder="Ex. : KONÉ"></div>
  <div><label class="f" for="pp-first">Prénoms</label><input type="text" id="pp-first" maxlength="80" required value="${esc(e ? e.first : '')}" placeholder="Ex. : Grâce Marie"></div></div>
  ${PCATS[cat].subs ? `<label class="f" for="pp-sub" style="margin-top:8px">Sous-rubrique</label><select id="pp-sub">${subOptions(cat, e ? e.sub : REG.sub).replace('Toutes les sous-rubriques', 'Aucune en particulier')}</select>` : ''}
  <label class="f" for="pp-note" style="margin-top:8px">Précision (âge, pays, besoin… facultatif)</label><input type="text" id="pp-note" maxlength="120" value="${esc(e ? e.note || '' : '')}">
  <div class="actions"><button class="btn" type="submit">${e ? 'Enregistrer' : '＋ Ajouter'}</button>${e ? '<button class="btn ghost" type="button" data-act="pcancel">Annuler</button>' : ''}</div></form>
  ${e ? '' : `<details class="bulk"><summary>Ajouter plusieurs personnes en une fois</summary><label class="f" for="pp-bulk">Une personne par ligne : NOM Prénoms</label><textarea id="pp-bulk" placeholder="KONÉ Grâce Marie&#10;KONÉ David&#10;TRAORÉ Esther"></textarea><div class="actions"><button class="btn ghost" type="button" data-act="pbulk">Ajouter la liste</button></div></details>`}
  <h3 style="margin:16px 0 6px">${PCATS[cat].l} <small class="hint">(${list.length})</small></h3>
  ${list.length ? `<div class="chips" style="margin-bottom:8px"><button class="chip" data-act="pall" data-v="1">Tout cocher</button><button class="chip" data-act="pall" data-v="0">Tout décocher</button></div>` + list.map(p => `<div class="person"><label><input type="checkbox" data-act="pchk" data-id="${p.id}" ${foc.cat === cat && foc.ids.includes(p.id) ? 'checked' : ''}> <b>${esc(p.last)}</b> ${esc(p.first)}${p.sub ? ` <span class="hint">· ${esc(p.sub)}</span>` : ''}${p.note ? ` <span class="hint">· ${esc(p.note)}</span>` : ''}</label><span><button class="btn ghost sm" data-act="pedit" data-id="${p.id}">Modifier</button> <button class="btn danger sm" data-act="pdel" data-id="${p.id}">✕</button></span></div>`).join('') : '<div class="empty">Personne dans cette liste pour le moment.</div>'}
  <div class="howto" style="margin-top:12px">${status}</div>
  <div class="actions"><button class="btn amber" data-act="papply">Prier pour la sélection dans toutes les prières</button><button class="btn ghost" data-act="pclear">Désactiver</button></div></div>`;
}
function openRegistre() { openModal(registreHTML()); }
function addPerson(last, first, note, sub) {
  PEOPLE.push({ id: 'pp-' + uid(), cat: REG.cat, last: last.trim(), first: first.trim(), note: (note || '').trim(), sub: sub || '', updated: Date.now(), del: false });
}
/* Bouton « Effacer » : vide le prénom saisi ET la sélection du registre, remet {PRENOM} partout et rafraîchit l'interface. */
function clearPrenom() {
  S.name = ''; S.focus = { cat: '', ids: [] }; saveS(); savePeople(); updateSide();
  ['name-in', 'd-name', 'p-name', 'pq-name'].forEach(id => { const o = $('#' + id); if (o) o.value = ''; });
  if (CUR && $('#pray')) $('#pray').innerHTML = phtml(p2text(CUR.raw));
  if (S.view === 'space' && isP(S.space) && $('#app')) { const keep = window.scrollY; renderSpace(); window.scrollTo(0, keep); }
  toast('Prénom effacé : « {PRENOM} » est rétabli dans les prières.');
}
function showRubric() {
  const c = PCATS[$('#pq-cat').value] || {}, f = F.P2; f.grp = c.grp ? D.p2groups[c.grp].name : ''; f.cat = ''; f.sub = ''; f.ex = '';
  const sv = $('#pq-sub') && !$('#pq-subbox').hidden ? $('#pq-sub').value : '';
  if (c.cat) { f.cat = D.tax.cats[c.cat].name; if (sv) f.sub = sv; }
  shown = 24; renderFilters(); renderList(); const l = $('#dd'); if (l) l.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function refreshPrayers() { savePeople(); saveS(); updateSide(); if (S.view === 'space' && isP(S.space) && $('#list')) renderList(); }

/* ------------------------------------------------------------ actualités du jour (aide à la prière et au discernement, 100 % hors-ligne) */
const dayIndex = () => Math.floor((Date.now() - new Date().getTimezoneOffset() * 60000) / 864e5);
const FEEDS = [
  { id: 'reforme', name: 'Réforme (protestant)', url: 'https://www.reforme.net/feed/' },
  { id: 'fpf', name: 'Fédération protestante de France', url: 'https://www.protestants.org/feed/' },
  { id: 'evch', name: 'Réseau évangélique suisse', url: 'https://www.evangelique.ch/feed/' },
  { id: 'aleteia', name: 'Aleteia (chrétien, catholique)', url: 'https://fr.aleteia.org/feed/' },
  { id: 'vatican', name: 'Vatican News', url: 'https://www.vaticannews.va/fr.rss.xml' },
  { id: 'croix', name: 'La Croix', url: 'https://www.la-croix.com/RSS' }
];
const FEEDK = 'ec5_feeds';
let FEEDCACHE = store.get(FEEDK, {}), FEEDLIST = [], feedBusy = false;
const stripHtml = h => { const t = document.createElement('div'); t.innerHTML = String(h || ''); return (t.textContent || '').replace(/\s+/g, ' ').trim(); };
async function fetchFeed(f) {
  const r = await fetch('https://api.rss2json.com/v1/api.json?rss_url=' + encodeURIComponent(f.url));
  const j = await r.json(); if (j.status !== 'ok') throw new Error('flux indisponible');
  return (j.items || []).slice(0, 8).map(i => ({ title: stripHtml(i.title), link: i.link, date: i.pubDate, txt: stripHtml(i.description).slice(0, 180), src: f.name, sid: f.id }));
}
function feedBoxHTML(msg) {
  const sel = S.feedSrc || 'all', list = FEEDLIST;
  const when = (FEEDCACHE._t ? 'Dernière mise à jour : ' + new Date(FEEDCACHE._t).toLocaleString('fr-FR') : 'Pas encore chargé');
  return `<div class="feed-bar"><label class="ddf"><span>Source</span><select id="feed-src"><option value="all" ${sel === 'all' ? 'selected' : ''}>Toutes les sources</option>${FEEDS.map(f => `<option value="${f.id}" ${sel === f.id ? 'selected' : ''}>${esc(f.name)}</option>`).join('')}</select></label><button class="btn ghost sm" data-act="feed-refresh">↻ Actualiser</button></div>
  <p class="hint">${esc(msg || when)}</p>` + (list.length ? list.map((n, i) => `<article class="feed-item"><span class="badge">${esc(n.src)}</span> <span class="hint">${n.date ? new Date(n.date.replace(' ', 'T')).toLocaleDateString('fr-FR') : ''}</span><h4><a href="${esc(n.link)}" target="_blank" rel="noopener noreferrer">${esc(n.title)}</a></h4>${n.txt ? `<p class="hint">${esc(n.txt)}…</p>` : ''}<div class="actions" style="margin-top:2px"><button class="btn ghost sm" data-act="feed-pray" data-i="${i}">🙏 Prier pour cela</button></div></article>`).join('') : '<div class="empty">Aucune actualité à afficher (connexion requise la première fois).</div>');
}
function renderFeed(msg) { const b = $('#feed-box'); if (b) b.innerHTML = feedBoxHTML(msg); }
async function loadFeeds(force) {
  const sel = S.feedSrc || 'all', want = sel === 'all' ? FEEDS : FEEDS.filter(f => f.id === sel);
  const fresh = id => FEEDCACHE[id] && Date.now() - FEEDCACHE[id].t < 3 * 36e5;
  const pickList = () => want.flatMap(f => (FEEDCACHE[f.id] ? FEEDCACHE[f.id].items.slice(0, sel === 'all' ? 3 : 8) : []));
  FEEDLIST = pickList(); renderFeed();
  if (!force && want.every(f => fresh(f.id))) return;
  if (!navigator.onLine) { renderFeed('Hors-ligne : affichage des dernières actualités enregistrées.'); return; }
  if (feedBusy) return; feedBusy = true; renderFeed('Chargement des actualités des sites chrétiens…');
  let ok = 0;
  await Promise.all(want.map(f => fetchFeed(f).then(items => { FEEDCACHE[f.id] = { t: Date.now(), items }; ok++; }).catch(() => { })));
  feedBusy = false;
  if (ok) { FEEDCACHE._t = Date.now(); store.set(FEEDK, FEEDCACHE); }
  FEEDLIST = pickList();
  renderFeed(ok ? '' : "Impossible de joindre les sites pour l'instant : réessaie plus tard.");
}
const NEWS_TOPICS = [
  ['Les dirigeants et la paix', "Prie pour la sagesse des dirigeants, la justice et la fin des conflits (1 Timothée 2:1-2)."],
  ['Les familles et les enfants', "Prie pour les foyers en difficulté, les enfants vulnérables, les orphelins et les parents épuisés."],
  ["L'Église et les responsables", "Prie pour l'unité, l'intégrité et la protection des Églises et de leurs responsables."],
  ['Les persécutés et les réfugiés', "Prie pour ceux qui souffrent à cause de leur foi, de la guerre ou de l'exil."],
  ['Les jeunes et les écoles', "Prie pour les élèves, étudiants, enseignants, et pour l'orientation des jeunes."],
  ['Les malades et les soignants', "Prie pour les malades, les personnes en deuil, les soignants et les services de santé."],
  ["Les pauvres et l'économie", "Prie pour ceux qui n'ont pas d'emploi, de nourriture ou de logement, et pour la justice économique."],
  ['Les catastrophes et les secours', "Prie pour les victimes d'inondations, séismes, incendies, accidents et pour les équipes de secours."],
  ['Les médias et la vérité', "Prie pour des médias honnêtes, contre la rumeur et la manipulation, pour le discernement du public."],
  ['La justice et les victimes', "Prie pour les victimes de violence, de trafic ou d'abus, pour les juges et les forces de l'ordre."],
  ['Les missionnaires et les nations', "Prie pour les missionnaires, la traduction de la Bible, les peuples non atteints."],
  ['Les femmes et les jeunes filles', "Prie pour leur protection, leur éducation, leur dignité et leur avenir."],
  ["La création et l'environnement", "Prie pour la sagesse dans la gestion des ressources, l'eau, la terre, les saisons."],
  ['Ma ville et mon quartier', "Prie pour tes voisins, ton école ou ton lieu de travail, et pour les besoins locaux (Jérémie 29:7)."]
];
const NEWS_VERSES = [
  ['Psaume 46:2', "Dieu est pour nous un refuge et un appui, Un secours qui ne manque jamais dans les détresses."],
  ['Proverbes 14:15', "L'homme simple croit tout ce qu'on dit, Mais l'homme prudent est attentif à ses pas."],
  ['1 Thessaloniciens 5:21', "Mais examinez toutes choses ; retenez ce qui est bon ;"],
  ['1 Timothée 2:1', "J'exhorte donc, avant toutes choses, à faire des prières, des supplications, des requêtes, des actions de grâces, pour tous les hommes,"],
  ['Jérémie 29:7', "Recherchez la paix de la ville où je vous ai fait aller en exil, et priez l'Éternel en sa faveur ; car dans sa paix vous aurez la paix."],
  ['Philippiens 4:6', "Ne vous inquiétez de rien ; mais en toute chose faites connaître vos besoins à Dieu par des prières et des supplications, avec des actions de grâces."]
];
function actuHTML() {
  const d = dayIndex(), topics = [0, 1, 2].map(i => NEWS_TOPICS[(d * 3 + i) % NEWS_TOPICS.length]), v = NEWS_VERSES[d % NEWS_VERSES.length];
  const date = new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  const list = NEWS.filter(n => !n.del).sort((a, b) => b.updated - a.updated);
  const fiches = (D.actu || []).map(it => `<details class="bulk"><summary>${esc(nice(it.title))}</summary>${it.sections.map(sectionHTML).join('')}</details>`).join('');
  return head('Actualités &amp; Ressources du jour') + `<div class="sheet-body">
  <div class="lock">${esc(date)} — les titres ci-dessous viennent de sites chrétiens (protestants, évangéliques, catholiques). Ouvre l'article complet et garde ton discernement : l'application ne contrôle pas leur contenu.</div>
  ${tips3HTML('actu')}
  <section class="sec"><h3>Actualités &amp; Sensibilisation Chrétienne</h3><div id="nj-box"><p class="hint">Chargement…</p></div></section>
  <section class="sec"><h3>Actualités des sites chrétiens</h3><div id="feed-box">${feedBoxHTML()}</div></section>
  <section class="sec"><h3>Verset du jour</h3><blockquote class="verse" style="margin:8px 0">${esc(v[1])}<cite>${esc(v[0])} (Louis Segond 1910)</cite></blockquote></section>
  <section class="sec"><h3>Trois sujets de prière du jour</h3><ul>${topics.map(t => `<li><b>${esc(t[0])}</b> — ${esc(t[1])}</li>`).join('')}</ul></section>
  <section class="sec"><h3>Avant de croire ou de partager</h3><ol><li>Qui parle ? La source est-elle connue et sérieuse ?</li><li>La date et le lieu sont-ils clairs ? Un deuxième média le confirme-t-il ?</li><li>Quelle émotion cherche-t-on à provoquer (peur, colère) ?</li><li>Que dit la Parole de Dieu sur cette situation ?</li><li>Que puis-je faire : prier, donner, visiter, me taire ?</li></ol></section>
  <section class="sec"><h3>Module · Lire et prier l'actualité</h3>${fiches}</section>
  <section class="sec"><h3>Mes actualités à porter dans la prière</h3>
  <form id="news-form"><label class="f" for="nw-title">Nouvelle ou événement</label><input type="text" id="nw-title" required maxlength="160" placeholder="Ex. : Inondations dans la région…">
  <div class="two"><div><label class="f" for="nw-src">Source (facultatif)</label><input type="text" id="nw-src" maxlength="120" placeholder="Ex. : radio, journal, église"></div><div><label class="f" for="nw-cat">Type</label><select id="nw-cat"><option>Nation & dirigeants</option><option>Famille & jeunesse</option><option>Église & mission</option><option>Santé & deuil</option><option>Paix & justice</option><option>Catastrophe & secours</option><option>Autre</option></select></div></div>
  <label class="f" for="nw-pr" style="margin-top:8px">Mon point de prière</label><textarea id="nw-pr" maxlength="400" placeholder="Seigneur, je te présente…"></textarea>
  <div class="actions"><button class="btn" type="submit">＋ Ajouter</button></div></form>
  ${list.length ? list.map(n => `<div class="note"><span class="badge">${esc(n.cat)}</span> <span class="hint">${new Date(n.updated).toLocaleDateString('fr-FR')}${n.src ? ' · ' + esc(n.src) : ''}</span><h4>${esc(n.title)}</h4>${n.pr ? `<pre>${esc(n.pr)}</pre>` : ''}<div class="actions" style="margin-top:4px"><button class="btn ghost sm" data-act="xnote" data-id="${n.id}">📓 Au carnet</button><button class="btn danger sm" data-act="xdel" data-id="${n.id}">Supprimer</button></div></div>`).join('') : '<div class="empty">Aucune actualité enregistrée.</div>'}
  </section></div>`;
}
function openActu() { showActu(); }

/* ------------------------------------------------------------ guide d'utilisation */
function guideHTML() {
  const sec = (t, items) => `<section class="sec"><h3>${t}</h3><ul>${items.map(i => `<li>${i}</li>`).join('')}</ul></section>`;
  return head('Guide d\'utilisation') + `<div class="sheet-body">
  <div class="lock">Écosystème Chrétien est un portail biblique et spirituel : <b>Foi · Famille · Vie spirituelle</b>. Tout fonctionne hors-ligne ; tes données restent sur ton appareil.</div>
  ${sec('Menu latéral (Espaces)', ['<b>Fille de la promesse</b> : méditations, quiz, ateliers et défis pour grandir dans la foi.', '<b>Source de vie</b> (sous Génération Lumière) : 66 prières : Prière Générale, Prière pour les Bénédictions et 9 rubriques de délivrance (moments difficiles, paix, délivrance, combat spirituel, protection, matin et soir, guérison, réussite, gratitude), avec synchronisation optionnelle de prieredelivrance.com.', '<b>Élan Famille</b> : 383 sujets de prière pour enfants, parents et encadreurs (actions de grâces, requêtes, combat spirituel).', '<b>Génération Lumière</b> (jeunesse) : conduire et orienter une jeunesse locale, programme annuel d\'activités en tableaux (créativité, défis, concours, prière, jeûne, adoration, détente, méditation, jeune du mois), vocation, santé mentale, relations, discernement, famille, argent, cité.', '<b>Fondement vie spirituelle</b> : le don, les autels, les alliances, la consécration et le monde numérique (Internet, réseaux sociaux, technologie, IA).'])}
  ${sec('Onglets d\'un espace', ['<b>📚 Bibliothèque</b> : parcourir, rechercher et filtrer les fiches (boutons à gauche <i>ou</i> listes déroulantes au-dessus de la grille).', '<b>🗓 Programme &amp; rappels</b> : routine quotidienne, hebdomadaire, mensuelle, trimestrielle et annuelle, avec rappels (notifications ou fichier agenda).', 'Le bandeau <b>Conseils &amp; repères</b> propose un conseil, une alerte et une recommandation (copiables et partageables).'])}
  ${sec('Filtrer', ['Utilise la barre de recherche (mot, verset) puis les <b>listes déroulantes</b> : Groupe/Module → Catégorie → Sous-groupe → Type/Âge. Chaque choix affine le suivant.', '« Tout effacer » réinitialise les filtres.'])}
  ${sec('Créer ma fiche', ['Bouton <b>＋ Ma fiche</b> : choisis l\'espace, la rubrique, le titre et le contenu. Elle apparaît avec le badge « Perso » et reste privée.'])}
  ${sec('Programme annuel &amp; capsules vidéo', ['<b>Programme annuel d\'activités</b> : tableau de 12 mois modifiable (clic sur une cellule), choix de l\'année, duplication vers l\'année suivante, export JSON et impression.', '<b>Poèmes, sketchs, slams &amp; jeux</b> : banque de 52 idées (20 poèmes, sketchs, slams, jeux) avec thèmes et passages bibliques, à compléter.', '<b>Capsules vidéo de sensibilisation</b> : lecteur YouTube / MP4 léger et panneau pour ajouter, modifier ou actualiser les liens.'])}
  ${sec('Registre de prière', ['Menu <b>Registre de prière</b> : choisis <i>Enfants</i>, <i>Prière Générale</i>, <i>Prière pour les Bénédictions</i>, <i>Parents</i> ou <i>Enfants missionnaires</i>, saisis nom et prénoms (un par un ou en liste), coche les personnes puis « Prier pour la sélection ».', 'Les noms remplacent <b>{PRENOM}</b> dans toutes les prières, le minuteur « 15 Min avec Dieu » et le culte familial.'])}
  ${sec('Actualités du jour', ['Menu <b>Actualités &amp; Ressources du jour</b> : flux « Actualités &amp; Sensibilisation Chrétienne » (fichier actualites.json modifiable), titres récents de sites chrétiens (liste déroulante de sources, bouton « Actualiser », bouton « Prier pour cela »), verset du jour, sujets de prière, méthode de discernement, et ta liste personnelle (avec envoi vers le carnet). Les titres sont mis en mémoire pour être relus hors-ligne.'])}
  ${sec('Outils &amp; personnel', ['<b>Vue Globale Transversale</b> : recherche dans les trois espaces à la fois.', '<b>Carnet Privé 100 % Local</b> : sujets de prière et réflexions avec statut (En cours · Exaucée · Archivée).', '<b>Synchronisation</b> (pastille en haut à droite) : sauvegardes, export/import JSON, cloud Supabase facultatif.'])}
  ${sec('Informations importantes', ['Textes bibliques : Louis Segond 1910.', 'Sauvegarde : exporte régulièrement un fichier JSON (Synchronisation → Exporter), surtout avant de changer d\'appareil ; vider les données du navigateur efface le registre et le carnet.', 'Taille du texte : boutons A / A+ / A++ en haut. Installation : menu du navigateur → « Installer l\'application ».', 'La foi et la prière ne sont jamais notées ni comptabilisées.'])}
  </div>`;
}

/* ------------------------------------------------------------ synchronisation Supabase (REST, sans dépendance) */
let syncing = false, pending = false, status = 'none', timer = null, lastErr = '';
const STL = { none: 'Mode local', synced: 'Synchronisé', syncing: 'Synchronisation en cours…', offline: 'Mode hors-ligne', error: 'Erreur de synchro' };
const sbOn = () => !!(SY.url && SY.key);
function setStatus(s) {
  status = (!navigator.onLine) ? 'offline' : s;
  const p = $('#sync-pill'); if (!p) return;
  p.hidden = !sbOn(); // pastille utile seulement si la synchronisation est activée
  p.dataset.st = status; $('#sync-label').textContent = STL[status]; p.title = lastErr || '';
  const sl = $('#sync-state'); if (sl) sl.textContent = STL[status] + (SY.last ? ' · dernière synchro ' + new Date(SY.last).toLocaleTimeString('fr-FR') : '');
}
function touch() { if (sbOn()) { clearTimeout(timer); timer = setTimeout(() => syncNow(false), 2500); } }
async function sb(path, opts) {
  opts = opts || {};
  const h = Object.assign({ apikey: SY.key, 'Content-Type': 'application/json' }, opts.headers || {});
  h.Authorization = 'Bearer ' + (opts.anon || !SY.auth ? SY.key : SY.auth.access);
  const r = await fetch(SY.url.replace(/\/+$/, '') + path, { method: opts.method || 'GET', headers: h, body: opts.body ? JSON.stringify(opts.body) : undefined });
  const txt = await r.text(); let j = null; try { j = txt ? JSON.parse(txt) : null; } catch (e) { /* ignore */ }
  if (!r.ok) throw new Error((j && (j.msg || j.message || j.error_description || j.error)) || ('HTTP ' + r.status));
  return j;
}
function keepSession(j, anon) {
  if (!j || !j.access_token) return false;
  SY.auth = { access: j.access_token, refresh: j.refresh_token, exp: Math.floor(Date.now() / 1000) + (j.expires_in || 3600), uid: (j.user && j.user.id) || '', email: (j.user && j.user.email) || '', anon: !!anon };
  saveY(); return true;
}
async function ensureAuth() {
  const now = Math.floor(Date.now() / 1000);
  if (SY.auth && SY.auth.exp > now + 60) return true;
  if (SY.auth && SY.auth.refresh) {
    try { if (keepSession(await sb('/auth/v1/token?grant_type=refresh_token', { method: 'POST', anon: true, body: { refresh_token: SY.auth.refresh } }), SY.auth.anon)) return true; } catch (e) { SY.auth = null; saveY(); }
  }
  try { return keepSession(await sb('/auth/v1/signup', { method: 'POST', anon: true, body: {} }), true); }
  catch (e) { lastErr = 'Connexion requise : active « Anonymous sign-ins » dans Supabase ou connecte-toi par e-mail. (' + e.message + ')'; return false; }
}
const iso = t => new Date(t).toISOString();
async function upsert(table, conflict, rows) {
  if (!rows.length) return;
  await sb('/rest/v1/' + table + '?on_conflict=' + conflict, { method: 'POST', headers: { Prefer: 'resolution=merge-duplicates,return=minimal' }, body: rows });
}
async function syncAll() {
  const u = SY.auth.uid; let changed = false;
  // notes
  const rn = await sb('/rest/v1/private_notes?select=*'), mapN = new Map(rn.map(x => [x.id, x])), pushN = [];
  NOTES.forEach(n => { const r = mapN.get(n.id); const rt = r ? Date.parse(r.updated_at) : 0; if (!r || n.updated > rt) pushN.push({ id: n.id, user_id: u, title: n.title, body: n.body, status: n.status, created_at: iso(n.created), updated_at: iso(n.updated), deleted: !!n.del }); });
  rn.forEach(r => { const l = NOTES.find(n => n.id === r.id), rt = Date.parse(r.updated_at); if (!l) { NOTES.push({ id: r.id, title: r.title, body: r.body, status: r.status, created: Date.parse(r.created_at), updated: rt, del: !!r.deleted }); changed = true; } else if (rt > l.updated) { Object.assign(l, { title: r.title, body: r.body, status: r.status, updated: rt, del: !!r.deleted }); changed = true; } });
  await upsert('private_notes', 'id', pushN);
  // progress
  const rp = await sb('/rest/v1/user_progress?select=*'), mapP = new Map(rp.map(x => [x.key, x])), pushP = [];
  Object.keys(PR).forEach(kind => Object.keys(PR[kind]).forEach(id => { const e = PR[kind][id], key = kind + ':' + id, r = mapP.get(key); if (!r || e.t > ((r.value && r.value.t) || 0)) pushP.push({ user_id: u, key, value: e, updated_at: iso(e.t) }); }));
  rp.forEach(r => { const [kind, ...rest] = r.key.split(':'), id = rest.join(':'), e = r.value; if (!e || !PR[kind]) return; const l = PR[kind][id]; if (!l || e.t > l.t) { PR[kind][id] = e; changed = true; } });
  await upsert('user_progress', 'user_id,key', pushP);
  // fiches perso
  const rc = await sb('/rest/v1/synced_cards?select=*'), mapC = new Map(rc.map(x => [x.id, x])), pushC = [];
  CARDS.forEach(c => { const r = mapC.get(c.id); if (!r || c.updated > Date.parse(r.updated_at)) pushC.push({ id: c.id, user_id: u, project: c.sp, title: c.title, payload: { text: c.text, sub: c.sub || '' }, updated_at: iso(c.updated), deleted: !!c.del }); });
  rc.forEach(r => { const l = CARDS.find(c => c.id === r.id), rt = Date.parse(r.updated_at); if (!l) { CARDS.push({ id: r.id, sp: r.project, title: r.title, text: (r.payload || {}).text || '', sub: (r.payload || {}).sub || '', updated: rt, del: !!r.deleted }); changed = true; } else if (rt > l.updated) { Object.assign(l, { title: r.title, text: (r.payload || {}).text || '', updated: rt, del: !!r.deleted }); changed = true; } });
  await upsert('synced_cards', 'id', pushC);
  if (changed) { saveN(); saveP(); saveC(); }
  return changed;
}
async function syncNow(manual) {
  if (!sbOn()) { setStatus('none'); if (manual) toast('Renseigne l\'URL et la clé Supabase pour activer la synchronisation.'); return; }
  if (!navigator.onLine) { setStatus('offline'); if (manual) toast('Hors-ligne : les données restent enregistrées sur cet appareil.'); return; }
  if (syncing) { pending = true; return; }
  syncing = true; lastErr = ''; setStatus('syncing');
  try {
    if (!(await ensureAuth())) throw new Error(lastErr || 'Authentification impossible');
    const ch = await syncAll(); SY.last = Date.now(); saveY(); setStatus('synced');
    if (ch) { if (!$('#modal').classList.contains('open')) { renderFilters(); renderList(); } }
    if (manual) toast('✓ Synchronisation terminée');
  } catch (e) { lastErr = e.message; setStatus('error'); if (manual) toast('Synchronisation impossible : ' + e.message); }
  finally { syncing = false; const sl = $('#sync-state'); if (sl) setStatus(status); if (pending) { pending = false; touch(); } }
}
function isSecretKey(k) { if (/^sb_secret_/.test(k)) return true; try { const p = JSON.parse(atob(k.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'))); return p.role === 'service_role'; } catch (e) { return false; } }
function snapshots() { return store.get(K.R, []); }
function dump() { return { app: 'ecosysteme-chretien', version: 5, exportedAt: new Date().toISOString(), settings: { name: S.name, text: S.text, ver: S.ver, space: S.space }, progress: PR, notes: NOTES, cards: CARDS, people: PEOPLE, news: NEWS }; }
function mergeIn(d) {
  if (!d || d.app !== 'ecosysteme-chretien') throw new Error('Fichier non reconnu');
  Object.keys(d.progress || {}).forEach(k => { PR[k] = PR[k] || {}; Object.keys(d.progress[k]).forEach(id => { const e = d.progress[k][id]; if (!PR[k][id] || e.t > PR[k][id].t) PR[k][id] = e; }); });
  (d.notes || []).forEach(n => { const l = NOTES.find(x => x.id === n.id); if (!l) NOTES.push(n); else if (n.updated > l.updated) Object.assign(l, n); });
  (d.cards || []).forEach(c => { const l = CARDS.find(x => x.id === c.id); if (!l) CARDS.push(c); else if (c.updated > l.updated) Object.assign(l, c); });
  (d.people || []).forEach(c => { const l = PEOPLE.find(x => x.id === c.id); if (!l) PEOPLE.push(c); else if (c.updated > l.updated) Object.assign(l, c); });
  savePeople();
  (d.news || []).forEach(c => { const l = NEWS.find(x => x.id === c.id); if (!l) NEWS.push(c); else if (c.updated > l.updated) Object.assign(l, c); });
  saveNews();
  if (d.settings && !S.name) S.name = d.settings.name || '';
  saveP(); saveN(); saveC(); saveS();
}
function addSnapshot(label) {
  const a = snapshots(); a.unshift({ id: uid(), label, t: Date.now(), data: dump() }); store.set(K.R, a.slice(0, 8));
}
function syncHTML() {
  const a = SY.auth, snaps = snapshots();
  return head('☁ Synchronisation & sauvegardes') + `<div class="sheet-body">
  <div class="lock" id="sync-state" aria-live="polite">${STL[status]}</div>
  <section class="sec"><h3>Supabase (PostgreSQL)</h3><p class="hint">Exécute d'abord <b>schema_sync_supabase.sql</b> dans l'éditeur SQL de ton projet. L'URL et la clé publique « anon » se saisissent ici : elles restent <b>uniquement sur cet appareil</b> (localStorage). Ne les écris pas dans data.js avant de publier sur GitHub, et n'utilise jamais la clé « service_role ». Sans Supabase, tout fonctionne en <b>mode local</b> (export/import JSON et points de restauration ci-dessous).</p>
  <label class="f" for="sb-url">URL du projet</label><input type="url" id="sb-url" placeholder="https://xxxx.supabase.co" value="${esc(SY.url)}">
  <label class="f" for="sb-key" style="margin-top:8px">Clé publique (anon)</label><input type="password" id="sb-key" placeholder="eyJ…" value="${esc(SY.key)}" autocomplete="off">
  <div class="actions"><button class="btn" data-act="sb-save">Enregistrer & synchroniser</button><button class="btn ghost" data-act="sync-now">Synchroniser maintenant</button></div></section>
  <section class="sec"><h3>Compte</h3><p class="hint">${a ? (a.anon ? 'Session anonyme active (données liées à cet appareil).' : 'Connectée : ' + esc(a.email)) : 'Aucune session. Une session anonyme est créée automatiquement ; connecte-toi par e-mail pour retrouver tes notes sur plusieurs appareils.'}</p>
  <label class="f" for="sb-mail">E-mail</label><input type="email" id="sb-mail" autocomplete="username"><label class="f" for="sb-pw" style="margin-top:8px">Mot de passe</label><input type="password" id="sb-pw" autocomplete="current-password">
  <div class="actions"><button class="btn ghost" data-act="sb-in">Se connecter</button><button class="btn ghost" data-act="sb-up">Créer un compte</button>${a ? '<button class="btn ghost" data-act="sb-out">Se déconnecter</button>' : ''}</div></section>
  <section class="sec"><h3>Export / Import JSON</h3><div class="actions"><button class="btn ghost" data-act="exp">Exporter mes données</button><label class="btn ghost" style="cursor:pointer">Importer un fichier<input type="file" id="imp" accept="application/json,.json" hidden></label></div></section>
  <section class="sec"><h3>Points de restauration locaux</h3><div class="actions"><button class="btn ghost" data-act="snap">Créer un point maintenant</button></div>
  ${snaps.length ? snaps.map(s => `<div class="note"><strong>${esc(s.label)}</strong> <span class="hint">${new Date(s.t).toLocaleString('fr-FR')}</span><div class="actions" style="margin-top:4px"><button class="btn ghost sm" data-act="snap-restore" data-id="${s.id}">Restaurer</button><button class="btn danger sm" data-act="snap-del" data-id="${s.id}">Supprimer</button></div></div>`).join('') : '<p class="hint">Aucun point de restauration.</p>'}</section></div>`;
}
function openSync() { openModal(syncHTML()); setStatus(status); }
async function authEmail(signup) {
  const email = $('#sb-mail').value.trim(), pw = $('#sb-pw').value;
  if (!sbOn()) return toast('Renseigne d\'abord l\'URL et la clé Supabase.');
  if (!email || pw.length < 6) return toast('E-mail et mot de passe (6 caractères min.) requis.');
  try {
    const j = await sb(signup ? '/auth/v1/signup' : '/auth/v1/token?grant_type=password', { method: 'POST', anon: true, body: { email, password: pw } });
    if (keepSession(j, false)) { toast('✓ Connectée'); openSync(); syncNow(true); }
    else toast('Compte créé : confirme ton e-mail, puis connecte-toi.');
  } catch (e) { toast('Échec : ' + e.message); }
}

/* ------------------------------------------------------------ programmes, rappels, vue globale */
const PG = window.PROGRAMS;
const DAYS = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const ICSD = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
const pad = n => String(n).padStart(2, '0');
function isoWeek(d) {
  const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate())), dn = t.getUTCDay() || 7;
  t.setUTCDate(t.getUTCDate() + 4 - dn); const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
  return [t.getUTCFullYear(), Math.ceil(((t - y0) / 864e5 + 1) / 7)];
}
function pkey(type) {
  const d = new Date(), y = d.getFullYear();
  if (type === 'daily') return y + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
  if (type === 'weekly') { const w = isoWeek(d); return w[0] + '-W' + pad(w[1]); }
  if (type === 'monthly') return y + '-' + pad(d.getMonth() + 1);
  if (type === 'quarterly') return y + '-Q' + (Math.floor(d.getMonth() / 3) + 1);
  return String(y);
}
function plabel(type) {
  const d = new Date();
  if (type === 'daily') return d.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' });
  if (type === 'weekly') return 'Semaine ' + isoWeek(d)[1];
  if (type === 'monthly') return d.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  if (type === 'quarterly') return 'T' + (Math.floor(d.getMonth() / 3) + 1) + ' ' + d.getFullYear();
  return String(d.getFullYear());
}
const weekNo = () => isoWeek(new Date())[1];
const rkey = (id, per) => id + '@' + pkey(per);
const rdone = (t, per) => !!getP('routine', rkey(t.id, per));
function periodOf(sp, per) { return PG[sp].periods.find(p => p.key === per); }
function stats(sp, per) { const p = periodOf(sp, per), n = p.tasks.filter(t => rdone(t, per)).length; return { n, total: p.tasks.length }; }
function leftIn(sp, per) { const s = stats(sp, per); return s.total - s.n; }
function yearlyDue(sp) {
  const p = periodOf(sp, 'yearly'); if (!p.md) return true;
  const now = new Date(), t = new Date(now.getFullYear(), p.md[0] - 1, p.md[1]), diff = (now - t) / 864e5;
  return diff >= -14 && diff <= 30;
}
function dueFor(sp) {
  const R = S.rem[sp], now = new Date(), wd = now.getDay() || 7;
  const o = { daily: leftIn(sp, 'daily'), weekly: wd >= R.day ? leftIn(sp, 'weekly') : 0, monthly: now.getDate() <= 7 ? leftIn(sp, 'monthly') : 0,
    quarterly: (now.getMonth() % 3 === 0 && now.getDate() <= 14) ? leftIn(sp, 'quarterly') : 0, yearly: yearlyDue(sp) ? leftIn(sp, 'yearly') : 0 };
  o.total = o.daily + o.weekly + o.monthly + o.quarterly + o.yearly; return o;
}
function dueText(d) {
  const p = []; if (d.daily) p.push(d.daily + ' action' + (d.daily > 1 ? 's' : '') + ' du jour');
  if (d.weekly) p.push(d.weekly + ' de la semaine'); if (d.monthly) p.push(d.monthly + ' du mois');
  if (d.quarterly) p.push(d.quarterly + ' du trimestre'); if (d.yearly) p.push(d.yearly + ' de l\'année');
  return p.join(' · ');
}
function timePassed(sp) { const [h, m] = S.rem[sp].time.split(':').map(Number), n = new Date(); return n.getHours() * 60 + n.getMinutes() >= h * 60 + m; }
function bannerHTML(sp) {
  const R = S.rem[sp]; if (!R.on || !timePassed(sp)) return '';
  const d = dueFor(sp); if (!d.total) return '';
  const inProg = (S.tab[sp] || 'lib') === 'prog';
  const chip = (n, l) => n ? `<button class="bchip" data-act="tab" data-v="prog" title="Ouvrir mon programme">${n} ${l}</button>` : '';
  return `<div class="banner"><span><b>🔔 Rappel</b> · ${esc(dueText(d))}</span><div class="bchips">${inProg ? '' : chip(d.daily, 'du jour') + chip(d.weekly, 'semaine') + chip(d.monthly, 'mois')}</div>${inProg ? '' : '<button class="btn amber sm" data-act="tab" data-v="prog">Voir mon programme</button>'}</div>`;
}
/* éléments « du moment » */
const medOfDay = () => { const m = D.p1.filter(x => x.kind === 'meditation'); return m[Math.floor(Date.now() / 864e5) % m.length]; };
const modWeek = () => (weekNo() - 1) % 8 + 1;
const catsSorted = () => Object.values(D.tax.cats).sort((a, b) => a.order - b.order);
const catWeek = () => { const c = catsSorted(); return c[(weekNo() - 1) % c.length]; };
function cycleWeek() {
  if (!S.cycleStart) return 1;
  const w = Math.floor((Date.now() - new Date(S.cycleStart).getTime()) / (7 * 864e5)) + 1; return Math.min(5, Math.max(1, w));
}
function specialHTML(sp) {
  if (sp === 'P1') {
    const m = D.p1.find(x => x.id === 'p1-mod-' + modWeek()), md = medOfDay();
    return `<div class="special"><div class="sp-card"><h4>Module de la semaine</h4><p><b>${esc(m.title)}</b></p><button class="btn sm" data-act="task-go" data-go="mod">Étudier</button></div><div class="sp-card"><h4>Méditation du jour</h4><p><b>${esc(md.title)}</b><br><span class="hint">${esc(md.ref)}</span></p><button class="btn sm" data-act="task-go" data-go="med">Méditer</button></div></div>`;
  }
  if (isP(sp)) {
    const c = catWeek();
    return `<div class="special"><div class="sp-card"><h4>Catégorie de prière de la semaine</h4><p><b>${esc(c.name)}</b></p><button class="btn sm" data-act="task-go" data-go="cat2week">Voir les sujets</button></div><div class="sp-card"><h4>Rendez-vous du jour</h4><p>Culte familial et 15 minutes avec Dieu, prêts à l'emploi.</p><div class="actions" style="margin:0"><button class="btn sm" data-act="timer">⏱ 15 Min</button><button class="btn ghost sm" data-act="culte">🕯 Culte familial</button></div></div></div>`;
  }
  if (sp === 'P4') return '';
  const cw = cycleWeek(), cyc = PG.P3.cycle;
  return `<div class="panel"><div class="h-sec" style="margin-top:0"><h3>Cycle de formation · 5 semaines</h3><small>Semaine en cours : ${cw}</small></div>
  <table class="cyc"><tbody>${cyc.map(c => `<tr class="${c.w === cw ? 'now' : ''}"><td>Sem. ${c.w}</td><td><b>${esc(c.t)}</b><br><span class="hint">${esc(c.d)}</span></td><td><button class="btn ghost sm" data-act="task-go" data-go="item:${c.ids[0]}">Ouvrir</button></td></tr>`).join('')}</tbody></table>
  <div class="rem" style="margin-top:10px"><div><label class="f" for="cyc-start">Début de mon cycle</label><input type="date" id="cyc-start" value="${esc(S.cycleStart || '')}"></div></div><p class="hint">Place la semaine 5 en décembre. Sans date, la semaine 1 est affichée.</p></div>`;
}
function remHTML(sp) {
  const R = S.rem[sp];
  return `<div class="panel" style="margin:0"><h4>🔔 Rappels</h4><div class="rem"><label class="sw"><input type="checkbox" data-act="rem-on" ${R.on ? 'checked' : ''}> Rappels activés</label>
  <div><label class="f" for="rem-time">Heure du rappel</label><input type="time" id="rem-time" value="${esc(R.time)}"></div>
  <div><label class="f" for="rem-day">Jour du rappel hebdomadaire</label><select id="rem-day">${DAYS.slice(1).map((d, i) => `<option value="${i + 1}" ${R.day === i + 1 ? 'selected' : ''}>${d}</option>`).join('')}</select></div></div>
  <div class="actions"><button class="btn sm" data-act="rem-notif">Activer les notifications</button><button class="btn amber sm" data-act="rem-ics">📆 Ajouter à mon agenda (.ics)</button></div>
  <p class="hint">Les rappels apparaissent en bandeau et en notification quand l'application est ouverte. Pour être prévenue même application fermée, ajoute les rappels à l'agenda du téléphone (.ics) : alarme récurrente quotidienne, hebdomadaire, mensuelle, trimestrielle et annuelle.</p></div>`;
}
function taskHTML(t, per) {
  const on = rdone(t, per);
  return `<div class="task ${on ? 'on' : ''}"><input type="checkbox" id="t-${t.id}" data-act="rt" data-id="${t.id}" data-per="${per}" ${on ? 'checked' : ''} aria-label="${esc(t.t)}"><label for="t-${t.id}"><b>${esc(t.t)}</b>${t.mins ? `<span class="m">⏱ ${t.mins >= 60 ? (t.mins / 60) + ' h' : t.mins + ' min'}</span>` : ''}<span class="d">${esc(t.d)}</span></label>${t.go ? `<button class="btn ghost sm go" data-act="task-go" data-go="${esc(t.go)}">Ouvrir</button>` : ''}</div>`;
}
function periodHTML(sp, p) {
  const s = stats(sp, p.key), pct = Math.round(s.n / s.total * 100);
  const when = p.md ? ` · à planifier autour du ${p.md[1]} ${new Date(2000, p.md[0] - 1, 1).toLocaleDateString('fr-FR', { month: 'long' })}` : '';
  return `<section class="period" id="per-${p.key}"><header><span class="pi">${p.icon}</span><div><h4>${esc(p.label)} <small style="display:inline;font-weight:600">· ${esc(plabel(p.key))}</small></h4><small>${esc(p.intro)}${esc(when)}</small></div><div class="pr">${s.n} / ${s.total}<div class="bar-prog"><i style="width:${pct}%"></i></div></div></header>${p.tasks.map(t => taskHTML(t, p.key)).join('')}</section>`;
}
function programHTML(sp) {
  const P = PG[sp];
  return `<div class="pg-intro"><div class="orient"><h3>Orientation</h3><p>${esc(P.orientation)}</p></div>${remHTML(sp)}</div>${specialHTML(sp)}
  <div class="h-sec"><h3>Attitudes à adopter</h3></div><div class="attg">${P.attitudes.map(a => `<div class="att"><i>${a.i}</i><div><b>${esc(a.t)}</b><span>${esc(a.d)}</span></div></div>`).join('')}</div>
  <div class="h-sec"><h3>Mon programme</h3><small>Les cases se réinitialisent à chaque nouvelle période (jour, semaine, mois…).</small></div>${P.periods.map(p => periodHTML(sp, p)).join('')}`;
}
function taskGo(go) {
  const open = id => openDetail(id);
  if (go === 'med') return open(medOfDay().id);
  if (go === 'mod') return open('p1-mod-' + modWeek());
  if (go === 'timer') return openTimer();
  if (go === 'culte') return openCulte();
  if (go === 'carnet') return openCarnet();
  if (go === 'registre') return openRegistre();
  if (go === 'actu') return showActu();
  if (go.startsWith('item:')) return open(go.slice(5));
  if (go === 'cycle') return open(PG.P3.cycle[cycleWeek() - 1].ids[0]);
  if (go === 'quiz') { const q = D.p1.filter(x => x.kind === 'quiz'); return open(q[weekNo() % q.length].id); }
  if (go === 'lib2' || go === 'cat2week' || go === 'min2') {
    S.space = 'P2'; S.view = 'space'; S.tab.P2 = 'lib'; F.P2 = {}; shown = 24;
    if (go === 'cat2week') F.P2.cat = catWeek().name;
    if (go === 'min2') F.P2.grp = D.p2groups.MINISTER.name;
    saveS(); render();
    if (go === 'lib2') { const n = $('#name-in'); if (n) { n.scrollIntoView({ behavior: 'smooth', block: 'center' }); n.focus(); } }
  }
}
/* rappels */
function sendNotif(title, body) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  const fallback = () => { try { new Notification(title, { body, icon: 'icons/icon-192.png' }); } catch (e) { /* ignore */ } };
  if (navigator.serviceWorker && navigator.serviceWorker.getRegistration) navigator.serviceWorker.getRegistration().then(r => r ? r.showNotification(title, { body, icon: 'icons/icon-192.png', badge: 'icons/icon-192.png', tag: 'ec-' + title }) : fallback()).catch(fallback); else fallback();
}
function remindTick() {
  const today = pkey('daily');
  SPACES.forEach(sp => {
    const R = S.rem[sp]; if (!R.on || !timePassed(sp) || S.remSent[sp] === today) return;
    S.remSent[sp] = today; saveS();
    const d = dueFor(sp); if (!d.total) return;
    sendNotif(SP[sp].name, dueText(d)); toast('🔔 ' + SP[sp].name + ' : ' + dueText(d));
  });
}
function icsEsc(s) { return String(s).replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n'); }
function icsFor(sp) {
  const R = S.rem[sp], [h, m] = R.time.split(':').map(Number), now = new Date();
  const fmt = d => d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + 'T' + pad(h) + pad(m) + '00';
  const startToday = () => { const d = new Date(); d.setHours(h, m, 0, 0); if (d < now) d.setDate(d.getDate() + 1); return d; };
  const nextWeekday = () => { const d = startToday(); while ((d.getDay() || 7) !== R.day) d.setDate(d.getDate() + 1); return d; };
  const nextMonth1 = (step) => { const d = new Date(now.getFullYear(), now.getMonth() + 1, 1, h, m); if (step === 3) while (d.getMonth() % 3 !== 0) d.setMonth(d.getMonth() + 1); return d; };
  const rr = { daily: ['FREQ=DAILY', startToday()], weekly: ['FREQ=WEEKLY;BYDAY=' + ICSD[R.day], nextWeekday()], monthly: ['FREQ=MONTHLY;BYMONTHDAY=1', nextMonth1(1)], quarterly: ['FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=1', nextMonth1(3)] };
  const yp = periodOf(sp, 'yearly'), yd = new Date(now.getFullYear(), (yp.md || [12, 1])[0] - 1, (yp.md || [12, 1])[1], h, m); if (yd < now) yd.setFullYear(yd.getFullYear() + 1);
  rr.yearly = ['FREQ=YEARLY', yd];
  const L = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Ecosysteme Chretien//Rappels//FR', 'CALSCALE:GREGORIAN'];
  PG[sp].periods.forEach(p => {
    L.push('BEGIN:VEVENT', 'UID:' + sp + '-' + p.key + '@ecosysteme-chretien', 'DTSTAMP:' + fmt(now).replace(/T\d{6}$/, 'T000000') + 'Z', 'DTSTART:' + fmt(rr[p.key][1]), 'DURATION:PT30M', 'RRULE:' + rr[p.key][0],
      'SUMMARY:' + icsEsc(SP[sp].name + ' — ' + p.label), 'DESCRIPTION:' + icsEsc(p.tasks.map(t => '• ' + t.t).join('\n')),
      'BEGIN:VALARM', 'TRIGGER:PT0M', 'ACTION:DISPLAY', 'DESCRIPTION:' + icsEsc(SP[sp].name), 'END:VALARM', 'END:VEVENT');
  });
  L.push('END:VCALENDAR'); return L.join('\r\n');
}
/* vue globale */
const G = { q: '' };
function glCard(sp) {
  const P = PG[sp], d = periodOf(sp, 'daily'), s = stats(sp, 'daily'), pct = Math.round(s.n / s.total * 100);
  const next = d.tasks.filter(t => !rdone(t, 'daily')).slice(0, 3), read = items(sp).filter(i => getP(isP(sp) ? 'prayed' : 'read', i.id)).length;
  return `<article class="gl-card" style="--c:${SP_COL[sp]}"><h3>${esc(SP[sp].name)}</h3><p class="hint">${esc(SP[sp].tag)}</p>
  <div class="hint"><b>${s.n}/${s.total}</b> actions du jour · ${read}/${items(sp).length} ${isP(sp) ? 'sujets priés' : 'fiches lues'}</div><div class="bar-prog"><i style="width:${pct}%"></i></div>
  ${next.length ? '<ul>' + next.map(t => `<li>${esc(t.t)}</li>`).join('') + '</ul>' : '<p>✓ Programme du jour accompli.</p>'}
  <div class="actions" style="margin-top:6px"><button class="btn sm" data-act="gprog" data-v="${sp}">Programme du jour</button><button class="btn ghost sm" data-act="space" data-v="${sp}">Bibliothèque</button></div></article>`;
}
function renderGlobal() {
  $('#app').innerHTML = `<div class="gl-head"><h2>Vue globale transversale</h2><p class="hint">Un seul regard sur les cinq espaces : programme du jour, progression et recherche dans toutes les ressources.</p></div>
  <div class="panel"><label class="f" for="g-q">Rechercher dans les ${TOTAL} ressources des cinq espaces</label><input type="search" id="g-q" placeholder="Ex. : pardon, dîme, famille, Proverbes…" value="${esc(G.q)}" autocomplete="off"></div><div id="g-res"></div>
  <div class="h-sec"><h3>Aujourd'hui dans les cinq espaces</h3><small>${esc(plabel('daily'))}</small></div><div class="gl3">${SPACES.map(glCard).join('')}</div>`;
  renderGRes();
}
function renderGRes() {
  const box = $('#g-res'); if (!box) return;
  const q = norm(G.q.trim()); if (q.length < 2) { box.innerHTML = ''; return; }
  const all = SPACES.flatMap(sp => items(sp)).filter(it => hay(it).includes(q));
  box.innerHTML = `<div class="count">${all.length} résultat${all.length > 1 ? 's' : ''} <small>dans les cinq espaces</small></div><div class="grid" style="margin:10px 0 20px">${all.slice(0, 36).map(cardHTML).join('')}</div>${all.length > 36 ? '<p class="hint">Affine ta recherche pour voir les autres résultats.</p>' : ''}`;
}
function refreshAfter() { updateSide(); if (S.view === 'space' && (S.tab[S.space] || 'lib') === 'lib' && $('#list')) renderList(); else if (S.view === 'global') renderGRes(); }

/* ------------------------------------------------------------ actions */
function copy(t) {
  if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t).then(() => toast('Copié ✓'), () => toast('Copie impossible'));
  const ta = document.createElement('textarea'); ta.value = t; document.body.appendChild(ta); ta.select(); try { document.execCommand('copy'); toast('Copié ✓'); } catch (e) { toast('Copie impossible'); } ta.remove();
}
/* Partage : WhatsApp, Facebook, X (liens web) ; Instagram et TikTok n'ont pas de lien de partage web →
   le texte est copié puis l'application / le site s'ouvre pour coller. */
const SHARE_NETS = [
  { k: 'whatsapp', n: 'WhatsApp', c: '#25D366', ic: '💬' },
  { k: 'facebook', n: 'Facebook', c: '#1877F2', ic: '📘' },
  { k: 'x', n: 'X', c: '#000000', ic: '✖' },
  { k: 'instagram', n: 'Instagram', c: '#E4405F', ic: '📸', copyFirst: 'https://www.instagram.com/' },
  { k: 'tiktok', n: 'TikTok', c: '#010101', ic: '🎵', copyFirst: 'https://www.tiktok.com/upload' }
];
let SHARE = { title: '', text: '' };
function shareURL() { return location.protocol.startsWith('http') ? location.href.split('#')[0] : ''; }
function shareMsg() { const u = shareURL(); return (SHARE.text + (u ? '\n\n' + u : '')).trim(); }
function shareLink(k) {
  const msg = encodeURIComponent(shareMsg()), u = encodeURIComponent(shareURL()), t = encodeURIComponent(SHARE.text.slice(0, 240));
  if (k === 'whatsapp') return 'https://wa.me/?text=' + msg;
  if (k === 'facebook') return 'https://www.facebook.com/sharer/sharer.php?u=' + (u || encodeURIComponent('https://www.facebook.com/')) + '&quote=' + t;
  if (k === 'x') return 'https://twitter.com/intent/tweet?text=' + t + (u ? '&url=' + u : '');
  return '';
}
function share(title, text) {
  SHARE = { title, text: String(text || '') };
  closeShare();
  const box = document.createElement('div'); box.id = 'sharebox'; box.className = 'sharebox';
  box.innerHTML = `<div class="sharesheet" role="dialog" aria-label="Partager"><div class="sharehead"><b>Partager</b><button class="x" data-act="shareclose" aria-label="Fermer">✕</button></div>
  <p class="hint">${esc(title)}</p><div class="sharegrid">${SHARE_NETS.map(s => `<button class="sharebtn" style="--c:${s.c}" data-act="sharenet" data-v="${s.k}"><span>${s.ic}</span>${s.n}</button>`).join('')}
  <button class="sharebtn" data-act="sharecopy"><span>📋</span>Copier</button>${navigator.share ? '<button class="sharebtn" data-act="sharenative"><span>↗</span>Autres…</button>' : ''}</div></div>`;
  box.addEventListener('click', e => { if (e.target === box) closeShare(); });
  document.body.appendChild(box);
}
function closeShare() { const b = document.getElementById('sharebox'); if (b) b.remove(); }
function shareNet(k) {
  const s = SHARE_NETS.find(x => x.k === k); if (!s) return;
  if (s.copyFirst) { copy(shareMsg()); toast('Texte copié : colle-le dans ' + s.n + ' ✓'); window.open(s.copyFirst, '_blank', 'noopener'); }
  else window.open(shareLink(k), '_blank', 'noopener');
  closeShare();
}
function tipText(k) { const T = D.tips[S.space], arr = T[k], i = S.tipIdx[S.space] || 0; return arr[i % arr.length]; }
function download(name, text) { const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([text], { type: name.endsWith('.ics') ? 'text/calendar' : 'application/json' })); a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 2000); }

document.addEventListener('click', e => {
  const el = e.target.closest('[data-act]'); if (!el) { if (e.target.id === 'modal') closeModal(); return; }
  const act = el.dataset.act, v = el.dataset.v;
  if (act !== 'menu' && act !== 'chk' && act !== 'rt') document.body.classList.remove('menu');
  switch (act) {
    case 'size': S.text = +v; saveS(); applyText(); break;
    case 'home': S.view = 'home'; saveS(); render(); window.scrollTo({ top: 0, behavior: 'smooth' }); break;
    case 'space': setSpace(v); window.scrollTo({ top: 0, behavior: 'smooth' }); break;
    case 'menu': document.body.classList.toggle('menu'); break;
    case 'global': S.view = 'global'; saveS(); render(); window.scrollTo({ top: 0 }); break;
    case 'gprog': S.space = v; S.view = 'space'; S.tab[v] = 'prog'; saveS(); render(); window.scrollTo({ top: 0 }); break;
    case 'tab': S.tab[S.space] = v; saveS(); renderSpace(); break;
    case 'rail': { const r = $('#rail'); if (r) r.classList.toggle('open'); break; }
    case 'clearq': F[S.space].q = ''; F[S.space].qraw = ''; { const qi = $('#q-in'); if (qi) qi.value = ''; } shown = 24; renderFilters(); renderList(); break;
    case 'task-go': taskGo(el.dataset.go); break;
    case 'rem-notif': if (!('Notification' in window)) toast('Notifications non prises en charge sur ce navigateur.'); else Notification.requestPermission().then(p => toast(p === 'granted' ? 'Notifications activées ✓' : 'Notifications refusées : le bandeau de rappel reste actif.')); break;
    case 'rem-ics': download('rappels-' + S.space + '.ics', icsFor(S.space)); toast('Fichier agenda téléchargé : ouvre-le pour créer les rappels.'); break;
    case 'f': { const f = F[S.space], k = el.dataset.k; f[k] = v; const order = ['grp', 'cat', 'sub', 'ex']; order.slice(order.indexOf(k) + 1).forEach(x => f[x] = ''); shown = 24; renderFilters(); renderList(); break; }
    case 'reset': F[S.space] = {}; shown = 24; { const qi = $('#q-in'); if (qi) qi.value = ''; } renderFilters(); renderList(); break;
    case 'more': shown += 24; renderList(); break;
    case 'open': openDetail(el.dataset.id); break;
    case 'close': closeModal(); break;
    case 'shareclose': closeShare(); break;
    case 'sharenet': shareNet(v); break;
    case 'sharecopy': copy(shareMsg()); closeShare(); break;
    case 'sharenative': navigator.share({ title: SHARE.title, text: SHARE.text, url: shareURL() || undefined }).catch(() => { }); closeShare(); break;
    case 'tiptab': S.tipsTab = v; saveS(); $('.bar').outerHTML = barHTML(); break;
    case 'tiptoggle': S.tipsHidden = !S.tipsHidden; saveS(); $('.bar').outerHTML = barHTML(); break;
    case 'tipnext': S.tipIdx[S.space] = (S.tipIdx[S.space] || 0) + 1; saveS(); $('.bar').outerHTML = barHTML(); break;
    case 'tipcopy': copy(tipText(v)); break;
    case 'tipshare': share('Écosystème Chrétien', tipText(v)); break;
    case 'ver': case 'ver2': S.ver = v; saveS(); if (act === 'ver') toast(v === 'kid' ? 'Prières à la 1ʳᵉ personne (« je »)' : 'Prières à la 3ᵉ personne (« il / elle »)'); if (act === 'ver') { document.querySelectorAll('[data-act=ver]').forEach(b => b.setAttribute('aria-pressed', b.dataset.v === v)); renderList(); } else { openDetail(CUR.id); } break;
    case 'timer': openTimer(); break;
    case 'culte': openCulte(); break;
    case 'culte-new': openCulte(Math.floor(Math.random() * 1e9)); break;
    case 'culte-copy': copy($('.sheet-body').innerText); break;
    case 'tm-toggle': if (TM.run) { tmStop(); TM.left = Math.max(0, Math.ceil((TM.end - Date.now()) / 1000)); } else { TM.run = true; TM.end = Date.now() + TM.left * 1000; clearInterval(TM.iv); TM.iv = setInterval(tmTick, 500); } $('#tm-btn').textContent = TM.run ? 'Pause' : 'Démarrer'; break;
    case 'tm-next': tmStop(); TM.done[TM.step] = true; if (TM.step < 2) TM.step++; TM.left = 300; openTimer(); break;
    case 'tm-reset': tmStop(); Object.assign(TM, { step: 0, left: 300, done: [false, false, false] }); openTimer(); break;
    case 'tm-alt': TM.seed = Date.now(); $('#tm-body').innerHTML = timerContent(); break;
    case 'toggleread': { const k = isP(CUR.sp) ? 'prayed' : 'read', on = !getP(k, CUR.id); setP(k, CUR.id, on); const b = $('#readbtn'); b.className = 'btn ' + (on ? '' : 'ghost'); b.textContent = on ? '✓ ' + (isP(CUR.sp) ? 'Prié' : 'Lu / terminé') : (isP(CUR.sp) ? 'Marquer comme prié' : 'Marquer comme lu'); break; }
    case 'note': openCarnet(null, { title: isP(CUR.sp) ? 'Prière · ' + CUR.title : CUR.title, body: isP(CUR.sp) ? ptxt(p2text(CUR.raw)) : '' }); break;
    case 'copyitem': copy(itemText(CUR)); break;
    case 'shareitem': share(CUR.title, itemText(CUR)); break;
    case 'ans': { const q = CUR.raw.quiz[QZ.i]; QZ.ans = +el.dataset.i; if (QZ.ans === q.correct) QZ.score++; drawQuiz(); break; }
    case 'qnext': QZ.ans = null; QZ.i++; if (QZ.i >= CUR.raw.quiz.length) { QZ.done = true; setP('quiz', CUR.id, { score: QZ.score, total: CUR.raw.quiz.length }); setP('read', CUR.id, true); } drawQuiz(); break;
    case 'qretry': QZ = { i: 0, score: 0, ans: null, done: false }; drawQuiz(); break;
    case 'carnet': openCarnet(); break;
    case 'nf': notesFilter = v; openCarnet(); break;
    case 'nedit': openCarnet(el.dataset.id); break;
    case 'nstat': { const n = NOTES.find(x => x.id === el.dataset.id); n.status = STATUSES[(STATUSES.indexOf(n.status) + 1) % 3]; n.updated = Date.now(); saveN(); touch(); openCarnet(); break; }
    case 'ndel': if (confirm('Supprimer cette note ?')) { const n = NOTES.find(x => x.id === el.dataset.id); n.del = true; n.updated = Date.now(); saveN(); touch(); openCarnet(); } break;
    case 'profil': openModal(profilHTML()); break;
    case 'guide': openModal(guideHTML()); break;
    case 'about': document.body.classList.remove('menu'); openWide(window.aboutHTML()); break;
    case 'actu': openActu(); break;
    case 'feed-refresh': loadFeeds(true); break;
    case 'feed-pray': { const n = FEEDLIST[+el.dataset.i]; if (n) { NEWS.push({ id: 'nw-' + uid(), title: n.title, src: n.src, cat: 'Autre', pr: 'Seigneur, je te présente cette situation : ' + n.title, updated: Date.now(), del: false }); saveNews(); toast('Ajouté à mes actualités à prier ✓'); showActu(); } break; }
    case 'xdel': if (confirm('Supprimer cette actualité ?')) { const n = NEWS.find(x => x.id === el.dataset.id); n.del = true; n.updated = Date.now(); saveNews(); openActu(); } break;
    case 'xnote': { const n = NEWS.find(x => x.id === el.dataset.id); openCarnet(null, { title: 'Prière · ' + n.title, body: (n.pr || '') + (n.src ? '\n(Source : ' + n.src + ')' : '') }); break; }
    case 'registre': REG.cat = ($('#pq-cat') && $('#pq-cat').value) || REG.cat; openRegistre(); break;
    case 'padd-quick': {
      const box = $('#pq-name'), cat = $('#pq-cat').value, ls = box.value.split('\n').map(x => x.trim()).filter(Boolean);
      if (!ls.length) { toast('Écris au moins un nom et prénoms.'); break; }
      REG.cat = cat; const ids = [];
      ls.forEach(l => { const w = l.split(/\s+/); const before = PEOPLE.length; addPerson(w[0], w.slice(1).join(' ') || w[0], '', ($('#pq-sub') && !$('#pq-subbox').hidden) ? $('#pq-sub').value : ''); ids.push(PEOPLE[before].id); });
      const f = (S.focus && S.focus.cat === cat) ? S.focus : { cat, ids: [] }; S.focus = { cat, ids: [...new Set([...f.ids, ...ids])] };
      refreshPrayers(); toast(ls.length + ' personne(s) enregistrée(s) ✓ — prières personnalisées'); renderSpace(); break;
    }
    case 'pclear2': clearPrenom(); break;
    case 'pshow': showRubric(); break;
    case 'pedit': REG.edit = el.dataset.id; openRegistre(); break;
    case 'pcancel': REG.edit = null; openRegistre(); break;
    case 'pdel': if (confirm('Retirer cette personne du registre ?')) { const p = PEOPLE.find(x => x.id === el.dataset.id); p.del = true; p.updated = Date.now(); if (S.focus) S.focus.ids = S.focus.ids.filter(i => i !== p.id); refreshPrayers(); openRegistre(); } break;
    case 'pall': { const ids = peopleOf(REG.cat).map(p => p.id); S.focus = { cat: REG.cat, ids: v === '1' ? ids : [] }; refreshPrayers(); openRegistre(); break; }
    case 'papply': { const f = S.focus; if (!f.cat || !peopleOf(f.cat).some(p => f.ids.includes(p.id))) { toast("Coche d'abord au moins une personne."); break; } refreshPrayers(); toast('Prières personnalisées ✓'); closeModal(); break; }
    case 'pclear': S.focus = { cat: '', ids: [] }; refreshPrayers(); openRegistre(); break;
    case 'pbulk': { const lines = $('#pp-bulk').value.split('\n').map(x => x.trim()).filter(Boolean); lines.forEach(l => { const w = l.split(/\s+/); addPerson(w[0], w.slice(1).join(' ') || w[0]); }); if (lines.length) { refreshPrayers(); toast(lines.length + ' personne(s) ajoutée(s) ✓'); } openRegistre(); break; }
    case 'theme': { const d = document.documentElement, dark = d.dataset.theme === 'dark' || (!d.dataset.theme && matchMedia('(prefers-color-scheme: dark)').matches); d.dataset.theme = dark ? 'light' : 'dark'; store.set('ec5_theme', d.dataset.theme); break; }
    case 'install': if (deferredInstall) { deferredInstall.prompt(); deferredInstall = null; } break;
    case 'newcard': openModal(cardForm(null, S.space)); break;
    case 'editcard': openModal(cardForm(CARDS.find(c => c.id === el.dataset.id), S.space)); break;
    case 'delcard': if (confirm('Supprimer cette fiche ?')) { const c = CARDS.find(x => x.id === el.dataset.id); c.del = true; c.updated = Date.now(); saveC(); touch(); closeModal(); renderFilters(); renderList(); } break;
    case 'open-sync': document.body.classList.remove('menu'); openSync(); break;
    case 'sync-now': syncNow(true); break;
    case 'sb-save': { const nu = $('#sb-url').value.trim(), nk = $('#sb-key').value.trim(); if (isSecretKey(nk)) { toast('Clé refusée : une clé « service_role » / secrète ne doit jamais être saisie ici. Utilise la clé « anon » publique.'); break; } if (nu !== SY.url || nk !== SY.key) SY.auth = null; SY.url = nu; SY.key = nk; } saveY(); setStatus('none'); syncNow(true); break;
    case 'sb-in': authEmail(false); break;
    case 'sb-up': authEmail(true); break;
    case 'sb-out': SY.auth = null; saveY(); toast('Déconnectée'); openSync(); break;
    case 'exp': download('ecosysteme-chretien-' + new Date().toISOString().slice(0, 10) + '.json', JSON.stringify(dump(), null, 1)); break;
    case 'snap': addSnapshot('Point manuel'); openSync(); break;
    case 'snap-del': store.set(K.R, snapshots().filter(s => s.id !== el.dataset.id)); openSync(); break;
    case 'snap-restore': { const s = snapshots().find(x => x.id === el.dataset.id); if (s && confirm('Restaurer ce point ? Les données actuelles seront d\'abord sauvegardées.')) { addSnapshot('Avant restauration'); PR = Object.assign(PRDEF(), s.data.progress); NOTES = s.data.notes || []; CARDS = s.data.cards || []; PEOPLE = s.data.people || []; savePeople(); saveP(); saveN(); saveC(); toast('Point restauré ✓'); touch(); renderFilters(); renderList(); openSync(); } break; }
    case 'chk': break;
  }
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && $('#modal').classList.contains('open')) closeModal();
  if ((e.key === 'Enter' || e.key === ' ') && e.target.matches('.card[data-act=open]')) { e.preventDefault(); openDetail(e.target.dataset.id); }
});
document.addEventListener('change', e => {
  const t = e.target;
  if (t.id === 'feed-src') { S.feedSrc = t.value; saveS(); loadFeeds(false); }
  else if (t.id === 'reg-cat') { REG.cat = t.value; REG.edit = null; openRegistre(); }
  else if (t.id === 'pq-cat') { REG.cat = t.value; REG.sub = ''; const sb = $('#pq-subbox'); if (sb) { sb.hidden = !PCATS[REG.cat].subs; $('#pq-sub').innerHTML = subOptions(REG.cat, ''); } }
  else if (t.id === 'pq-sub') { REG.sub = t.value; }
  else if (t.matches('input[data-act=pchk]')) { const f = S.focus = (S.focus && S.focus.cat === REG.cat) ? S.focus : { cat: REG.cat, ids: [] }; f.ids = t.checked ? [...new Set([...f.ids, t.dataset.id])] : f.ids.filter(i => i !== t.dataset.id); refreshPrayers(); }
  else if (t.matches('select[data-k]')) { const f = F[S.space], k = t.dataset.k, order = ['grp', 'cat', 'sub', 'ex']; f[k] = t.value; order.slice(order.indexOf(k) + 1).forEach(x => f[x] = ''); shown = 24; renderFilters(); renderList(); }
  else if (t.matches('input[data-act=rt]')) { const sp = S.space, per = t.dataset.per, task = periodOf(sp, per).tasks.find(x => x.id === t.dataset.id); setP('routine', rkey(task.id, per), t.checked); const old = $('#per-' + per); if (old) old.outerHTML = periodHTML(sp, periodOf(sp, per)); }
  else if (t.matches('input[data-act=rem-on]')) { S.rem[S.space].on = t.checked; saveS(); }
  else if (t.id === 'rem-day') { S.rem[S.space].day = +t.value; saveS(); }
  else if (t.id === 'cyc-start') { S.cycleStart = t.value; saveS(); renderSpace(); }
  else if (t.matches('input[data-act=chk]')) { const kind = t.dataset.kind, arr = kind === 'steps' ? CUR.raw.steps : CUR.raw.checklist, st = Object.assign({}, getP(kind, CUR.id) || {}); st[t.dataset.i] = t.checked; setP(kind, CUR.id, st); if (Object.values(st).filter(Boolean).length === arr.length) setP('read', CUR.id, true); drawChecks(kind, arr, kind === 'steps'); }
  else if (t.id === 'imp' && t.files[0]) { const fr = new FileReader(); fr.onload = () => { try { addSnapshot('Avant import'); mergeIn(JSON.parse(fr.result)); toast('Import réussi ✓'); touch(); renderFilters(); renderList(); openSync(); } catch (er) { toast('Import impossible : ' + er.message); } }; fr.readAsText(t.files[0]); }
});
document.addEventListener('input', e => {
  const t = e.target;
  if (t.id === 'rem-time' && t.value) { S.rem[S.space].time = t.value; saveS(); }
  else if (t.id === 'g-q') { G.q = t.value; renderGRes(); }
  else if (t.id === 'q-in') { F[S.space].qraw = t.value; F[S.space].q = norm(t.value.trim()); shown = 24; renderFilters(); renderList(); }
  else if (t.id === 'name-in' || t.id === 'd-name' || t.id === 'p-name') {
    S.name = t.value; saveS();
    ['name-in', 'd-name', 'p-name'].forEach(id => { const o = $('#' + id); if (o && o !== t) o.value = S.name; });
    if (CUR && $('#pray')) $('#pray').innerHTML = phtml(p2text(CUR.raw));
    if (!$('#modal').classList.contains('open') && S.view === 'space' && isP(S.space) && $('#list')) renderList();
  }
});
document.addEventListener('submit', e => {
  const f = e.target;
  if (f.id === 'news-form') {
    e.preventDefault(); const t = $('#nw-title').value.trim(); if (!t) return;
    NEWS.push({ id: 'nw-' + uid(), title: t, src: $('#nw-src').value.trim(), cat: $('#nw-cat').value, pr: $('#nw-pr').value.trim(), updated: Date.now(), del: false });
    saveNews(); toast('Actualité ajoutée ✓'); openActu();
  } else if (f.id === 'people-form') {
    e.preventDefault(); const id = f.dataset.id, o = { last: $('#pp-last').value.trim(), first: $('#pp-first').value.trim(), note: $('#pp-note').value.trim(), sub: $('#pp-sub') ? $('#pp-sub').value : '', updated: Date.now() };
    if (!o.last || !o.first) return;
    if (id) Object.assign(PEOPLE.find(p => p.id === id), o); else addPerson(o.last, o.first, o.note, o.sub);
    REG.edit = null; refreshPrayers(); toast('Enregistré ✓'); openRegistre();
  } else if (f.id === 'note-form') {
    e.preventDefault(); const id = f.dataset.id, o = { title: $('#n-title').value.trim(), body: $('#n-body').value, status: $('#n-status').value, updated: Date.now() };
    if (!o.title) return;
    if (id) Object.assign(NOTES.find(n => n.id === id), o); else NOTES.push(Object.assign({ id: uid(), created: Date.now(), del: false }, o));
    saveN(); touch(); toast('Note enregistrée ✓'); openCarnet();
  } else if (f.id === 'card-form') {
    e.preventDefault(); const id = f.dataset.id, o = { title: $('#c-title').value.trim(), text: $('#c-text').value, sub: $('#c-sub').value.trim(), updated: Date.now() };
    if (id) Object.assign(CARDS.find(c => c.id === id), o); else CARDS.push(Object.assign({ id: 'perso-' + uid(), sp: $('#c-sp').value, del: false }, o));
    saveC(); touch(); closeModal(); renderFilters(); renderList(); toast('Fiche enregistrée ✓');
  }
});
function applyText() {
  document.documentElement.dataset.text = S.text;
  document.querySelectorAll('.sz button').forEach(b => b.setAttribute('aria-pressed', +b.dataset.v === S.text));
}

/* ------------------------------------------------------------ v6 : bannières, trois cartes, programme annuel, capsules vidéo, flux JSON */
const IMGS = CFG.IMAGES || {};
function illus(kind) {
  const defs = (id, a, b) => `<defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs>`;
  if (kind === 'anim') return `<svg viewBox="0 0 1200 340" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Scène, micro et livre ouvert">${defs('anA', '#0F766E', '#F59E0B')}<rect width="1200" height="340" fill="url(#anA)"/><circle cx="930" cy="150" r="150" fill="#fff" fill-opacity=".14"/><rect x="912" y="70" width="36" height="80" rx="18" fill="#fff"/><path d="M890 130c0 30 20 46 40 46s40-16 40-46M930 176v50M900 228h60" fill="none" stroke="#fff" stroke-width="8" stroke-linecap="round"/><path d="M720 210c36-14 66-12 82 8 16-20 46-22 82-8v70c-36-14-66-12-82 8-16-20-46-22-82-8z" fill="#FFF6E0" fill-opacity=".95"/><g fill="#fff" fill-opacity=".5"><circle cx="150" cy="70" r="3"/><circle cx="330" cy="140" r="2.4"/><circle cx="500" cy="60" r="3"/></g></svg>`;
  if (kind === 'prog') {
    const cells = Array.from({ length: 12 }, (_, i) => { const x = 620 + (i % 4) * 92, y = 80 + Math.floor(i / 4) * 78; return `<rect x="${x}" y="${y}" width="76" height="62" rx="12" fill="#fff" fill-opacity="${i % 5 === 0 ? '.95' : '.55'}"/>${i % 3 === 0 ? `<path d="M${x + 22} ${y + 32}l12 12 22-26" fill="none" stroke="#059669" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>` : ''}`; }).join('');
    return `<svg viewBox="0 0 1200 340" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Calendrier annuel d'activités">${defs('pgA', '#0369A1', '#10B981')}<rect width="1200" height="340" fill="url(#pgA)"/><circle cx="1090" cy="70" r="46" fill="#FFE9B8"/><circle cx="1090" cy="70" r="72" fill="#fff" fill-opacity=".16"/>${cells}<g fill="#fff" fill-opacity=".5"><circle cx="120" cy="70" r="3"/><circle cx="300" cy="140" r="2.4"/><circle cx="470" cy="60" r="3"/></g></svg>`;
  }
  if (kind === 'videos') {
    return `<svg viewBox="0 0 1200 340" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Lecteur vidéo lumineux">${defs('vdA', '#312E81', '#DB2777')}<rect width="1200" height="340" fill="url(#vdA)"/><g stroke="#fff" stroke-opacity=".22" stroke-width="5" stroke-linecap="round">${Array.from({ length: 16 }, (_, i) => { const a = i / 16 * Math.PI * 2; return `<line x1="${900 + Math.cos(a) * 120}" y1="${170 + Math.sin(a) * 120}" x2="${900 + Math.cos(a) * 200}" y2="${170 + Math.sin(a) * 200}"/>`; }).join('')}</g><rect x="740" y="90" width="320" height="180" rx="26" fill="#fff" fill-opacity=".92"/><path d="M866 140l70 40-70 40z" fill="#DB2777"/><rect x="770" y="288" width="260" height="10" rx="5" fill="#fff" fill-opacity=".5"/><rect x="770" y="288" width="110" height="10" rx="5" fill="#FDE68A"/></svg>`;
  }
  return `<svg viewBox="0 0 1200 340" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Page d'actualités et lumière">${defs('acA', '#92400E', '#F59E0B')}<rect width="1200" height="340" fill="url(#acA)"/><circle cx="930" cy="150" r="190" fill="#FFE7A8" fill-opacity=".25"/><rect x="760" y="70" width="330" height="210" rx="18" fill="#FFF8E7"/><rect x="784" y="96" width="120" height="86" rx="8" fill="#F59E0B" fill-opacity=".6"/><g fill="#B45309" fill-opacity=".55"><rect x="920" y="100" width="150" height="10" rx="5"/><rect x="920" y="124" width="130" height="10" rx="5"/><rect x="920" y="148" width="150" height="10" rx="5"/><rect x="784" y="200" width="286" height="10" rx="5"/><rect x="784" y="224" width="240" height="10" rx="5"/></g></svg>`;
}
window.__illus = illus;
function banner(kind, title, sub) {
  const url = IMGS[kind];
  const art = url ? `<img src="${esc(url)}" alt="" loading="lazy" onerror="this.outerHTML=window.__illus('${kind}')">` : illus(kind);
  return `<section class="mbanner"><div class="art">${art}</div><div class="mb-body"><h3>${esc(title)}</h3><p>${esc(sub)}</p></div></section>`;
}
const MODTIPS = {
  anim: {
    advice: ["Choisis le thème et le passage biblique d'abord, puis le format (poème, sketch, slam, jeu).", "Répète une fois avant de présenter ; trois minutes bien préparées valent mieux qu'un long passage improvisé.", "Mélange les formats : un poème pour ouvrir, un sketch pour illustrer, un jeu pour s'amuser."],
    alert: ["Aucun jeu ni sketch ne doit humilier, moquer ou mettre mal à l'aise un participant.", "Vérifie que le texte reste fidèle au passage biblique cité.", "Au moins deux adultes responsables pour les activités avec des mineurs."],
    reco: ["Adapte la durée et le vocabulaire à l'âge du groupe.", "Invite les jeunes à écrire eux-mêmes leurs poèmes et leurs slams.", "Termine chaque animation par un verset et une question de réflexion."]
  },
  prog: {
    advice: ["Fixe les dates des retraites, du camp et du forum dès janvier ; le tableau se modifie d'un simple clic sur une cellule.", "Duplique le programme chaque fin d'année : tu gardes la structure et tu ajustes les thèmes.", "Associe un verset et un objectif pédagogique précis à chaque activité."],
    alert: ["Au moins deux adultes responsables pour toute activité avec des mineurs ; accord écrit des parents pour les sorties et les photos.", "Ne note jamais la foi ni la prière : on observe seulement les attitudes visibles et le service.", "Pense à l'assurance, au budget et à une personne référente pour la protection avant chaque camp."],
    reco: ["Évalue chaque trimestre avec les jeunes : ce qui porte du fruit, ce qu'on arrête.", "Alterne temps spirituels (retraite, étude) et temps fraternels (sortie, atelier de talents).", "Exporte le programme en JSON ou imprime-le pour le partager avec le pasteur et les parents."]
  },
  videos: {
    advice: ["Une capsule de 3 à 5 minutes suivie de deux questions suffit pour lancer un échange.", "Visionne toujours la vidéo en entier avant de la proposer à un groupe.", "Classe tes capsules par thème : jeunesse, prière, réseaux sociaux, famille, engagement."],
    alert: ["Vérifie la doctrine et la source : une vidéo populaire n'est pas forcément fidèle à la Bible.", "Ne publie jamais de vidéos montrant des mineurs sans l'accord écrit des parents.", "Les lecteurs externes (YouTube) peuvent afficher des publicités ou des suggestions : prévois un adulte pour animer."],
    reco: ["Privilégie les vidéos de ton Église ou de ministères que ton pasteur connaît.", "Ajoute un lien MP4 hébergé par ton Église pour un visionnage sans publicité.", "Termine chaque capsule par un verset et un engagement concret pour la semaine."]
  },
  actu: {
    advice: ["Lis l'actualité avec la Parole : une nouvelle, un verset, une prière.", "Ajoute les sujets de ton quartier dans « Mes actualités à porter dans la prière ».", "Prie en famille ou en groupe une fois par semaine pour un sujet d'actualité."],
    alert: ["Vérifie la source et la date avant de partager : une information peut être fausse ou déformée.", "Évite la rumeur, la peur et les jugements hâtifs ; ne prie pas contre des personnes, prie pour elles.", "Les liens externes ne sont pas contrôlés par l'application : garde ton discernement."],
    reco: ["Programme un moment fixe et court (15 à 20 minutes) pour l'actualité, une fois par jour au plus.", "Remplace une heure de défilement par un temps de prière et de lecture biblique.", "Note les réponses de Dieu dans le Carnet privé."]
  }
};
function tips3HTML(k) {
  const T = MODTIPS[k], i = dayIndex(), pick = a => a[i % a.length];
  return '<div class="cards3" style="margin:14px 0">' + [['e', '💡', 'Conseil pratique', T.advice], ['a', '⚠️', 'Point de Vigilance & Alerte', T.alert], ['i', '⭐', 'Recommandation', T.reco]]
    .map(([c, ic, t, a]) => `<article class="tip ${c} in-detail"><span class="ico">${ic}</span><h4>${t}</h4><p>${esc(pick(a))}</p></article>`).join('') + '</div>';
}
const openWide = html => { openModal(html); const sh = $('#modal .sheet'); if (sh) sh.classList.add('wide'); };

/* ---------- Programme annuel d'activités — Jeune Fille & Jeunesse */
const PGS = { year: +S.progYear || new Date().getFullYear() };
const PGT = "Programme annuel d'activités — Jeune Fille & Jeunesse";
function progRows(y) {
  const e = PR.prog && PR.prog[y];
  if (e && Array.isArray(e.v)) return e.v;
  return PROG_TEMPLATE.map((r, i) => ({ id: 'r' + i, m: PROG_MONTHS[i], pole: r[0], theme: r[1], act: r[2], obj: r[3], resp: r[4], st: 'Planifié' }));
}
function progYears() {
  const y0 = new Date().getFullYear(), ys = new Set([y0, y0 + 1, y0 + 2, PGS.year]);
  Object.keys(PR.prog || {}).forEach(k => { if (/^\d{4}$/.test(k) && PR.prog[k] && Array.isArray(PR.prog[k].v)) ys.add(+k); });
  return [...ys].sort((a, b) => a - b);
}
const progSave = rows => setP('prog', String(PGS.year), rows);
function progSet(i, key, val) { const rows = progRows(PGS.year); if (!rows[i] || rows[i][key] === val) return; rows[i][key] = val; progSave(rows); }
function progTable(rows) {
  const sel = (key, i, val, opts, cls) => { const list = !val || opts.includes(val) ? opts : [val, ...opts]; return `<select class="${cls || ''}" data-pg="${key}" data-i="${i}" aria-label="${key}">${list.map(o => `<option ${o === val ? 'selected' : ''}>${esc(o)}</option>`).join('')}</select>`; };
  const cell = (key, i, v) => `<td contenteditable="true" spellcheck="true" data-pg="${key}" data-i="${i}">${esc(v)}</td>`;
  return `<div class="tbl-wrap"><table class="cmp prog-tbl"><thead><tr><th>Mois / Période</th><th>Pôle cible</th><th>Thème spirituel &amp; Verset</th><th>Activité principale</th><th>Objectif pédagogique</th><th>Responsable</th><th>Statut</th><th><span class="sr">Supprimer</span></th></tr></thead><tbody>` +
    rows.map((r, i) => `<tr>${cell('m', i, r.m)}<td>${sel('pole', i, r.pole, PROG_POLES)}</td>${cell('theme', i, r.theme)}<td>${sel('act', i, r.act, PROG_ACTS)}</td>${cell('obj', i, r.obj)}${cell('resp', i, r.resp)}<td>${sel('st', i, r.st, PROG_STATUS, 'st s' + Math.max(0, PROG_STATUS.indexOf(r.st)))}</td><td><button class="btn danger sm" data-act="pg-del" data-i="${i}" aria-label="Supprimer la ligne ${esc(r.m)}">✕</button></td></tr>`).join('') +
    '</tbody></table></div>';
}
function progStats(rows) {
  const cnt = PROG_STATUS.map(s => rows.filter(r => r.st === s).length), pct = rows.length ? Math.round(cnt[2] / rows.length * 100) : 0;
  return `<div class="chips">${PROG_STATUS.map((s, i) => `<span class="badge st-b s${i}">${s} : ${cnt[i]}</span>`).join('')}<span class="badge">${rows.length} ligne(s)</span></div><div class="bar-prog" aria-label="Avancement"><i style="width:${pct}%"></i></div><p class="hint">${pct} % réalisé pour ${PGS.year}</p>`;
}
function progBody() {
  const y = PGS.year, rows = progRows(y);
  return banner('prog', PGT, 'Un calendrier de douze mois, modifiable et actualisable chaque année : thèmes, activités, objectifs, responsables et suivi.') +
    tips3HTML('prog') +
    `<div class="pg-bar"><label class="ddf"><span>Année</span><select id="pg-year">${progYears().map(x => `<option ${x === y ? 'selected' : ''}>${x}</option>`).join('')}</select></label>
    <button class="btn amber sm" data-act="pg-dup">＋ Dupliquer et actualiser pour la nouvelle année (${y + 1})</button>
    <button class="btn ghost sm" data-act="pg-add">＋ Ajouter une ligne</button><button class="btn ghost sm" data-act="pg-export">Exporter (JSON)</button><label class="btn ghost sm" style="cursor:pointer">Importer<input type="file" id="pg-imp" accept="application/json,.json" hidden></label><button class="btn ghost sm" data-act="pg-print">Imprimer</button><button class="btn ghost sm" data-act="pg-reset">Rétablir le modèle</button></div>
    <div id="pg-stats">${progStats(rows)}</div>
    <p class="hint">Clique sur une cellule pour la modifier : l'enregistrement est automatique (sur cet appareil et, si activé, dans le cloud). Entrée valide la cellule.</p>
    <div id="pg-table">${progTable(rows)}</div>`;
}
const progHTML = () => head(esc(PGT)) + `<div class="sheet-body" id="pg-wrap">${progBody()}</div>`;
const progRefresh = () => { const w = $('#pg-wrap'); if (w) w.innerHTML = progBody(); };
function openProg() { openWide(progHTML()); }
function progPrint() {
  const y = PGS.year, rows = progRows(y);
  let pa = $('#printarea'); if (!pa) { pa = document.createElement('div'); pa.id = 'printarea'; document.body.appendChild(pa); }
  pa.innerHTML = `<h1>${esc(PGT)} · ${y}</h1><table><thead><tr><th>Mois</th><th>Pôle cible</th><th>Thème &amp; verset</th><th>Activité</th><th>Objectif pédagogique</th><th>Responsable</th><th>Statut</th></tr></thead><tbody>${rows.map(r => `<tr><td>${esc(r.m)}</td><td>${esc(r.pole)}</td><td>${esc(r.theme)}</td><td>${esc(r.act)}</td><td>${esc(r.obj)}</td><td>${esc(r.resp)}</td><td>${esc(r.st)}</td></tr>`).join('')}</tbody></table><p>Écosystème Chrétien · Textes bibliques : Louis Segond 1910</p>`;
  document.body.classList.add('printing');
  const done = () => { document.body.classList.remove('printing'); window.removeEventListener('afterprint', done); };
  window.addEventListener('afterprint', done); window.print();
}
document.addEventListener('focusout', e => { const t = e.target; if (t.matches && t.matches('td[data-pg]')) progSet(+t.dataset.i, t.dataset.pg, t.textContent.replace(/\s+/g, ' ').trim()); });
document.addEventListener('keydown', e => { if (e.key === 'Enter' && e.target.matches && e.target.matches('td[data-pg]')) { e.preventDefault(); e.target.blur(); } });
document.addEventListener('paste', e => { if (e.target.matches && e.target.matches('td[data-pg]')) { e.preventDefault(); document.execCommand('insertText', false, ((e.clipboardData || window.clipboardData).getData('text') || '').replace(/\s+/g, ' ')); } });
document.addEventListener('change', e => {
  const t = e.target;
  if (t.id === 'pg-year') { PGS.year = +t.value; S.progYear = PGS.year; saveS(); progRefresh(); }
  else if (t.matches && t.matches('select[data-pg]')) { progSet(+t.dataset.i, t.dataset.pg, t.value); if (t.dataset.pg === 'st') { t.className = 'st s' + PROG_STATUS.indexOf(t.value); $('#pg-stats').innerHTML = progStats(progRows(PGS.year)); } }
  else if (t.id === 'pg-imp' && t.files[0]) {
    const fr = new FileReader();
    fr.onload = () => { try { const j = JSON.parse(fr.result); if (!j || !Array.isArray(j.rows)) throw new Error('fichier non reconnu'); const y = +j.year || PGS.year; PGS.year = y; progSave(j.rows.map((r, i) => ({ id: 'r' + Date.now() + i, m: String(r.m || ''), pole: String(r.pole || ''), theme: String(r.theme || ''), act: String(r.act || ''), obj: String(r.obj || ''), resp: String(r.resp || ''), st: PROG_STATUS.includes(r.st) ? r.st : 'Planifié' }))); S.progYear = y; saveS(); progRefresh(); toast('Programme ' + y + ' importé ✓'); } catch (er) { toast('Import impossible : ' + er.message); } };
    fr.readAsText(t.files[0]);
  }
});

/* ---------- Capsules vidéo de sensibilisation */
const VG = { theme: '', edit: '' };
const vidList = () => { const e = PR.vids && PR.vids.list; return e && Array.isArray(e.v) ? e.v : VIDEO_SEED.map(v => Object.assign({}, v)); };
const vidSave = a => setP('vids', 'list', a);
function vidParse(u) {
  u = String(u || '').trim(); if (!/^https?:\/\//i.test(u)) return null;
  const m = /(?:youtu\.be\/|youtube\.com\/(?:watch\?(?:[^#]*&)?v=|embed\/|shorts\/|live\/)|youtube-nocookie\.com\/embed\/)([\w-]{11})/i.exec(u);
  if (m) return { type: 'yt', id: m[1] };
  if (/\.(mp4|webm|ogv)(\?|#|$)/i.test(u)) return { type: 'file', url: u };
  return { type: 'link', url: u };
}
const PLAYSVG = '<svg viewBox="0 0 64 64" aria-hidden="true"><circle cx="32" cy="32" r="30" fill="#fff" fill-opacity=".92"/><path d="M26 20l20 12-20 12z" fill="#DB2777"/></svg>';
function vidPlayer(v) {
  const p = vidParse(v.url);
  if (!p) return `<div class="vthumb empty"><span>Aucun lien pour le moment</span><a class="btn ghost sm" href="https://www.youtube.com/results?search_query=${encodeURIComponent(v.title + ' ' + v.theme)}" target="_blank" rel="noopener noreferrer">Chercher sur YouTube</a></div>`;
  if (p.type === 'yt') return `<button class="vthumb" data-act="vd-play" data-id="${esc(v.id)}" aria-label="Lire : ${esc(v.title)}"><img src="https://i.ytimg.com/vi/${p.id}/hqdefault.jpg" alt="" loading="lazy" onerror="this.remove()">${PLAYSVG}</button>`;
  if (p.type === 'file') return `<button class="vthumb" data-act="vd-play" data-id="${esc(v.id)}" aria-label="Lire : ${esc(v.title)}"><span class="vt">MP4</span>${PLAYSVG}</button>`;
  return `<a class="vthumb" href="${esc(p.url)}" target="_blank" rel="noopener noreferrer"><span class="vt">Lien externe</span>${PLAYSVG}</a>`;
}
function vidBody() {
  const list = vidList(), themes = VIDEO_THEMES, shown2 = list.filter(v => !VG.theme || v.theme === VG.theme), e = VG.edit ? list.find(v => v.id === VG.edit) : null;
  const chip = (v, l, n) => `<button class="chip" data-act="vd-theme" data-v="${esc(v)}" aria-pressed="${VG.theme === v}">${esc(l)} <small>${n}</small></button>`;
  return banner('videos', 'Capsules Vidéo de Sensibilisation', 'Petites vidéos pour éveiller, former et encourager : jeunesse, prière, réseaux sociaux, famille et engagement chrétien.') +
    tips3HTML('videos') +
    `<div class="chips" style="margin:6px 0 12px">${chip('', 'Toutes', list.length)}${themes.map(t => chip(t, t, list.filter(v => v.theme === t).length)).join('')}</div>
    <div class="vgrid">${shown2.length ? shown2.map(v => `<article class="vid"><div class="vp" id="vp-${esc(v.id)}">${vidPlayer(v)}</div><div class="vbody"><span class="badge">${esc(v.theme)}</span><h4>${esc(v.title)}</h4>${v.desc ? `<p class="hint">${esc(v.desc)}</p>` : ''}<div class="actions" style="margin-top:4px"><button class="btn ghost sm" data-act="vd-edit" data-id="${esc(v.id)}">Modifier</button><button class="btn danger sm" data-act="vd-del" data-id="${esc(v.id)}">Supprimer</button></div></div></article>`).join('') : '<div class="empty" style="grid-column:1/-1">Aucune capsule dans ce thème.</div>'}</div>
    <details class="bulk" id="vd-manage" ${e ? 'open' : ''}><summary>Gérer les capsules : ajouter, modifier, actualiser un lien</summary>
    <form id="vid-form" data-id="${e ? esc(e.id) : ''}"><label class="f" for="v-title">Titre</label><input type="text" id="v-title" required maxlength="120" value="${esc(e ? e.title : '')}" placeholder="Ex. : Garder son cœur">
    <div class="two"><div><label class="f" for="v-theme">Thème</label><select id="v-theme">${themes.map(t => `<option ${e && e.theme === t ? 'selected' : ''}>${esc(t)}</option>`).join('')}</select></div>
    <div><label class="f" for="v-url">Lien YouTube ou fichier MP4</label><input type="url" id="v-url" maxlength="400" value="${esc(e ? e.url : '')}" placeholder="https://www.youtube.com/watch?v=…  ou  https://…/video.mp4"></div></div>
    <label class="f" for="v-desc" style="margin-top:8px">Description (facultatif)</label><input type="text" id="v-desc" maxlength="200" value="${esc(e ? e.desc || '' : '')}">
    <div class="actions"><button class="btn" type="submit">${e ? 'Enregistrer la capsule' : '＋ Ajouter la capsule'}</button>${e ? '<button class="btn ghost" type="button" data-act="vd-cancel">Annuler</button>' : ''}<button class="btn ghost" type="button" data-act="vd-export">Exporter (JSON)</button><label class="btn ghost" style="cursor:pointer">Importer<input type="file" id="vd-imp" accept="application/json,.json" hidden></label><button class="btn ghost" type="button" data-act="vd-reset">Rétablir les capsules d'origine</button></div>
    <p class="hint">Les liens sont enregistrés sur cet appareil (et dans le cloud si activé). Seuls les liens commençant par https:// sont acceptés.</p></form></details>`;
}
const vidHTML = () => head('Capsules Vidéo de Sensibilisation') + `<div class="sheet-body" id="vd-wrap">${vidBody()}</div>`;
const vidRefresh = () => { const w = $('#vd-wrap'); if (w) w.innerHTML = vidBody(); };
function openVideos() { openWide(vidHTML()); }
document.addEventListener('submit', e => {
  if (e.target.id !== 'vid-form') return;
  e.preventDefault();
  const id = e.target.dataset.id, o = { title: $('#v-title').value.trim(), theme: $('#v-theme').value, url: $('#v-url').value.trim(), desc: $('#v-desc').value.trim() };
  if (!o.title) return;
  if (o.url && !/^https:\/\//i.test(o.url)) { toast('Le lien doit commencer par https://'); return; }
  const list = vidList().map(v => Object.assign({}, v));
  if (id) Object.assign(list.find(v => v.id === id), o); else list.push(Object.assign({ id: 'vd-' + uid() }, o));
  vidSave(list); VG.edit = ''; vidRefresh(); toast('Capsule enregistrée ✓');
});
document.addEventListener('change', e => {
  const t = e.target;
  if (t.id === 'vd-imp' && t.files[0]) {
    const fr = new FileReader();
    fr.onload = () => { try { const j = JSON.parse(fr.result), a = Array.isArray(j) ? j : j.videos; if (!Array.isArray(a)) throw new Error('fichier non reconnu'); vidSave(a.filter(x => x && x.title).map((x, i) => ({ id: 'vd-' + uid() + i, theme: VIDEO_THEMES.includes(x.theme) ? x.theme : VIDEO_THEMES[0], title: String(x.title).slice(0, 120), desc: String(x.desc || '').slice(0, 200), url: /^https:\/\//i.test(x.url || '') ? String(x.url) : '' }))); vidRefresh(); toast('Capsules importées ✓'); } catch (er) { toast('Import impossible : ' + er.message); } };
    fr.readAsText(t.files[0]);
  }
});


/* ---------- Banque d'animations : poèmes, sketchs, slams, jeux (thèmes et passages bibliques) */
const AG = { type: '', q: '', edit: '' };
const animList = () => {
  const e = PR.anim && PR.anim.list; if (!(e && Array.isArray(e.v))) return ANIM_SEED.map(x => Object.assign({}, x));
  const NEW = /^(sk|sl|jb|ja)-/, have = new Set(e.v.map(x => x.id)), fresh = ANIM_SEED.filter(x => NEW.test(x.id));
  const titles = new Set(fresh.map(x => x.type + '|' + x.theme));
  const kept = e.v.filter(x => !(/^an-\d+$/.test(x.id) && titles.has(x.type + '|' + x.theme)));
  return kept.concat(fresh.filter(x => !have.has(x.id)).map(x => Object.assign({}, x)));
};
const animSave = a => setP('anim', 'list', a);
const slamHTML = x => `<p class="hint"><b>⏱ ${esc(x.duree || '')}</b>${x.pole ? ' · ' + esc(x.pole) : ''}</p><details class="poemd"><summary>Lire le slam</summary><div class="poem">${esc(x.desc)}</div><p class="sk-tip">💡 <b>Conseil pratique :</b> ${esc(x.conseil)}</p></details>`;
const quizHTML = x => `<p class="hint"><b>⏱ ${esc(x.duree || '')}</b> · ${x.questions.length} questions</p><p class="hint">${esc(x.desc)}</p><details class="poemd quiz" data-id="${esc(x.id)}"><summary>Jouer · voir les questions</summary>${x.questions.map((q, i) => `<fieldset class="qz" data-q="${i}"><legend>${esc(q.q)}</legend>${q.options.map((o, j) => `<label class="qo"><input type="radio" name="${esc(x.id)}-${i}" value="${j}"> <span>${esc(o)}</span></label>`).join('')}<div class="qa"><button type="button" class="vbtn" data-act="an-val" data-id="${esc(x.id)}" data-qi="${i}">Valider</button></div><div class="qf" role="status" aria-live="polite"></div></fieldset>`).join('')}<p class="qscore hint" aria-live="polite"></p>${x.conseil ? `<p class="sk-tip">💡 <b>Conseil d'animation :</b> ${esc(x.conseil)}</p>` : ''}</details>`;
const gameHTML = x => { const dn = !!getP('anim', 'done:' + x.id); return `<p class="hint"><b>⏱ ${esc(x.duree || '')}</b></p><p class="hint">${esc(x.desc)}</p><details class="poemd"><summary>Voir le procédé</summary><div class="sk"><h5>Procédé</h5><ol class="steps">${x.procede.map(p => `<li>${esc(p.replace(/^\d+\.\s*/, ''))}</li>`).join('')}</ol><h5>Matériel</h5><ul>${(x.materiel || []).map(p => `<li>${esc(p)}</li>`).join('')}</ul><div class="qa"><button type="button" class="vbtn ${dn ? 'done' : ''}" data-act="an-done" data-id="${esc(x.id)}">${dn ? '✓ Activité réalisée' : "Valider l'activité"}</button></div></div></details>`; };
const skHTML = x => `<p class="hint"><b>⏱ ${esc(x.duree || '')}</b>${x.pole ? ' · ' + esc(x.pole) : ''}</p><details class="poemd"><summary>Lire le sketch</summary><div class="sk"><h5>Personnages</h5><ul>${(x.personnages || []).map(p => `<li>${esc(p)}</li>`).join('')}</ul><h5>Accessoires</h5><ul>${(x.accessoires || []).map(p => `<li>${esc(p)}</li>`).join('')}</ul><h5>Dialogue</h5><div class="poem">${esc(x.desc)}</div>${x.conseil ? `<p class="sk-tip">💡 <b>Conseil pratique :</b> ${esc(x.conseil)}</p>` : ''}</div></details>`;
const skCopy = x => {
  const L = (t, a) => t + ':\n- ' + a.join('\n- ');
  if (x.questions) return [x.type + ' — ' + x.theme, x.ref, x.questions.map(q => q.q + '\n' + q.options.map((o, i) => '  ' + 'ABC'[i] + '. ' + o).join('\n')).join('\n\n')].join('\n\n');
  if (x.procede) return [x.type + ' — ' + x.theme, x.ref, 'Procédé :\n' + x.procede.join('\n'), L('Matériel', x.materiel || [])].join('\n\n');
  return [x.type + ' — ' + x.theme, x.ref, x.duree ? 'Durée : ' + x.duree : '', x.personnages ? L('Personnages', x.personnages) : '', x.accessoires ? L('Accessoires', x.accessoires) : '', x.desc, x.conseil ? 'Conseil pratique : ' + x.conseil : ''].filter(Boolean).join('\n\n');
};
function animBody() {
  const all = animList(), q = norm(AG.q), list = all.filter(x => (!AG.type || x.type === AG.type) && (!q || norm([x.type, x.theme, x.ref, x.desc].join(' ')).includes(q))), e = AG.edit ? all.find(x => x.id === AG.edit) : null;
  const chip = (v, l, n) => `<button class="chip" data-act="an-type" data-v="${esc(v)}" aria-pressed="${AG.type === v}">${esc(l)} <small>${n}</small></button>`;
  return banner('anim', 'Poèmes, sketchs, slams & jeux', "Une banque d'idées avec thèmes et passages bibliques, à compléter et à adapter à ton groupe.") + tips3HTML('anim') +
    `<div class="chips" style="margin:6px 0 10px">${chip('', 'Tous', all.length)}${ANIM_TYPES.map(t => chip(t, t, all.filter(x => x.type === t).length)).join('')}</div>
    <input type="search" id="an-q" placeholder="Rechercher un thème, un passage…" value="${esc(AG.q)}" autocomplete="off" style="margin-bottom:12px">
    <div class="vgrid">${list.length ? list.map(x => `<article class="vid an"><div class="vbody"><span class="badge">${esc(x.type)}</span><h4>${esc(x.type === 'Poème' ? x.theme.replace(/\s+—\s+.*$/, '') : x.theme)}</h4><p class="ref">${esc(x.ref)}</p>${x.ton ? `<p class="hint">${esc(x.ton)}</p>` : ''}${x.questions ? quizHTML(x) : x.procede ? gameHTML(x) : x.personnages ? skHTML(x) : x.conseil ? slamHTML(x) : /\n/.test(x.desc) ? `<details class="poemd"><summary>Lire le poème</summary><div class="poem">${esc(x.desc)}</div></details>` : `<p class="hint">${esc(x.desc)}</p>`}<div class="actions" style="margin-top:4px"><button class="btn ghost sm" data-act="an-copy" data-id="${esc(x.id)}">Copier</button><button class="btn ghost sm" data-act="an-edit" data-id="${esc(x.id)}">Modifier</button><button class="btn danger sm" data-act="an-del" data-id="${esc(x.id)}">Supprimer</button></div></div></article>`).join('') : '<div class="empty" style="grid-column:1/-1">Aucune idée ne correspond.</div>'}</div>
    <details class="bulk" id="an-manage" ${e ? 'open' : ''}><summary>Ajouter ou modifier une idée</summary>
    <form id="anim-form" data-id="${e ? esc(e.id) : ''}"><div class="two"><div><label class="f" for="a-type">Type</label><select id="a-type">${ANIM_TYPES.map(t => `<option ${e && e.type === t ? 'selected' : ''}>${esc(t)}</option>`).join('')}</select></div><div><label class="f" for="a-ref">Passage biblique</label><input type="text" id="a-ref" maxlength="80" value="${esc(e ? e.ref : '')}" placeholder="Ex. : Psaume 23"></div></div>
    <label class="f" for="a-theme" style="margin-top:8px">Thème / titre</label><input type="text" id="a-theme" required maxlength="100" value="${esc(e ? e.theme : '')}">
    <label class="f" for="a-desc" style="margin-top:8px">Idée, consigne ou texte</label><textarea id="a-desc" maxlength="4000" style="min-height:140px">${esc(e ? e.desc : '')}</textarea>
    <div class="actions"><button class="btn" type="submit">${e ? 'Enregistrer' : '＋ Ajouter'}</button>${e ? '<button class="btn ghost" type="button" data-act="an-cancel">Annuler</button>' : ''}<button class="btn ghost" type="button" data-act="an-export">Exporter (JSON)</button><button class="btn ghost" type="button" data-act="an-reset">Rétablir la liste d'origine</button></div></form></details>`;
}
const animHTML = () => head('Poèmes, sketchs, slams &amp; jeux') + `<div class="sheet-body" id="an-wrap">${animBody()}</div>`;
const animRefresh = () => { const w = $('#an-wrap'), q = $('#an-q'), f = document.activeElement === q; if (w) w.innerHTML = animBody(); if (f) { const n = $('#an-q'); n.focus(); n.setSelectionRange(n.value.length, n.value.length); } };
document.addEventListener('input', e => { if (e.target.id === 'an-q') { AG.q = e.target.value; animRefresh(); } });
document.addEventListener('submit', e => {
  if (e.target.id !== 'anim-form') return; e.preventDefault();
  const id = e.target.dataset.id, o = { type: $('#a-type').value, theme: $('#a-theme').value.trim(), ref: $('#a-ref').value.trim(), desc: $('#a-desc').value.trim() };
  if (!o.theme) return;
  const list = animList().map(x => Object.assign({}, x));
  if (id) Object.assign(list.find(x => x.id === id), o); else list.push(Object.assign({ id: 'an-' + uid() }, o));
  animSave(list); AG.edit = ''; animRefresh(); toast('Idée enregistrée ✓');
});
document.addEventListener('click', e => {
  const el = e.target.closest && e.target.closest('[data-act]'); if (!el) return;
  const a = el.dataset.act;
  if (a === 'anim') { document.body.classList.remove('menu'); openWide(animHTML()); }
  else if (a === 'an-type') { AG.type = el.dataset.v; animRefresh(); }
  else if (a === 'an-edit') { AG.edit = el.dataset.id; animRefresh(); const f = $('#anim-form'); if (f) f.scrollIntoView({ behavior: 'smooth', block: 'center' }); }
  else if (a === 'an-cancel') { AG.edit = ''; animRefresh(); }
  else if (a === 'an-val') {
    const fs = el.closest('.qz'), g = animList().find(v => v.id === el.dataset.id), q = g && g.questions[+el.dataset.qi]; if (!q) return;
    const ch = fs.querySelector('input:checked'), fb = fs.querySelector('.qf');
    if (!ch) { fb.className = 'qf warn'; fb.textContent = 'Choisis une réponse avant de valider.'; return; }
    const ok = +ch.value === q.correct; fs.dataset.ok = ok ? '1' : '0';
    fb.className = 'qf ' + (ok ? 'ok' : 'ko');
    fb.innerHTML = '<b>' + (ok ? '✅ Bonne réponse !' : "❌ Ce n'est pas tout à fait ça. Bonne réponse : " + esc(q.options[q.correct])) + '</b><br>' + esc(q.fb);
    fs.querySelectorAll('input').forEach(i => { i.disabled = true; }); el.disabled = true;
    const box = el.closest('.quiz'), all = box.querySelectorAll('.qz'), dn = box.querySelectorAll('.qz[data-ok]');
    if (dn.length === all.length) box.querySelector('.qscore').textContent = 'Score : ' + box.querySelectorAll('.qz[data-ok="1"]').length + ' / ' + all.length;
  }
  else if (a === 'an-done') { const k = 'done:' + el.dataset.id, v = !getP('anim', k); setP('anim', k, v); el.classList.toggle('done', v); el.textContent = v ? '✓ Activité réalisée' : "Valider l'activité"; toast(v ? 'Activité marquée comme réalisée ✓' : 'Marque retirée'); }
  else if (a === 'an-del') { if (confirm('Supprimer cette idée ?')) { animSave(animList().filter(x => x.id !== el.dataset.id)); animRefresh(); } }
  else if (a === 'an-copy') { const x = animList().find(v => v.id === el.dataset.id); if (x) copy(x.personnages || x.questions || x.procede ? skCopy(x) : x.type + ' — ' + x.theme + '\n' + x.ref + '\n' + x.desc); }
  else if (a === 'an-export') download('animations.json', JSON.stringify({ app: 'ecosysteme-chretien-animations', items: animList() }, null, 1));
  else if (a === 'an-reset') { if (confirm("Rétablir la liste d'origine ? Tes ajouts seront supprimés.")) { animSave(ANIM_SEED.map(x => Object.assign({}, x))); animRefresh(); } }
});

/* ---------- Flux « Actualités & Sensibilisation Chrétienne » (actualites.json ou adresse configurable) */
const NJK = 'ec5_newsjson';
let NJ = store.get(NJK, null);
const safeLink = u => /^https?:\/\//i.test(u || '') ? u : '';
async function loadNewsJson(force) {
  const url = S.newsUrl || 'actualites.json';
  try {
    const r = await fetch(url, { cache: force ? 'reload' : 'no-cache' }); if (!r.ok) throw new Error('HTTP ' + r.status);
    const j = await r.json(); if (!j || !Array.isArray(j.items)) throw new Error('format');
    NJ = { t: Date.now(), url, data: j }; store.set(NJK, NJ);
  } catch (er) { /* hors-ligne ou fichier absent : on garde la dernière copie locale */ }
  renderNJ();
}
function renderNJ() {
  const box = $('#nj-box'); if (!box) return;
  const d = NJ && NJ.data, items = d ? d.items : [];
  const cats = [...new Set(items.map(i => i.categorie).filter(Boolean))], cur = S.njCat || '';
  const list = items.map((x, i) => [x, i]).filter(([x]) => !cur || x.categorie === cur);
  box.innerHTML = `<div class="feed-bar"><label class="ddf"><span>Catégorie</span><select id="nj-cat"><option value="">Toutes</option>${cats.map(c => `<option ${c === cur ? 'selected' : ''}>${esc(c)}</option>`).join('')}</select></label><button class="btn ghost sm" data-act="nj-refresh">↻ Actualiser</button></div>
  <p class="hint">${d ? 'Mis à jour le ' + esc(d.maj || '—') + ' · ' + items.length + ' message(s)' : 'Aucun message chargé pour le moment.'}</p>` +
    (list.length ? list.map(([x, i]) => `<article class="feed-item"><span class="badge">${esc(x.categorie || 'Message')}</span><h4>${esc(x.titre)}</h4><p>${esc(x.texte)}</p>${x.verset ? `<p class="hint">Verset : <b>${esc(x.verset)}</b> (Louis Segond 1910)</p>` : ''}<div class="actions" style="margin-top:2px">${safeLink(x.lien) ? `<a class="btn ghost sm" href="${esc(safeLink(x.lien))}" target="_blank" rel="noopener noreferrer">Lire la suite</a>` : ''}<button class="btn ghost sm" data-act="nj-note" data-i="${i}">Au carnet</button></div></article>`).join('') : '<div class="empty">Rien à afficher.</div>') +
    `<details class="bulk"><summary>Changer la source du flux</summary><label class="f" for="nj-url">Adresse d'un fichier JSON (même format que actualites.json)</label><input type="url" id="nj-url" placeholder="actualites.json (par défaut)" value="${esc(S.newsUrl || '')}"><div class="actions"><button class="btn ghost sm" data-act="nj-save">Enregistrer</button></div></details>`;
}
function showActu() { openModal(actuHTML()); loadFeeds(false); loadNewsJson(false); }
document.addEventListener('change', e => { if (e.target.id === 'nj-cat') { S.njCat = e.target.value; saveS(); renderNJ(); } });

/* ---------- actions des nouveaux modules */
document.addEventListener('click', e => {
  const el = e.target.closest && e.target.closest('[data-act]'); if (!el) return;
  const a = el.dataset.act;
  if (a === 'prog') { document.body.classList.remove('menu'); openProg(); }
  else if (a === 'videos') { document.body.classList.remove('menu'); openVideos(); }
  else if (a === 'pg-add') { const rows = progRows(PGS.year); rows.push({ id: 'r' + Date.now(), m: 'Nouvelle période', pole: PROG_POLES[1], theme: '', act: PROG_ACTS[1], obj: '', resp: '', st: 'Planifié' }); progSave(rows); progRefresh(); const tds = document.querySelectorAll('td[data-pg="m"]'); if (tds.length) tds[tds.length - 1].focus(); }
  else if (a === 'pg-del') { const rows = progRows(PGS.year); if (confirm('Supprimer la ligne « ' + (rows[+el.dataset.i] || {}).m + ' » ?')) { rows.splice(+el.dataset.i, 1); progSave(rows); progRefresh(); } }
  else if (a === 'pg-dup') {
    const ny = PGS.year + 1;
    if (PR.prog[ny] && Array.isArray(PR.prog[ny].v) && !confirm('Le programme ' + ny + ' existe déjà. Le remplacer par une copie de ' + PGS.year + ' ?')) return;
    const rows = progRows(PGS.year).map((r, i) => Object.assign({}, r, { id: 'r' + Date.now() + i, st: 'Planifié' }));
    PGS.year = ny; progSave(rows); S.progYear = ny; saveS(); progRefresh(); toast('Programme ' + ny + ' créé : actualise les thèmes et les dates ✓');
  }
  else if (a === 'pg-export') download('programme-annuel-' + PGS.year + '.json', JSON.stringify({ app: 'ecosysteme-chretien-programme', year: PGS.year, rows: progRows(PGS.year) }, null, 1));
  else if (a === 'pg-print') progPrint();
  else if (a === 'pg-reset') { if (confirm('Rétablir le modèle d\'origine pour ' + PGS.year + ' ? Tes modifications de cette année seront remplacées.')) { delete PR.prog[PGS.year]; progSave(PROG_TEMPLATE.map((r, i) => ({ id: 'r' + i, m: PROG_MONTHS[i], pole: r[0], theme: r[1], act: r[2], obj: r[3], resp: r[4], st: 'Planifié' }))); progRefresh(); } }
  else if (a === 'vd-theme') { VG.theme = el.dataset.v; vidRefresh(); }
  else if (a === 'vd-play') {
    const v = vidList().find(x => x.id === el.dataset.id), p = v && vidParse(v.url), box = $('#vp-' + el.dataset.id); if (!p || !box) return;
    box.innerHTML = p.type === 'yt' ? `<iframe src="https://www.youtube-nocookie.com/embed/${p.id}?autoplay=1&rel=0" title="${esc(v.title)}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe>` : `<video src="${esc(p.url)}" controls autoplay playsinline preload="none"></video>`;
  }
  else if (a === 'vd-edit') { VG.edit = el.dataset.id; vidRefresh(); const f = $('#vid-form'); if (f) f.scrollIntoView({ behavior: 'smooth', block: 'center' }); }
  else if (a === 'vd-cancel') { VG.edit = ''; vidRefresh(); }
  else if (a === 'vd-del') { if (confirm('Supprimer cette capsule ?')) { vidSave(vidList().filter(v => v.id !== el.dataset.id)); vidRefresh(); } }
  else if (a === 'vd-export') download('capsules-video.json', JSON.stringify({ app: 'ecosysteme-chretien-videos', videos: vidList() }, null, 1));
  else if (a === 'vd-reset') { if (confirm('Rétablir les capsules d\'origine (sans lien) ? Tes ajouts seront supprimés.')) { vidSave(VIDEO_SEED.map(v => Object.assign({}, v))); vidRefresh(); } }
  else if (a === 'nj-refresh') loadNewsJson(true);
  else if (a === 'nj-save') { S.newsUrl = ($('#nj-url').value || '').trim(); if (S.newsUrl && !/^https?:\/\//i.test(S.newsUrl) && !/^[\w./-]+\.json$/i.test(S.newsUrl)) { toast('Adresse non valide.'); S.newsUrl = ''; } saveS(); loadNewsJson(true); toast('Source enregistrée'); }
  else if (a === 'nj-note') { const x = NJ && NJ.data && NJ.data.items[+el.dataset.i]; if (x) openCarnet(null, { title: 'Prière · ' + x.titre, body: x.texte + (x.verset ? '\n(' + x.verset + ')' : '') }); }
});



/* ---------- Connecteur prieredelivrance.com : titres, extraits et liens (pas de copie intégrale) */
const pdData = () => { const e = PR.pdimp && PR.pdimp.list; return e && e.v ? e.v : { items: [], src: '', at: 0 }; };
function pdListHTML() {
  const d = pdData();
  return `<p class="hint" id="pd-state">${d.items.length ? d.items.length + ' prière(s) référencée(s) · dernière synchronisation : ' + new Date(d.at).toLocaleString('fr-FR') : 'Aucune synchronisation pour le moment : les 36 prières intégrées restent disponibles hors-ligne.'}</p>` +
    d.items.map(x => `<article class="feed-item"><span class="badge">${esc(x.cat || 'prieredelivrance.com')}</span><h4>${esc(x.title)}</h4>${x.excerpt ? `<p class="hint">${esc(x.excerpt)}</p>` : ''}${safeLink(x.link) ? `<a class="btn ghost sm" href="${esc(safeLink(x.link))}" target="_blank" rel="noopener noreferrer">Lire sur le site →</a>` : ''}</article>`).join('');
}
function pdSectionHTML() {
  return `<details class="bulk" id="pd-box"><summary>Synchroniser avec prieredelivrance.com (enrichir les sujets)</summary>
  <p class="hint">Récupère les titres, extraits et liens des prières de la page indiquée et les range dans cette rubrique. Le texte complet reste sur le site d'origine (lien « Lire sur le site »). Si le site bloque l'accès depuis le navigateur (CORS), renseigne un relais « proxy » ou l'adresse d'un fichier JSON au format actualites.json.</p>
  <label class="f" for="pd-url">Adresse à synchroniser</label><input type="url" id="pd-url" value="${esc(S.pdUrl || PD_SOURCE.url)}">
  <label class="f" for="pd-proxy" style="margin-top:8px">Relais (facultatif) : adresse se terminant par ?url= ou contenant {url}</label><input type="url" id="pd-proxy" placeholder="https://mon-relais.exemple/?url=" value="${esc(S.pdProxy || '')}">
  <div class="actions"><button class="btn" data-act="pd-sync">↻ Synchroniser</button><button class="btn ghost" data-act="pd-clear">Vider la liste</button></div>
  <div id="pd-list">${pdListHTML()}</div></details>`;
}
function pdParse(html, base) {
  const doc = new DOMParser().parseFromString(html, 'text/html'), host = new URL(base).host, out = [], seen = new Set();
  const txt = n => (n && n.textContent || '').replace(/\s+/g, ' ').trim();
  doc.querySelectorAll('article, .post, .card, li.type-post').forEach(n => {
    const h = n.querySelector('h1,h2,h3,h4'), a = (h && h.querySelector('a')) || n.querySelector('a[href]'); if (!a) return;
    let link; try { link = new URL(a.getAttribute('href'), base); } catch (e) { return; }
    if (!/^https?:$/.test(link.protocol) || link.host !== host || seen.has(link.href) || link.href === base) return;
    const title = txt(h || a).slice(0, 140); if (!title) return; seen.add(link.href);
    const cat = txt(n.querySelector('[rel~=tag],[rel~=category],.category,.cat,[class*=categ]')).slice(0, 40), p = n.querySelector('p');
    out.push({ title, excerpt: txt(p).slice(0, 220), cat, link: link.href });
  });
  return out;
}
async function pdSync() {
  const st = $('#pd-state'), base = ($('#pd-url').value || '').trim() || PD_SOURCE.url, px = ($('#pd-proxy').value || '').trim();
  if (!/^https?:\/\//i.test(base) || (px && !/^https?:\/\//i.test(px))) { toast('Adresse non valide (https://…).'); return; }
  S.pdUrl = base; S.pdProxy = px; saveS();
  const url = px ? (px.includes('{url}') ? px.replace('{url}', encodeURIComponent(base)) : px + encodeURIComponent(base)) : base;
  if (!navigator.onLine) { toast('Hors-ligne : les prières intégrées restent disponibles.'); return; }
  if (st) st.textContent = 'Synchronisation en cours…';
  try {
    const r = await fetch(url); if (!r.ok) throw new Error('HTTP ' + r.status);
    let list;
    if (/json/i.test(r.headers.get('content-type') || '') || /\.json(\?|$)/i.test(base)) { const j = await r.json(), a = Array.isArray(j) ? j : j.items; if (!Array.isArray(a)) throw new Error('format JSON non reconnu'); list = a.map(x => ({ title: String(x.titre || x.title || '').slice(0, 140), excerpt: String(x.texte || x.excerpt || '').slice(0, 220), cat: String(x.categorie || x.cat || '').slice(0, 40), link: safeLink(x.lien || x.link) })); }
    else list = pdParse(await r.text(), base);
    list = list.filter(x => x.title).slice(0, 80); if (!list.length) throw new Error('aucune prière reconnue sur cette page');
    setP('pdimp', 'list', { items: list, src: base, at: Date.now() }); toast('✓ ' + list.length + ' prière(s) référencée(s)');
  } catch (e) { toast("Synchronisation impossible (" + e.message + ") : le site bloque peut-être l'accès direct. Utilise un relais ou un fichier JSON."); }
  const l = $('#pd-list'); if (l) l.innerHTML = pdListHTML();
}
document.addEventListener('click', e => {
  const el = e.target.closest && e.target.closest('[data-act]'); if (!el) return;
  const a = el.dataset.act;
  if (a === 'qf') { QF[S.space] = el.dataset.v; shown = 24; renderList(); return; }
  if (a === 'lview') { S.lview = el.dataset.v; saveS(); renderSpace(); }
  else if (a === 'ccopy') { const it = ALLBYID[el.dataset.id]; if (it) copy(itemText(it)); }
  else if (a === 'cpray') { const it = ALLBYID[el.dataset.id]; if (it) { const k = isP(it.sp) ? 'prayed' : 'read'; setP(k, it.id, !getP(k, it.id)); renderList(); } }
  else if (a === 'pd-sync') pdSync();
  else if (a === 'pd-clear') { delete PR.pdimp.list; setP('pdimp', 'list', { items: [], src: '', at: 0 }); const l = $('#pd-list'); if (l) l.innerHTML = pdListHTML(); }
});

/* ------------------------------------------------------------ démarrage & PWA */
window.addEventListener('online', () => { setStatus(status === 'offline' ? 'none' : status); syncNow(false); });
window.addEventListener('offline', () => setStatus('offline'));
window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); deferredInstall = e; });
document.addEventListener('visibilitychange', () => { if (!document.hidden && sbOn()) syncNow(false); });
setInterval(() => { if (!document.hidden && sbOn() && navigator.onLine) syncNow(false); }, 120000);
(function init() {
  const th = store.get('ec5_theme', null); if (th) document.documentElement.dataset.theme = th;
  applyText(); render();
  setStatus('none'); setTimeout(remindTick, 2500); setInterval(remindTick, 60000);
  if (sbOn()) syncNow(false);
  if ('serviceWorker' in navigator && location.protocol !== 'file:') {
    navigator.serviceWorker.register('sw.js').then(reg => {
      reg.addEventListener('updatefound', () => { const w = reg.installing; if (w) w.addEventListener('statechange', () => { if (w.state === 'installed' && navigator.serviceWorker.controller) toast('Nouvelle version prête : recharge la page pour l\'utiliser.'); }); });
    }).catch(() => { /* hors HTTPS/localhost : mode normal */ });
  }
})();

/* ---------- Historique : boutons Retour / Suivant (vues, onglets, fenêtres) */
(function () {
  const bk = $('#nav-back'), fw = $('#nav-fwd'), modalOpen = () => $('#modal').classList.contains('open');
  const key = () => S.view + '|' + S.space + '|' + (S.tab[S.space] || 'lib');
  let idx = (history.state && history.state.i) || 0, max = idx, cur = null, quiet = false, skip = false;
  const snap = modal => ({ i: idx, view: S.view, space: S.space, tab: S.tab[S.space] || 'lib', modal: !!modal });
  const upd = () => { if (bk) bk.disabled = idx <= 0; if (fw) fw.disabled = idx >= max; };
  const push = modal => { idx++; max = idx; history.pushState(snap(modal), ''); upd(); };
  const wrapView = fn => function () {
    const r = fn.apply(this, arguments);
    if (!quiet) { const k = key(); if (cur === null) { cur = k; history.replaceState(snap(false), ''); upd(); } else if (k !== cur) { cur = k; push(false); } }
    return r;
  };
  renderSpace = wrapView(renderSpace); renderGlobal = wrapView(renderGlobal);
  const open0 = openModal, close0 = closeModal;
  openModal = function () { const was = modalOpen(); const r = open0.apply(this, arguments); if (!quiet && !was) push(true); return r; };
  closeModal = function () {
    const was = modalOpen(), r = close0.apply(this, arguments);
    if (!quiet && was && history.state && history.state.modal) { skip = true; history.back(); }
    return r;
  };
  window.addEventListener('popstate', e => {
    const st = e.state; if (!st) return;
    idx = st.i || 0; max = Math.max(max, idx); upd();
    if (skip) { skip = false; return; }
    quiet = true;
    try {
      if (modalOpen()) close0();
      if (st.modal) { skip = true; history.back(); return; }
      if (st.view) { S.view = st.view; S.space = st.space; S.tab[st.space] = st.tab; saveS(); render(); cur = key(); window.scrollTo(0, 0); }
    } finally { quiet = false; }
  });
  document.addEventListener('click', e => {
    const b = e.target.closest && e.target.closest('[data-act="nav-back"],[data-act="nav-fwd"]'); if (!b) return;
    if (b.dataset.act === 'nav-back') history.back(); else history.forward();
  });
  cur = key(); history.replaceState(snap(false), ''); upd();
})();
})();
