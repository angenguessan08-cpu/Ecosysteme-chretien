# Écosystème Chrétien — Audit initial et refonte de l'accueil

**Version de travail :** 7.1  
**Date :** 19 novembre 2026  
**Périmètre inspecté :** archive fournie, dossier `app/`, fichiers HTML, CSS, JavaScript, JSON, PWA, README et schémas SQL.

## 1. Résumé exécutif

L'application fournie est une application monopage en JavaScript natif, installable comme PWA et dotée d'un mode hors connexion. Elle contient cinq espaces de contenus. Avant cette intervention, elle ne possédait pas de page d'accueil générale : l'état initial ouvrait directement l'espace P1 (« Fille de la promesse »). La vue « Vue Globale Transversale » est un outil de suivi et de recherche, pas une page d'accueil éditoriale.

La première refonte a donc été réalisée dans le code existant : ajout d'un accueil général, accès aux cinq espaces, parole du jour basée sur les ressources déjà présentes, raccourcis vers les fonctions transversales, correction de la navigation mobile et clarification des mentions de confidentialité.

## 2. Inventaire des contenus constatés

Les quantités suivantes ont été calculées à partir des tableaux du fichier `data.js` :

| Espace | Tableau | Nombre d'enregistrements |
|---|---|---:|
| P1 — Fille de la promesse | `p1` | 42 |
| P2 — Élan Famille | `p2` | 383 |
| P3 — Fondement vie spirituelle | `p3` | 31 |
| P4 — Génération Lumière | `p4` | 10 |
| P5 — Source de vie | `p5` | 66 |
| **Total** | | **532** |

Le référentiel `spaces` et les données contiennent bien P1 à P5. Les noms de référence sont ceux présents dans `data.js`.

## 3. Constats fonctionnels sur l'accueil et la navigation

| ID | Constat vérifié | Niveau | Traitement V7.1 |
|---|---|---|---|
| HOME-01 | Aucun écran d'accueil général ; lancement direct sur P1 | Élevé | Corrigé : nouvel accueil général |
| NAV-01 | La navigation latérale ne proposait pas d'entrée Accueil | Élevé | Corrigé |
| NAV-02 | La barre mobile produisait sept boutons alors que la grille CSS était prévue pour cinq colonnes | Élevé | Corrigé : cinq entrées principales, les autres espaces dans le menu |
| NAV-03 | Le libellé du carnet annonçait « 100 % Local » alors que la synchronisation Supabase peut être activée | Élevé | Corrigé : libellé neutre « Carnet personnel » |
| NAV-04 | La version affichée dans le pied de navigation était 6.0 alors que le README annonce 7.0 | Moyen | Harmonisé à 7.0 dans le panneau latéral ; version de refonte 7.1 documentée |
| GLOBAL-01 | Le total global excluait P5 | Élevé | Corrigé : total calculé sur les cinq tableaux |
| GLOBAL-02 | Les textes de la vue globale parlaient de trois ou quatre espaces | Moyen | Corrigés pour cinq espaces |
| META-01 | La description SEO ne mentionnait que trois espaces | Moyen | Corrigée |
| PRIV-01 | Le pied de page pouvait laisser croire que les données n'étaient jamais synchronisées | Élevé | Clarifié : local par défaut, synchronisation volontaire |

## 4. Composition de l'accueil V7.1

1. Hero institutionnel « Grandir dans la foi, à chaque étape de la vie ».
2. Parole du jour avec date et référence, choisie parmi les ressources bibliques structurées existantes.
3. Présentation des cinq espaces avec leur nom, leur descriptif et le nombre de ressources.
4. Raccourcis vers actualités, programmes, créativité/jeux et espace personnel.
5. Mise en avant d'une méditation existante.
6. Mention de prudence indiquant que les ressources ne remplacent pas l'accompagnement pastoral ou professionnel approprié.

La page n'affiche pas de score spirituel. Les chiffres présentés sont des volumes documentaires, pas une mesure de la foi ou de la valeur des personnes.

## 5. Fichiers modifiés

- `app/app.js` : route d'accueil, migration de première ouverture, navigation, calcul du total global et rendu de l'accueil.
- `app/styles.css` : styles responsive de l'accueil.
- `app/index.html` : description de page et formulation de confidentialité.
- `app/sw.js` : version de cache portée à `ec-v10.22.0`.
- `app/data.js` : commentaire d'inventaire corrigé.
- `app/README.md` : documentation de la version 7.1 et inventaire actualisé.

## 6. Points restant à traiter dans les phases suivantes

### Critiques avant ouverture publique

- Le carnet et les notes synchronisées sont stockés en texte lisible dans les colonnes `title` et `body` de `private_notes`. Les politiques RLS isolent les lignes par propriétaire, mais ce n'est pas du chiffrement de bout en bout. La promesse de confidentialité doit rester précise jusqu'à implémentation et test du chiffrement.
- Les tranches d'âge présentes dans les données P1 sont féminines (8–100 ans), alors que la décision produit est une plateforme pour tous les publics. Il faut séparer les catégories éditoriales des publics généraux et construire un référentiel d'âge cohérent, avec parcours spécifiques aux mineurs.
- Le schéma SQL de synchronisation couvre trois familles de données (`private_notes`, `user_progress`, `synced_cards`) et n'est pas encore le modèle métier complet des cinq espaces, contenus, églises, modération, formations et événements.
- La protection des mineurs, les consentements parentaux, les règles de modération et la conformité à la législation ivoirienne sur les données personnelles nécessitent une spécification dédiée et une validation compétente.

### Fonctionnel et éditorial

- Les noms des cinq espaces doivent être harmonisés dans les textes, menus, métadonnées, documentation et contenus.
- Le référentiel des âges P1 doit être revu : la promesse produit « tous les âges et tous les publics » ne correspond pas encore aux catégories féminines de `ageGroups`.
- Les contenus doivent être inventoriés, dédoublonnés, attribués et dotés de métadonnées éditoriales (auteur/source, droits, âge cible, date, statut et version).
- Le flux d'actualités, les médias et les contenus distants doivent être audités pour leur disponibilité, leur attribution et leur comportement hors ligne.
- Une administration centrale avec circuit de soumission, révision, validation, publication et journal d'audit reste à développer.

### Technique et qualité

- `app.js` concentre encore l'état, les rendus, les interactions, les données personnelles, la synchronisation et plusieurs outils dans un seul fichier volumineux.
- Les tests automatisés et tests de navigation mobile ne sont pas fournis dans l'archive.
- Le contrôle d'exécution visuelle avec Chromium n'a pas abouti dans l'environnement de vérification (le processus headless est resté bloqué). Les fichiers JavaScript ont passé `node --check`, mais cela ne remplace pas un test navigateur réel.
- La migration vers une architecture Web/Android distincte (Next.js/TypeScript et Flutter, selon le cahier des charges directeur) reste à planifier ; la PWA existante est conservée pendant la transition.

## 7. Vérifications réalisées

- Extraction de l'archive et inspection des fichiers.
- Vérification syntaxique Node.js de `app.js`, `data.js` et `sw.js`.
- Lecture du référentiel `spaces` et comptage des cinq tableaux de contenus.
- Vérification des chemins de navigation, des libellés et des éléments de configuration PWA.

**Limite de validation :** aucune connexion à un projet Supabase ou à un dépôt Git distant n'a été effectuée. Aucune publication en ligne ni migration de base de données n'a été réalisée.

## 8. Ordre de continuation recommandé

1. Audit détaillé des cinq espaces et de toutes les pages modales.
2. Audit du patrimoine éditorial et du contenu documentaire joint.
3. Refonte de la bibliothèque et des pages de détail de ressource.
4. Refonte du carnet, de la synchronisation et de la sécurité.
5. Modèle de données central et migrations SQL.
6. Administration centrale et gouvernance des contributions d'églises.
7. Accessibilité, mode hors connexion et tests automatisés.
8. Application Android et synchronisation multi-appareils.
9. Groupe pilote, recette de sécurité et lancement.
