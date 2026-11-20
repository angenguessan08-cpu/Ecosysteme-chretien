/* 16 jeux : 8 jeux bibliques (QCM avec validation) + 8 autres jeux (procédé étape par étape + matériel). */
(function () {
  const Q = (q, options, correct, fb) => ({ q, options, correct, fb });
  const B = [
    ['Quiz par équipes', 'Livres de la Bible', 'Compétitif, joyeux et collaboratif (points bonus pour l\'entraide)', '15 à 20 min',
      '30 questions (personnages, livres, versets) en trois manches ; points pour l\'entraide.',
      'Formez 2 à 4 équipes mixtes. Accordez +2 points bonus à chaque fois qu\'une équipe aide un plus jeune membre à formuler la réponse.', [
        Q('1. Quel est le tout premier livre de la Bible et que raconte-t-il au début ?', ['Exode', 'Genèse', 'Psaumes'], 1, 'Bonne réponse : La Genèse ! Elle raconte la création du monde, d\'Adam et Ève, ainsi que l\'histoire des patriarches (Abraham, Isaac, Jacob).'),
        Q('2. Combien de livres compte le Nouveau Testament ?', ['27 livres', '39 livres', '66 livres'], 0, 'Bonne réponse : 27 livres ! (39 dans l\'Ancien Testament + 27 dans le Nouveau Testament = 66 livres au total).'),
        Q('3. Qui a construit l\'arche sur l\'ordre de Dieu avant le déluge ?', ['Moïse', 'Noé', 'Abraham'], 1, 'Bonne réponse : Noé (Genèse 6) ! Il a obéi à Dieu avec persévérance malgré les moqueries autour de lui.'),
        Q('4. Quel jeune berger a vaincu le géant Goliath avec une fronde et une pierre ?', ['David', 'Salomon', 'Samuel'], 0, 'Bonne réponse : David (1 Samuel 17) ! Il a vaincu non par la taille de son armure, mais au nom de l\'Éternel des armées.'),
        Q('5. Quel livre de la Bible contient 150 chants et prières ?', ['Proverbes', 'Psaumes', 'Ésaïe'], 1, 'Bonne réponse : Le livre des Psaumes ! On y trouve des prières de louange, de confiance et de secours dans toutes les saisons de la vie.'),
        Q('6. Dans quelle ville Jésus est-il né ?', ['Nazareth', 'Jérusalem', 'Bethléem'], 2, 'Bonne réponse : Bethléem (Luc 2:4-7), accomplissant ainsi la prophétie de Michée 5:1.'),
        Q('7. Qui a été avalé par un grand poisson après avoir fui l\'ordre de Dieu d\'aller à Ninive ?', ['Jonas', 'Daniel', 'Élie'], 0, 'Bonne réponse : Jonas (Jonas 1-2) ! Après trois jours, il a prié Dieu et a accompli sa mission à Ninive.'),
        Q('8. Quel disciple a marché brièvement sur l\'eau vers Jésus avant de douter ?', ['Jean', 'Pierre', 'André'], 1, 'Bonne réponse : Pierre (Matthieu 14:28-31) ! Tant qu\'il gardait les yeux sur Jésus, il avançait sur les vagues.'),
        Q('9. Quel apôtre a écrit de nombreuses lettres aux Églises (Romains, Corinthiens, Éphésiens...) ?', ['Paul', 'Pierre', 'Jacques'], 0, 'Bonne réponse : L\'apôtre Paul ! Après sa rencontre avec Jésus sur le chemin de Damas, il est devenu un grand missionnaire.'),
        Q('10. Quel est le dernier livre de la Bible ?', ['Jude', 'Actes des Apôtres', 'Apocalypse'], 2, 'Bonne réponse : L\'Apocalypse ! Il annonce le retour glorieux de Jésus-Christ et la victoire finale de Dieu.')]],
    ['Qui suis-je ?', 'Esther, Daniel, Ruth, David', 'Mystérieux, ludique et captivant (indices progressifs)', '15 min',
      'Devinettes de personnages bibliques avec trois indices de plus en plus précis.',
      'Lisez l\'indice 1 (3 points si trouvé), puis l\'indice 2 (2 points), puis l\'indice 3 (1 point) avant de valider.', [
        Q('Énigme 1 — Indice 1 : J\'ai vécu à la cour d\'un roi perse. Indice 2 : J\'ai jeûné trois jours avec mon peuple. Indice 3 : J\'ai risqué ma vie en entrant chez le roi Assuérus sans être appelée. Qui suis-je ?', ['Ruth', 'Esther', 'Débora'], 1, 'C\'est Esther (Esther 4:14-16) ! Elle a dit : « Si je dois périr, je périrai » et Dieu l\'a utilisée pour sauver tout son peuple.'),
        Q('Énigme 2 — Indice 1 : J\'ai refusé de manger les mets souillés du roi de Babylone. Indice 2 : J\'ouvrais ma fenêtre vers Jérusalem pour prier trois fois par jour. Indice 3 : Dieu a fermé la gueule des lions pour me protéger. Qui suis-je ?', ['Daniel', 'Joseph', 'Néhémie'], 0, 'C\'est Daniel (Daniel 1 et 6) ! Sa fidélité dans la prière et l\'intégrité a glorifié Dieu devant les rois.'),
        Q('Énigme 3 — Indice 1 : J\'étais étrangère, originaire de Moab. Indice 2 : J\'ai dit à ma belle-mère : « Ton peuple sera mon peuple, et ton Dieu sera mon Dieu ». Indice 3 : J\'ai glané des épis dans le champ de Boaz. Qui suis-je ?', ['Sara', 'Anne', 'Ruth'], 2, 'C\'est Ruth (Ruth 1:16) ! Sa loyauté et son humilité l\'ont placée dans la lignée de David et de Jésus.'),
        Q('Énigme 4 — Indice 1 : J\'étais le plus jeune de huit frères et je gardais les brebis. Indice 2 : Je jouais de la harpe pour apaiser le roi Saül. Indice 3 : J\'ai écrit le Psaume 23 (« L\'Éternel est mon berger »). Qui suis-je ?', ['David', 'Jonathan', 'Gédéon'], 0, 'C\'est David (1 Samuel 16 ; Psaume 23) ! Un homme selon le cœur de Dieu, à la fois berger, musicien et roi.'),
        Q('Énigme 5 — Indice 1 : Mes frères m\'ont vendu par jalousie. Indice 2 : J\'ai interprété les rêves de Pharaon en Égypte. Indice 3 : J\'ai pardonné à mes frères et sauvé ma famille de la famine. Qui suis-je ?', ['Moïse', 'Joseph', 'Jacob'], 1, 'C\'est Joseph (Genèse 37 à 45) ! Ce que ses frères avaient pensé pour lui faire du mal, Dieu l\'a changé en bien.')]],
    ['Chasse au verset', 'Psaumes et Proverbes', 'Dynamique, actif et exploratoire', '15 à 20 min',
      'Retrouver des versets cachés dans la salle grâce à des indices.',
      'Cachez des enveloppes numérotées dans la salle. Chaque équipe rapporte l\'enveloppe, lit le verset et valide sa référence.', [
        Q('Indice 1 (Près de la porte d\'entrée) : « Ta parole est une lampe à mes pieds, et une lumière sur mon sentier. » Où se trouve ce verset ?', ['Psaume 119:105', 'Psaume 23:1', 'Proverbes 1:7'], 0, 'Validé : Psaume 119:105 ! La Parole de Dieu éclaire chacun de nos pas pour éviter les pièges.'),
        Q('Indice 2 (Sous une chaise au centre) : « Garde ton cœur plus que toute autre chose, car de lui viennent les sources de la vie. » Quelle est sa référence ?', ['Proverbes 3:5', 'Proverbes 4:23', 'Psaume 51:12'], 1, 'Validé : Proverbes 4:23 ! Ce que nous nourrissons dans notre cœur oriente toute notre vie.'),
        Q('Indice 3 (Près du pupitre / table) : « Confie-toi en l\'Éternel de tout ton cœur, et ne t\'appuie pas sur ta sagesse. » Quelle est sa référence ?', ['Psaume 37:4', 'Proverbes 3:5', 'Proverbes 16:3'], 1, 'Validé : Proverbes 3:5 ! Faire confiance à Dieu dépasse nos propres calculs humains.'),
        Q('Indice 4 (Près de l\'accueil / fenêtre) : « L\'Éternel est mon berger : je ne manquerai de rien. » Quelle est sa référence ?', ['Psaume 23:1', 'Psaume 91:1', 'Psaume 100:1'], 0, 'Validé : Psaume 23:1 ! Le Seigneur veille, conduit et pourvoit avec fidélité.')]],
    ['Mimes bibliques', 'Luc 5 à 8', 'Très drôle, théâtral et expressif (sans parler !)', '15 min',
      'Une équipe mime un récit de Jésus, l\'autre devine et cite le passage.',
      'Interdiction absolue de prononcer un mot ou un bruitage pendant le mime : seuls les gestes et expressions du visage comptent !', [
        Q('Mime 1 : Des pêcheurs jettent leurs filets toute la nuit sans rien attraper, puis sur la parole de Jésus, leurs filets se remplissent à craquer ! Quel est ce récit ?', ['La pêche miraculeuse (Luc 5:1-11)', 'La multiplication des pains (Luc 9:10-17)', 'Les noces de Cana (Jean 2:1-11)'], 0, 'Validé : La pêche miraculeuse (Luc 5:1-11) ! Pierre a dit : « Sur ta parole, je jetterai le filet. »'),
        Q('Mime 2 : Quatre amis portent un paralytique sur un brancard, montent sur le toit, enlèvent des tuiles et le descendent devant Jésus ! Quel est ce récit ?', ['L\'aveugle Bartimée (Luc 18:35)', 'La guérison du paralytique descendu par le toit (Luc 5:17-26)', 'La fille de Jaïrus (Luc 8:40-56)'], 1, 'Validé : La guérison du paralytique (Luc 5:17-26) ! Jésus a vu la foi persévérante de ses amis.'),
        Q('Mime 3 : Les disciples rament dans une barque secouée par une énorme tempête pendant que Jésus dort ; Jésus se lève et calme le vent d\'une parole ! Quel est ce récit ?', ['La tempête apaisée (Luc 8:22-25)', 'Le baptême de Jésus (Luc 3:21)', 'La traversée de la mer Rouge (Exode 14)'], 0, 'Validé : La tempête apaisée (Luc 8:22-25) ! Même les vents et les vagues obéissent à la voix de Jésus.')]],
    ['Vrai ou faux', 'Actes 17:11', 'Rapide, malin et formateur (pièges gentils à vérifier dans la Bible)', '10 à 15 min',
      'Affirmations à vérifier dans la Bible, comme les Béréens, avec le verset à l\'appui.',
      'Faites lever la main droite pour VRAI et la main gauche pour FAUX, puis demandez à un volontaire de lire le verset à voix haute.', [
        Q('Affirmation 1 : « Les chrétiens de Bérée examinaient chaque jour les Écritures pour voir si ce qu\'on leur disait était exact. » Vrai ou Faux ?', ['Vrai', 'Faux'], 0, 'VRAI (Actes 17:11) ! Vérifier chaque enseignement dans sa Bible est une excellente habitude spirituelle.'),
        Q('Affirmation 2 : « Moïse a construit l\'arche pour sauver les animaux du déluge. » Vrai ou Faux ?', ['Vrai', 'Faux'], 1, 'FAUX ! C\'est Noé qui a construit l\'arche (Genèse 6:14). Moïse a conduit Israël hors d\'Égypte (Exode).'),
        Q('Affirmation 3 : « Jésus a transformé l\'eau en vin lors d\'un mariage à Cana. » Vrai ou Faux ?', ['Vrai', 'Faux'], 0, 'VRAI (Jean 2:1-11) ! Ce fut le premier miracle accompli par Jésus.'),
        Q('Affirmation 4 : « L\'apôtre Paul s\'appelait David avant sa conversion. » Vrai ou Faux ?', ['Vrai', 'Faux'], 1, 'FAUX ! Il s\'appelait Saul (Saul de Tarse) avant sa rencontre avec Jésus (Actes 9:1-19).'),
        Q('Affirmation 5 : « La Bible dit que l\'amour de l\'argent est une racine de tous les maux. » Vrai ou Faux ?', ['Vrai', 'Faux'], 0, 'VRAI (1 Timothée 6:10) ! Attention à la nuance : c\'est « l\'amour de l\'argent » (la cupidité), et non l\'argent lui-même.')]],
    ['Puzzle des versets', 'Philippiens 4:13', 'Coopératif, rythmé et mémorisable', '10 min',
      'Reconstituer des versets découpés mot par mot, puis les réciter.',
      'Imprimez ou écrivez chaque groupe de mots sur une carte séparée. Une fois assemblé, toute l\'équipe récite le verset d\'une seule voix.', [
        Q('Puzzle 1 — Remets ces morceaux dans le bon ordre : [par celui qui] / [Je puis tout] / [me fortifie.]', ['Je puis tout par celui qui me fortifie. (Philippiens 4:13)', 'Par celui qui me fortifie je puis tout.', 'Me fortifie celui qui je puis tout.'], 0, 'Exact ! « Je puis tout par celui qui me fortifie. » — Philippiens 4:13.'),
        Q('Puzzle 2 — Remets ces morceaux dans le bon ordre : [ne vous inquiétez] / [en toutes choses] / [de rien ; mais] / [faites connaître vos besoins à Dieu.]', ['Ne vous inquiétez de rien ; mais en toutes choses faites connaître vos besoins à Dieu. (Philippiens 4:6)', 'En toutes choses ne vous inquiétez de rien ; mais vos besoins faites connaître.', 'Faites connaître vos besoins à Dieu ; mais ne vous inquiétez en toutes choses.'], 0, 'Exact ! « Ne vous inquiétez de rien ; mais en toutes choses faites connaître vos besoins à Dieu par des prières et des supplications, avec des actions de grâces. » — Philippiens 4:6.'),
        Q('Puzzle 3 — Remets ces morceaux dans le bon ordre : [Car Dieu a tant aimé] / [qu\'il a donné] / [le monde] / [son Fils unique.]', ['Car Dieu a tant aimé le monde qu\'il a donné son Fils unique. (Jean 3:16)', 'Qu\'il a donné son Fils unique car Dieu a tant aimé le monde.', 'Le monde a tant aimé Dieu qu\'il a donné son Fils unique.'], 0, 'Exact ! « Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle. » — Jean 3:16.')]],
    ['Course des livres', 'Ancien et Nouveau Testament', 'Énergique, rapide et stimulant (relais d\'équipe)', '10 à 15 min',
      'Relais : classer les livres de la Bible dans l\'ordre.',
      'Distribuez des cartes portant chacune le nom d\'un livre biblique : les joueurs doivent se placer côte à côte dans le bon ordre chronologique.', [
        Q('Manche 1 (Pentateuque) — Quel est l\'ordre exact des 5 premiers livres de la Bible ?', ['Genèse, Exode, Lévitique, Nombres, Deutéronome', 'Genèse, Lévitique, Exode, Deutéronome, Nombres', 'Exode, Genèse, Nombres, Lévitique, Deutéronome'], 0, 'Parfait ! Genèse → Exode → Lévitique → Nombres → Deutéronome (les 5 livres de la Loi).'),
        Q('Manche 2 (Les 4 Évangiles) — Dans quel ordre apparaissent les 4 Évangiles dans le Nouveau Testament ?', ['Luc, Matthieu, Marc, Jean', 'Matthieu, Marc, Luc, Jean', 'Jean, Matthieu, Luc, Marc'], 1, 'Parfait ! Matthieu → Marc → Luc → Jean.'),
        Q('Manche 3 (Livres poétiques) — Quel est l\'ordre exact de ces trois livres ?', ['Psaumes, Proverbes, Ecclésiaste', 'Proverbes, Psaumes, Ecclésiaste', 'Ecclésiaste, Psaumes, Proverbes'], 0, 'Parfait ! Job → Psaumes → Proverbes → Ecclésiaste → Cantique des Cantiques.')]],
    ['Le fruit de l\'Esprit', 'Galates 5:22–23', 'Pratique, concret et appliqué à la vie quotidienne', '15 min',
      'Cartes : associer chaque fruit de l\'Esprit à une situation de la vie.',
      'Les 9 facettes du fruit de l\'Esprit (Galates 5:22-23) : amour, joie, paix, patience, bonté, bénignité, fidélité, douceur, tempérance.', [
        Q('Situation 1 : Un camarade te bouscule exprès et se moque de toi devant la classe. Au lieu de te venger ou de l\'insulter, tu gardes ton calme et tu lui réponds avec respect. Quel fruit de l\'Esprit mets-tu en pratique ?', ['La maîtrise de soi et la douceur', 'La jalousie', 'L\'impatience'], 0, 'Exact ! La douceur et la maîtrise de soi (Galates 5:22-23) désamorcent la colère et honorent Jésus.'),
        Q('Situation 2 : La file d\'attente à la cantine ou au transport est très longue et tout le monde râle. Tu restes serein(e) et tu encourages ceux autour de toi. Quel fruit de l\'Esprit s\'exprime ici ?', ['La patience et la paix', 'La précipitation', 'La dispute'], 0, 'Exact ! La patience et la paix permettent de rester stable même quand les circonstances sont lentes.'),
        Q('Situation 3 : Un nouvel élève arrive à l\'église ou à l\'école et reste tout seul dans son coin. Tu vas vers lui avec le sourire pour l\'accueillir et partager ton repas. Quel fruit de l\'Esprit agis-tu ?', ['L\'amour, la bonté et la bienveillance', 'L\'indifférence', 'L\'orgueil'], 0, 'Exact ! L\'amour, la bonté et la bienveillance rendent l\'Évangile visible par des gestes simples.')]]
  ].map((x, i) => ({ id: 'jb-' + String(i + 1).padStart(2, '0'), type: 'Jeu biblique', theme: x[0], ref: x[1], ton: x[2], duree: x[3], desc: x[4], conseil: x[5], questions: x[6] }));

  const O = [
    ['Relais d\'entraide', 'Galates 6:2', 'Dynamique, sportif et solidaire', '15 à 20 min', 'Parcours en équipes où chacun doit aider un coéquipier à franchir l\'épreuve.', [
      '1. Préparation du terrain : Tracez un parcours de 15 à 20 mètres avec 3 obstacles simples (plots à contourner, ligne à franchir ensemble, objet à transporter à deux sans les mains).',
      '2. Constitution des équipes : Formez des équipes équilibrées de 4 à 6 joueurs (mélangeant les âges).',
      '3. Règle d\'or (Galates 6:2) : Aucun joueur n\'a le droit de franchir la ligne d\'arrivée seul. Chaque binôme ou équipe doit rester relié (par un foulard tenu ensemble ou main dans la main) et aider celui qui rencontre une difficulté.',
      '4. Déroulement : Au signal, les équipes avancent. Si un membre lâche ou passe sans attendre son coéquipier, l\'équipe marque une pause de 5 secondes pour se regrouper.',
      '5. Validation & Partage : L\'équipe gagnante est celle qui franchit la ligne au complet avec le meilleur esprit d\'entraide. Terminez en lisant Galates 6:2 (« Portez les fardeaux les uns des autres »).'],
      ['Plots ou bouteilles d\'eau', 'Foulards ou rubans', 'Un ballon ou livre léger par équipe']],
    ['Chaîne de compliments', '1 Thessaloniciens 5:11', 'Chaleureux, bienveillant et édifiant', '10 à 15 min', 'Chacun encourage son voisin avec une phrase sincère ; thème : l\'encouragement.', [
      '1. Installation : Tous les participants s\'assoient ou se tiennent debout en un grand cercle afin que chacun puisse voir tout le groupe.',
      '2. Lancement de la chaîne : L\'animateur tient une pelote de laine (ou un ballon) et regarde une personne du cercle. Il lui adresse un encouragement sincère sur une qualité observée (ex. « J\'apprécie ta joie et ta disponibilité pour aider »).',
      '3. Transmission du fil : Tout en gardant le bout de la ficelle en main, il lance la pelote à la personne encouragée, qui à son tour en encourage une autre qui n\'a pas encore reçu la pelote.',
      '4. Règle de sincérité : Interdiction des moqueries ou des compliments superficiels sur les vêtements ; on valorise le caractère, les efforts, la gentillesse ou les talents.',
      '5. Clôture visuelle : Une fois que tout le monde est relié par la toile de laine, montrez comment chaque parole édifiante tisse l\'unité du groupe selon 1 Thessaloniciens 5:11.'],
      ['Une pelote de laine ou de ficelle (ou un ballon léger)']],
    ['Confiance en marche', 'Proverbes 3:5', 'Calme, attentif et profond sur l\'écoute et la confiance', '15 min', 'Guider un coéquipier aux yeux bandés par la voix seule ; thème : la confiance.', [
      '1. Formation des binômes : Chaque équipe se compose d\'un « Marcheur » (aux yeux bandés avec un foulard propre) et d\'un « Guide ».',
      '2. Mise en place des obstacles : Disposez quelques chaises ou coussins espacés dans la salle en toute sécurité.',
      '3. Règle de guidage : Le Guide n\'a pas le droit de toucher le Marcheur ; il doit le diriger uniquement avec une voix calme et claire (« Deux pas tout droit », « Tourne légèrement à gauche », « Stop »).',
      '4. Inversion des rôles : Une fois arrivé au point d\'arrivée, on inverse les rôles pour que chacun expérimente à la fois le fait de guider et celui de faire confiance.',
      '5. Débriefing biblique : Échangez 3 minutes sur ce que l\'on ressent quand on ne voit pas le chemin, en lien avec Proverbes 3:5 (« Confie-toi en l\'Éternel de tout ton cœur »).'],
      ['Foulards propres pour bander les yeux', 'Chaises ou plots souples']],
    ['Chasse au trésor du quartier', 'Matthieu 25:35–40', 'Aventureux, missionnaire et tourné vers le service concret', '30 à 45 min', 'Les équipes accomplissent de petites actions de service pour gagner des indices.', [
      '1. Briefing sécurité & encadrement : Formez des équipes de 4 à 5 jeunes accompagnées chacune d\'un adulte ou responsable référent.',
      '2. Remise de la feuille de route : Chaque équipe reçoit une enveloppe contenant 4 missions de service concret et bienveillant à accomplir dans l\'enceinte de l\'église ou du voisinage immédiat.',
      '3. Exemples de missions : (a) Ramasser 10 déchets pour rendre la cour propre ; (b) Offrir un verre d\'eau fraîche ou un sourire et un verset écrit à 3 personnes ; (c) Aider un responsable à ranger des chaises ; (d) Prier ensemble pour une famille du quartier.',
      '4. Validation des étapes : À chaque mission accomplie, le responsable valide l\'étape et remet un indice menant au « Trésor final » (un coffret contenant des versets personnalisés et un goûter à partager).',
      '5. Conclusion : Lecture de Matthieu 25:40 (« Toutes les fois que vous avez fait ces choses à l\'un de ces plus petits... c\'est à moi que vous les avez faites »).'],
      ['Enveloppes d\'indices', 'Cartes de versets', 'Sacs poubelle / gobelets d\'eau', 'Coffret goûter final']],
    ['Chaises musicales de la gratitude', 'Psaume 136:1', 'Joyeux, rythmé et plein de reconnaissance (sans élimination frustrante !)', '10 à 15 min', 'À chaque arrêt de la musique, dire un motif de reconnaissance.', [
      '1. Installation : Placez des chaises en cercle (une chaise de moins que le nombre de participants).',
      '2. Musique et mouvement : Lancez un chant de louange joyeux ; tout le monde marche ou danse autour des chaises.',
      '3. Arrêt de la musique : Dès que la musique s\'arrête, chacun s\'assoit. La personne qui reste debout prend le micro (ou parle à voix haute) et cite un motif précis de gratitude envers Dieu (ex. « Merci Seigneur pour la santé de ma maman », « Merci pour la pluie »).',
      '4. Variante coopérative : Au lieu d\'éliminer des joueurs, on retire une chaise à chaque tour et tout le groupe doit trouver comment s\'entraider pour que personne ne touche le sol !',
      '5. Clôture : Répétez ensemble Psaume 136:1 (« Louez l\'Éternel, car il est bon, car sa miséricorde dure à toujours ! »).'],
      ['Chaises solides', 'Enceinte audio avec musique joyeuse']],
    ['Tournoi fair-play', 'Colossiens 3:23', 'Sportif, enthousiaste et exemplaire dans le respect mutuel', '30 à 45 min', 'Volley ou football avec points bonus pour le fair-play et l\'esprit d\'équipe.', [
      '1. Règle du double score : Chaque match attribue des points pour les buts/points marqués (1 point), mais attribue +3 points bonus pour les gestes de fair-play.',
      '2. Critères des points bonus : Encourager un coéquipier qui a raté une passe, aider un adversaire à se relever, reconnaître honnêtement une faute, inclure tous les joueurs dans le jeu.',
      '3. Pénalité de mauvaise humeur : Toute plainte envers l\'arbitre ou moquerie annule les points bonus de la manche.',
      '4. Temps mort prière : Avant le coup d\'envoi et à la fin du tournoi, les deux équipes se réunissent au centre du terrain pour se saluer et remercier Dieu pour la joie et la santé.',
      '5. Verset phare : Colossiens 3:23 (« Tout ce que vous faites, faites-le de bon cœur, comme pour le Seigneur »).'],
      ['Ballon de football ou de volley', 'Chasubles de couleurs', 'Sifflet et tableau de score']],
    ['Jeu de rôles : bien décider', 'Proverbes 14:15', 'Interactif, réaliste et formateur sur le discernement au quotidien', '20 min', 'Dilemmes de la vie courante discutés en groupe : que ferais-tu ?', [
      '1. Tirage d\'une carte Dilemme : Un petit groupe de 3 volontaires tire une situation concrète (ex. : « On te propose les réponses d\'un examen », « Un groupe critique une camarade absente », « On t\'invite à une fête où circulera de l\'alcool »).',
      '2. Mise en scène rapide (2 minutes) : Les volontaires jouent la situation et s\'arrêtent juste au moment où il faut prendre une décision (« Gel sur image ! »).',
      '3. Débat du public : L\'animateur demande à l\'assemblée : « Que ferais-tu à sa place et quel verset biblique peut éclairer ce choix ? »',
      '4. Reprise avec la bonne décision : Les acteurs rejouent la fin de la scène en appliquant la décision sage et courageuse proposée par le groupe.',
      '5. Synthèse : Lecture de Proverbes 14:15 (« L\'homme simple croit tout ce qu\'on dit, mais l\'homme prudent est attentif à ses pas »).'],
      ['5 à 8 cartes de situations / dilemmes', 'Une Bible pour vérifier les repères']],
    ['Soirée jeux de société sans écran', 'Ecclésiaste 3:1', 'Convivial, détendu, complice et 100 % déconnecté', '45 à 60 min', 'Tournoi amical ; thème : il y a un temps pour tout, y compris pour se reposer.', [
      '1. Panier « Mode Avion » : À l\'entrée, chacun dépose volontairement son téléphone en mode silencieux dans un panier sécurisé pour profiter pleinement des échanges réels.',
      '2. Rotation par tables : Installez 4 à 5 tables avec des jeux variés (Awalé, Uno, Scrabble, Dames, Ludo, Pictionary biblique, Jenga). Toutes les 15 minutes, une cloche sonne et les joueurs changent de table.',
      '3. Défi convivialité : À chaque changement de table, chaque joueur salue ses nouveaux partenaires et partage une anecdote drôle ou un bon souvenir de la semaine.',
      '4. Pause rafraîchissement : Prévoyez un moment simple autour de jus naturels (bissap, gingembre) et de gâteaux pour favoriser l\'amitié fraternelle.',
      '5. Mot de fin : Méditation courte sur Ecclésiaste 3:1 (« Il y a un temps pour tout... un temps pour rire ») : la joie saine et le repos font partie de l\'équilibre chrétien.'],
      ['Jeux de société variés (Awalé, cartes, plateau)', 'Un panier d\'accueil pour les téléphones', 'Une clochette et des rafraîchissements']]
  ].map((x, i) => ({ id: 'ja-' + String(i + 1).padStart(2, '0'), type: 'Jeu (autre)', theme: x[0], ref: x[1], ton: x[2], duree: x[3], desc: x[4], procede: x[5], materiel: x[6] }));

  const seed = window.ANIM_SEED.filter(x => x.type !== 'Jeu biblique' && x.type !== 'Jeu (autre)');
  window.ANIM_SEED = seed.concat(B, O);
})();
