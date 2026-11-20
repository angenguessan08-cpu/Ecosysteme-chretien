/* Page « À propos & Contact » (affichée dans une fenêtre large de l'application) */
(function () {
  const KEY = 'ecosysteme_contact_messages';
  window.aboutHTML = function () {
    return `<div class="sheet-head"><div><h2>À propos &amp; Contact</h2></div><button class="x" data-act="close" aria-label="Fermer">✕</button></div>
<div class="sheet-body ab">
  <nav class="ab-nav" aria-label="Sections"><a href="#ab-apropos" data-ab="ab-apropos">À propos</a><a href="#ab-poles" data-ab="ab-poles">Les 3 pôles</a><a href="#ab-concepteur" data-ab="ab-concepteur">Le concepteur</a><a href="#ab-contact" data-ab="ab-contact" class="cta">Nous contacter</a></nav>

  <section class="ab-hero">
    <span class="ab-tag">Vision · Conception · Accompagnement</span>
    <h3>Édifier chaque génération par la <em>Parole</em> et la <em class="g">Prière</em></h3>
    <p>Découvrez la vision éditoriale derrière <b>Écosystème Chrétien</b> — une plateforme conçue pour accompagner les enfants, les jeunes filles, les familles et les responsables d'église au quotidien, même hors-ligne.</p>
  </section>

  <section id="ab-apropos" class="ab-sec">
    <div class="ab-eyebrow">À propos de la plateforme</div>
    <h3>Un outil spirituel accessible de 8 à 100 ans</h3>
    <div class="ab-two">
      <div>
        <p>Né d'un besoin concret observé au sein des familles, des groupes de jeunesse et des assemblées évangéliques, <b>Écosystème Chrétien</b> rassemble dans un espace unique des ressources bibliques structurées, pratiques et fidèles aux Écritures (Louis Segond 1910).</p>
        <p>Pensée pour fonctionner avec une <b>connexion limitée ou hors-ligne</b>, la plateforme offre une lecture confortable pour toutes les générations, un carnet de prière personnel 100 % privé et des outils d'animation prêts à l'emploi (méditations, quiz, poèmes, sketchs, slams et jeux).</p>
        <div class="ab-kpis"><div><b>3</b><span>Pôles complémentaires</span></div><div><b>400+</b><span>Fiches &amp; sujets de prière</span></div><div><b>100 %</b><span>Gratuit &amp; hors-ligne</span></div></div>
      </div>
      <div class="ab-stack">
        <article class="ab-c e"><h4>💡 Notre mission</h4><p>Rendre la méditation biblique, l'intercession familiale et la formation spirituelle simples, vivantes et accessibles à chacun, sans barrière technique ni confessionnelle.</p></article>
        <article class="ab-c a"><h4>🛡️ Éthique &amp; sécurité</h4><p>Respect de la vie privée : vos notes personnelles restent strictement sur votre appareil. Aucune manipulation, uniquement l'édification dans la grâce.</p></article>
        <article class="ab-c i"><h4>🤝 Ouverture inter-églises</h4><p>Une bibliothèque commune ouverte à toutes les assemblées, pour partager des ressources validées et édifiantes.</p></article>
      </div>
    </div>
  </section>

  <section id="ab-poles" class="ab-sec">
    <div class="ab-eyebrow">Architecture éditoriale</div>
    <h3>Trois espaces complémentaires réunis</h3>
    <div class="ab-three">
      <article class="ab-c e"><h4>Fille de la promesse</h4><p>Un parcours pour les jeunes filles et les femmes : foi, estime de soi en Christ, sagesse, talents et conduite chrétienne, avec quiz, défis, poèmes, sketchs et slams.</p><small>Croissance · Talents · Défis — Pôle 01</small></article>
      <article class="ab-c a"><h4>Élan Famille</h4><p>Plus de 380 sujets d'intercession personnalisables avec le prénom de chaque enfant, un minuteur « 15 Min avec Dieu » et un générateur de Culte Familial.</p><small>Enfants · Parents · Intercession — Pôle 02</small></article>
      <article class="ab-c i"><h4>Fondement vie spirituelle</h4><p>Des enseignements doctrinaux clairs sur le Don, les Autels, les Alliances et la Consécration, avec un programme annuel d'activités et des capsules de sensibilisation.</p><small>Enseignement · Formation · Leadership — Pôle 03</small></article>
    </div>
  </section>

  <section id="ab-concepteur" class="ab-sec">
    <div class="ab-eyebrow">Le mot du concepteur</div>
    <div class="ab-designer">
      <div class="ab-id"><div class="ab-av">✒️<span>Concepteur</span></div><h4>Équipe &amp; Concepteur</h4><p class="hint">Conception éditoriale, pédagogique &amp; numérique</p><p class="hint">📍 Abidjan, Côte d'Ivoire</p>
        <div class="ab-chips"><span>Édification biblique</span><span>Jeunesse &amp; Famille</span><span>Outils numériques</span></div></div>
      <div>
        <h3>« Mettre le numérique au service de la foi vivante, de la famille et de la jeunesse »</h3>
        <p>Ce portail est le fruit d'un travail de structuration biblique, pédagogique et technique. L'objectif : offrir aux parents, aux moniteurs d'école du dimanche, aux responsables de jeunesse et à chaque croyant un compagnon fiable, structuré et gratuit pour nourrir sa vie de prière et son étude de la Parole.</p>
        <p>Chaque rubrique — sujets de prière, parcours pour les jeunes filles, programmes annuels, capsules vidéo, poèmes, sketchs, slams et jeux — est pensée pour être utilisable immédiatement sur le terrain : en cellule, à l'école ou en assemblée.</p>
        <div class="ab-two sm"><div class="ab-note">✅ <b>Ancrage biblique :</b> textes basés sur la Bible Louis Segond 1910, dans le respect de la saine doctrine.</div><div class="ab-note">✅ <b>Approche participative :</b> ouvert aux suggestions, témoignages et contributions des églises.</div></div>
      </div>
    </div>
  </section>

  <section id="ab-contact" class="ab-sec">
    <div class="ab-eyebrow">Nous contacter</div>
    <h3>Échangeons ensemble</h3>
    <div class="ab-two">
      <div class="ab-stack">
        <p>Une question, une suggestion, un témoignage ou une ressource à proposer pour votre assemblée ? Écrivez-nous.</p>
        <article class="ab-c e"><h4>✉️ Courriel éditorial &amp; support</h4><p><a href="mailto:contact@ecosysteme-chretien.org">contact@ecosysteme-chretien.org</a></p></article>
        <article class="ab-c a"><h4>📍 Localisation</h4><p>Abidjan, Côte d'Ivoire · Francophonie</p></article>
        <article class="ab-c i"><h4>📱 Application</h4><p>Web &amp; PWA hors-ligne · Version 6.0</p></article>
        <details class="poemd"><summary>L'application est-elle gratuite ?</summary><p class="hint">Oui, l'accès aux méditations, sujets de prière, quiz, poèmes, sketchs, slams et jeux est entièrement gratuit.</p></details>
        <details class="poemd"><summary>Puis-je l'utiliser dans mon église ?</summary><p class="hint">Oui : fiches, programmes annuels et activités sont utilisables en réunion de jeunesse, cellule ou culte familial.</p></details>
      </div>
      <form id="ab-form" class="ab-form" novalidate>
        <h4>Envoyer un message</h4>
        <div class="two"><div><label class="f" for="c-name">Nom &amp; prénoms *</label><input type="text" id="c-name" required maxlength="120" placeholder="Ex. KONÉ Grâce Marie"></div><div><label class="f" for="c-email">Adresse e-mail *</label><input type="email" id="c-email" required maxlength="160" placeholder="nom@exemple.com"></div></div>
        <div class="two"><div><label class="f" for="c-subject">Objet *</label><select id="c-subject"><option>Question générale</option><option>Proposer un contenu / partenariat Église</option><option>Suggestion d'amélioration</option><option>Témoignage &amp; encouragement</option></select></div><div><label class="f" for="c-church">Assemblée / ville (facultatif)</label><input type="text" id="c-church" maxlength="120" placeholder="Ex. Abidjan — Église…"></div></div>
        <label class="f" for="c-message">Votre message *</label><textarea id="c-message" rows="4" required maxlength="3000" placeholder="Écrivez votre message…"></textarea>
        <div id="ab-fb" class="ab-fb" role="status" aria-live="polite" hidden></div>
        <div class="actions"><button class="btn" type="submit">Enregistrer le message</button><button class="btn ghost" type="button" data-ab-mail>Envoyer par e-mail</button></div>
        <p class="hint">Le message est enregistré sur votre appareil ; « Envoyer par e-mail » ouvre votre messagerie.</p>
      </form>
    </div>
  </section>
</div>`;
  };

  function read() {
    const g = id => (document.getElementById(id) || {}).value || '';
    return { name: g('c-name').trim(), email: g('c-email').trim(), subject: g('c-subject'), church: g('c-church').trim(), message: g('c-message').trim() };
  }
  const valid = m => m.name && /^\S+@\S+\.\S+$/.test(m.email) && m.message;
  function say(t, bad) { const f = document.getElementById('ab-fb'); if (!f) return; f.hidden = false; f.className = 'ab-fb' + (bad ? ' bad' : ''); f.textContent = t; }
  const NEED = 'Merci de renseigner votre nom, une adresse e-mail valide et votre message.';

  document.addEventListener('submit', e => {
    if (e.target.id !== 'ab-form') return; e.preventDefault();
    const m = read(); if (!valid(m)) return say(NEED, true);
    try { const a = JSON.parse(localStorage.getItem(KEY) || '[]'); a.unshift(Object.assign(m, { date: new Date().toISOString() })); localStorage.setItem(KEY, JSON.stringify(a)); } catch (_) { return say('Enregistrement impossible sur cet appareil.', true); }
    say('Merci ' + m.name + ' ! Votre message « ' + m.subject + ' » est enregistré sur cet appareil. Utilisez « Envoyer par e-mail » pour nous le transmettre.');
    e.target.reset();
  });
  document.addEventListener('click', e => {
    const a = e.target.closest && e.target.closest('[data-ab]');
    if (a) { e.preventDefault(); const t = document.getElementById(a.dataset.ab); if (t) t.scrollIntoView({ behavior: 'smooth', block: 'start' }); return; }
    if (e.target.closest && e.target.closest('[data-ab-mail]')) {
      const m = read(); if (!valid(m)) return say(NEED, true);
      const body = m.message + '\n\n— ' + m.name + (m.church ? ' (' + m.church + ')' : '') + ' · ' + m.email;
      location.href = 'mailto:contact@ecosysteme-chretien.org?subject=' + encodeURIComponent(m.subject) + '&body=' + encodeURIComponent(body);
    }
  });
})();
