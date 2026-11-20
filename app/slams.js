/* 12 slams complets : remplacent les 8 idées courtes et ajoutent 4 slams « Fille de la promesse ». */
(function () {
  const S = [
    ['01', 'Identité & Valeur', 'Pas à vendre', 'Genèse 1:27', "Assuré, percutant, avec une pointe d'ironie sur la société de consommation. Cadence modérée montant en puissance sur le refrain.", '2 min 30',
`On vit dans un monde où tout a une étiquette,
Un code-barres collé jusque sur la casquette !
« Combien tu pèses ? Combien tu gagnes ? Combien tu vaux ? »
On te juge au vêtement, au téléphone ou au niveau !
Mais dis-moi : depuis quand un cœur se vend au kilo ?
Depuis quand une âme se négocie au rabais au coin du rétro ?

Regarde dans le miroir : tu n'es pas un produit en solde,
Pas un brouillon raté, pas une copie qu'on remoule !
Genèse 1:27 a déjà signé ton acte de naissance :
Créé à l'image de Dieu — voilà ta vraie puissance !
Même si les hommes te mettent « hors catégorie »,
Le Ciel a déjà payé le prix fort pour ta vie !

Alors remballe tes complexes et range tes étiquettes,
La valeur d'un enfant de Dieu n'est pas faite en miettes.
Aucun regard méchant, aucun échec passé,
Ne peut effacer ce que le Créateur a gravé !
Je ne suis pas à vendre, je ne suis pas à louer :
Je porte la marque du Roi — et c'est pour l'éternité !`,
      "Marquez une pause nette avant les deux derniers vers (« Je ne suis pas à vendre... ») pour accentuer l'impact de la chute."],
    ['02', 'Réseaux & Vérité', 'Zéro filtre', 'Psaume 139:14', "Drôle, rythmé, complice avec le public (clins d'œil aux réseaux sociaux), puis profond et libérateur.", '2 min 30',
`Trois heures devant l'écran pour choisir la bonne lumière,
Oreilles de lapin, teint doré, sourire de milliardaire !
On met un filtre « Soleil », un filtre « Matin parfait »,
Alors qu'en vrai, on a encore la trace de l'oreiller !
On retouche le nez, on gomme le moindre petit pli,
Et on attend les « j'aime » comme si c'était le prix de la vie !

« Regarde comme elle voyage ! Regarde comme il réussit ! »
À force de scroller la vie des autres, on oublie la sienne ici !
On compare nos coulisses à leur bande-annonce montée,
Et on finit par trouver que notre propre vie est ratée !

Stop ! Pose le téléphone et respire un grand coup !
Le Psaume 139:14 te le dit sans tabou :
« Je te loue de ce que je suis une créature si merveilleuse ! »
Pas besoin d'application pour rendre ton âme précieuse !
Dieu n'a pas utilisé de filtre quand Il t'a façonné,
Il a mis de son souffle, de sa grâce et de sa vérité.
Zéro filtre, cent pour cent vrai, debout dans la lumière :
Tu es déjà un chef-d'œuvre entre les mains du Père !`,
      "Mimez le geste de faire défiler un écran sur la première strophe pour déclencher immédiatement le sourire du public."],
    ['03', 'Relations & Grâce', 'Pardon', 'Éphésiens 4:32', "Expressif, théâtral au début sur le poids de la rancune, léger et libérateur à la fin.", '2 min 30',
`Tu connais ce gros sac de cailloux qu'on traîne sur le dos ?
« Il m'a mal parlé en 2022... Elle n'a pas dit bonjour tantôt... »
On garde la liste au chaud, classée par ordre alphabétique,
On ressasse la scène en boucle comme un film dramatique !
Et pendant que l'autre dort paisiblement sur ses deux oreilles,
Toi tu transpires de colère sous ton propre soleil !

La rancune, c'est boire du poison en espérant que l'autre ait mal au ventre —
Spoiler : c'est ton propre cœur qui s'enferme au centre !
Éphésiens 4:32 vient casser le cadenas :
« Soyez bons les uns envers les autres, compatissants, vous pardonnant réciproquement, comme Dieu vous a pardonné en Christ. »

Pardonner, ce n'est pas dire : « Ce que tu as fait était génial ! »
Non ! C'est dire : « Je refuse que ta faute devienne ma prison finale ! »
Je lâche les pierres, je vide le sac, je reprends ma respiration,
La grâce de Jésus est plus forte que toutes mes émotions !`,
      "Mimez le geste de poser un sac très lourd au sol au moment de dire « Je lâche les pierres, je vide le sac »."],
    ['04', 'Courage & Foi', 'Debout', 'Josué 1:9', "Énergique, martial et motivant, comme un cri de ralliement.", '2 min 30',
`La peur frappe à la porte avec sa grosse voix grave :
« N'essaie même pas ! Tu vas tomber ! Reste dans ta cave ! »
Elle te sort les statistiques de tous ceux qui ont raté,
Elle te rappelle tes doutes, tes faiblesses et ton passé !
Si tu l'écoutes trop longtemps, tu restes assis sur le banc,
À regarder la vie passer comme un train sans occupant !

Mais Josué 1:9 débarque comme un coup de tonnerre :
« Ne t'ai-je pas donné cet ordre : Fortifie-toi et prends courage ? »
Ce n'est pas une suggestion si tu es de bonne humeur,
C'est un ordre du Roi qui marche devant ton cœur !
« Ne t'effraie point et ne t'épouvante point, car l'Éternel, ton Dieu, est avec toi dans tout ce que tu entreprendras ! »

Alors secoue la poussière, relève le menton,
Quand Dieu marche avec toi, tu n'es jamais seul au front !
Même si tes genoux tremblent au premier pas sur le chemin,
Avance ! Celui qui t'envoie tient l'avenir dans sa main — DEBOUT !`,
      "Invitez l'assemblée à répondre « DEBOUT ! » avec vous sur le tout dernier mot pour mobiliser la salle."],
    ['05', 'Sagesse & Paroles', 'Mes mots', 'Éphésiens 4:29', "Vif, imagé, alternant humour sur la vitesse de la langue et gravité sur l'impact des paroles.", '2 min 30',
`Sept centimètres de muscle, cachés derrière les dents,
Mais capable de déclencher un orage en deux instants !
La langue n'a pas d'os, pourtant elle casse des ponts,
Elle allume des incendies dans toutes les maisons !
« C'était juste pour rire ! C'était juste une petite pique ! »
Oui, mais la flèche est partie, et la blessure est authentique !

Une fois que le mot s'envole, impossible de le rattraper,
Même avec un filet à papillons, tu ne peux plus l'effacer !
Alors Éphésiens 4:29 pose un panneau lumineux :
« Qu'il ne sorte de votre bouche aucune parole mauvaise, mais quelque bonne parole, qui serve à l'édification ! »

Mes mots peuvent être des pierres qui écrasent le voisin,
Ou des briques solides qui bâtissent son chemin !
Je choisis d'être un maçon, pas un démolisseur :
Que ma bouche sème la paix, le courage et la douceur !`,
      "Accélérez légèrement le débit sur la première strophe pour illustrer la rapidité des paroles irréfléchies, puis ralentissez sur la conclusion."],
    ['06', 'Sanctification & Jeunesse', 'Pure', 'Psaume 119:9', "Posé, ferme, sans moralisme sec, inspirant la dignité et la clarté.", '2 min 30',
`On te dit : « Profite ! Tout le monde le fait, ne sois pas coincé ! »
On te vend du brouillard en te jurant que c'est la liberté !
Mais regarde autour de toi : combien de cœurs brisés,
Pour avoir suivi des chemins brillants mais piégés ?

Le Psaume 119:9 pose la question droit dans les yeux :
« Comment le jeune homme rendra-t-il pur son sentier ? »
Pas en comptant uniquement sur ses propres muscles du matin,
Mais « En se dirigeant d'après ta parole » sur chaque terrain !

Garder son cœur pur, ce n'est pas vivre dans une bulle de verre,
C'est marcher dans la boue sans que la boue devienne ton repère !
C'est savoir dire « Non » quand tout pousse à dire « Oui »,
Parce que tu connais le prix de ta paix et de ta vie !
La pureté n'est pas une cage qui t'empêche de voler :
C'est le ciel clair qui permet à tes ailes de se déployer !`,
      "Maintenez un contact visuel calme et bienveillant avec les jeunes : ce texte touche particulièrement lorsqu'il est dit avec conviction."],
    ['07', 'Intercession & Nation', 'Ma ville, ma prière', 'Jérémie 29:7', "Chaleureux, ancré dans le quotidien du quartier et de la ville, engagé.", '2 min 30',
`On critique les embouteillages, les trous dans le goudron,
Les bruits du carrefour et les factures à la maison !
C'est facile de râler assis sous le ventilateur,
Mais qui lève les mains pour bénir son secteur ?

Jérémie 29:7 donne la feuille de route aux croyants :
« Recherchez le bien de la ville où je vous ai menés... et priez l'Éternel en sa faveur, parce que votre bonheur dépend du sien ! »

Alors je prie pour mon quartier, pour l'école au coin de la rue,
Pour le vendeur du matin et celui qui n'en peut plus !
Je prie pour la paix dans les familles, la sagesse pour nos dirigeants,
Que la lumière de l'Évangile transforme les cœurs des habitants !
Ma ville n'est pas seulement l'adresse sur ma carte d'identité :
C'est le champ où Dieu m'a planté pour aimer, servir et prier !`,
      "Vous pouvez remplacer « mon quartier » par le nom réel de votre commune ou ville lors d'une veillée d'intercession."],
    ['08', 'Évangile & Résurrection', 'Il est vivant', 'Romains 10:9', "Triomphant, joyeux, crescendo final idéal pour clôturer une soirée ou un culte.", '2 min 30',
`Vendredi soir, tout semblait fini derrière une grosse pierre,
Les disciples enfermés, les yeux rouges de poussière.
L'ennemi pensait avoir gagné la partie définitive,
Il avait oublié que la Vie ne reste jamais captive !

Dimanche à l'aube, la terre tremble, le sceau éclate en morceaux,
L'ange s'assoit sur la pierre comme sur un simple tabouret nouveau !
« Pourquoi cherchez-vous parmi les morts Celui qui est vivant ? »
La tombe est vide — et l'espoir bat à nouveau dans le sang !

Romains 10:9 le proclame sans détour ni condition :
« Si tu confesses de ta bouche le Seigneur Jésus, et si tu crois dans ton cœur que Dieu l'a ressuscité des morts, tu seras sauvé ! »
Il n'est pas un souvenir figé dans un livre ancien :
Il est vivant aujourd'hui, Il guérit, Il relève, Il tient ta main !
La mort a perdu son aiguillon, la peur a perdu son trône :
Jésus est vivant — que toute la terre résonne !`,
      "Idéal en clôture de rassemblement jeunesse ou d'évangélisation avec un fond musical rythmique discret."],
    ['09', 'Fille de la promesse', 'Fille de la promesse, pas une copie conforme', 'Ésaïe 43:4', "Tendre, complice avec une touche d'humour, puis fort et valorisant sur l'estime de soi.", '2 min 15',
`Elle regarde sa copine : « J'aimerais avoir sa taille, sa voix, son style ! »
Elle regarde les écrans : « Tout le monde a l'air brillant, moi je me sens fragile ! »
À force de vouloir copier la voisine de droite ou de gauche,
On finit par laisser son propre trésor au fond de sa poche !

Écoute-moi bien, ma sœur : Dieu ne fait pas de photocopies !
Quand Il t'a pensée, Il n'a pas dit : « Faisons encore la même série ! »
Ésaïe 43:4 te le murmure avec toute sa tendresse :
« Parce que tu as du prix à mes yeux, parce que tu es honorée et que je t'aime... »

Tu n'as pas besoin d'imiter pour exister,
Ni de te rabaisser pour te faire accepter.
Tes dons, ton sourire, ton intelligence et ta foi
Sont uniques — parce que le Roi a mis sa signature en toi !`,
      "Parfait en ouverture d'un atelier « Estime de soi et identité en Christ » pour jeunes filles."],
    ['10', 'Fille de la promesse', 'Ma couronne ne se négocie pas', 'Proverbes 31:25 ; 1 Corinthiens 6:19–20', "Digne, tranchant, plein d'assurance sur le respect de soi et la pureté.", '2 min 15',
`Il arrive avec de grands mots sucrés comme du miel en boîte :
« Si tu m'aimes vraiment, prouve-le ce soir, ne sois pas si droite ! »
Il te promet la lune, les étoiles et tout le firmament,
Mais il veut que tu brades ta dignité dès maintenant !

Pause ! Regarde bien le marché qu'on te propose :
Échanger ton avenir et ta paix contre une promesse rose ?
Le vrai amour ne te pousse jamais à salir ta conscience,
Le vrai respect sait attendre, protéger et honorer ta présence !

Proverbes 31:25 te revêt d'un vêtement qui ne passe pas :
« Elle est revêtue de force et de gloire, et elle se rit de l'avenir ! »
Ton corps est le temple du Saint-Esprit, pas un terrain de jeu :
Garde ta couronne sur la tête — tu es princesse devant Dieu !`,
      "Très percutant lors des campagnes de sensibilisation sur la dignité et les relations saines."],
    ['11', 'Fille de la promesse', 'Écran allumé, vigilance activée', 'Proverbes 4:23', "Actuel, dynamique, avec une pointe d'humour sur les faux profils et les pièges en ligne.", '2 min 15',
`« Salut ma belle, je suis un prince héritier qui cherche une amie sincère... »
Derrière la photo de mannequin, c'est souvent un arnaqueur derrière un verre !
Un clic trop rapide, une photo envoyée dans un moment d'émotion,
Et ce qui était privé fait le tour du quartier sans permission !

Sur Internet, la gomme n'existe pas, tout laisse une trace,
Ce que tu publies aujourd'hui peut te rattraper demain face à face !
Proverbes 4:23 sonne l'alarme avec sagesse :
« Garde ton cœur plus que toute autre chose, car de lui viennent les sources de la vie ! »

Sois connectée, brillante, créative — mais jamais naïve !
Protège ton intimité, trie tes contacts, reste attentive.
Une fille sage sait verrouiller sa porte et garder sa clarté :
Sur les réseaux comme dans la rue, marche dans la vérité !`,
      "Idéal pour introduire un échange pratique sur la sécurité numérique et la pudeur sur les réseaux sociaux."],
    ['12', 'Fille de la promesse', 'Cahier ouvert, avenir debout', 'Daniel 1:17 ; Jérémie 29:11', "Entraînant, rythmé comme un battement de tambour, très motivant pour les études et la vocation.", '2 min 30',
`« À quoi bon réviser quand on peut copier ? »
« À quoi bon étudier quand tout semble bloqué ? »
Voilà les chansons tristes qu'on entend dans les couloirs,
Quand le découragement essaie d'éteindre l'espoir !

Mais regarde Daniel et ses amis à Babylone :
Ils n'ont pas choisi la facilité ni la triche qui déraisonne !
Ils ont travaillé dur, gardé leur foi intacte,
Et Dieu leur a donné dix fois plus de sagesse exacte !

Fille de la promesse, ouvre ton cahier avec fierté !
Ton intelligence est une arme que Dieu veut utiliser !
Étudie avec sérieux, vise l'excellence sans complexe,
Refuse la triche, la paresse et tous les faux réflexes !
Demain, l'Église, la famille et la nation auront besoin de femmes debout,
Formées, intègres, compétentes — et attachées à Dieu jusqu'au bout !`,
      "Parfait pour encourager les collégiennes, lycéennes et étudiantes avant la période des examens."]
  ].map(x => ({ id: 'sl-' + x[0], type: 'Slam', pole: x[1], theme: x[2], ref: x[3], ton: x[4], duree: x[5], desc: x[6], conseil: x[7] }));
  const seed = window.ANIM_SEED, i = seed.findIndex(x => x.type === 'Slam');
  window.ANIM_SEED = seed.filter(x => x.type !== 'Slam');
  window.ANIM_SEED.splice(i < 0 ? window.ANIM_SEED.length : i, 0, ...S);
})();
