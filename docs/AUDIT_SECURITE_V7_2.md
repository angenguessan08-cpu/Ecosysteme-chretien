# Audit fonctionnel, éditorial et sécurité — Écosystème Chrétien

**Version de travail :** V7.2  
**Date :** 19 novembre 2026  
**Périmètre :** application PWA fournie, cinq espaces de ressources, interactions, synchronisation Supabase et documents/SQL joints à l'archive.

## 1. Résultat exécutif

La V7.1 a rétabli un accueil général et une navigation mobile à cinq entrées. Le présent audit confirme que l'application est encore un portail PWA local-first, et non la plateforme centrale multi-utilisateurs décrite dans le dossier technique « Filles de Promesse ».

Le patrimoine de contenu est conséquent : **532 ressources** dans cinq espaces. L'application propose des bibliothèques filtrables, un suivi de lecture/prière, des programmes et rappels, un carnet personnel, des outils de prière familiale, des actualités, des vidéos, des exports/imports et une synchronisation Supabase facultative.

La priorité avant toute ouverture publique n'est pas une migration précipitée vers Android : c'est la sécurisation du modèle d'identité et des données personnelles, la clarification du périmètre produit et la mise en place d'une gouvernance éditoriale centrale.

## 2. Cartographie fonctionnelle observée

### 2.1 Routes principales

| Route / vue | Fonction | État constaté |
|---|---|---|
| Accueil général | Présentation des cinq espaces, parole du jour, raccourcis | Ajouté en V7.1 |
| Vue globale | Recherche transversale et suivi agrégé des ressources/progressions | Présente ; ce n'est pas un tableau d'administration |
| P1 — Fille de la promesse | Méditations, quiz, modules, prières, défis, ateliers, communauté et programmes | Présent |
| P2 — Élan Famille | Bibliothèque de sujets de prière enfants, parents et encadreurs ; outils de prière familiale | Présent |
| P3 — Fondement vie spirituelle | Enseignements sur offrandes, autels, alliances, consécration et monde numérique | Présent |
| P4 — Génération Lumière | Ressources jeunesse et formation | Présent |
| P5 — Source de vie | Prières générales, bénédictions et délivrance | Présent |

Chaque espace a deux onglets : **Bibliothèque** et **Programme & rappels**. Les bibliothèques utilisent recherche, filtres hiérarchiques, affichage en cartes/arborescence, pagination et fiches détaillées.

### 2.2 Fonctions transversales et panneaux

- Détail d'une ressource : marquer comme lue/priée, copier, partager, ouvrir un quiz et ajouter une réflexion au carnet.
- Carnet personnel : création, édition, filtre par statut (En cours, Exaucée, Archivée), archivage logique et suppression logique.
- Registre de personnes : ajout individuel ou en lot, sélection et personnalisation de prières.
- Minuteur « 15 min avec Dieu » et générateur de culte familial.
- Profil/préférences : nom, taille de texte, installation PWA et accès à la synchronisation.
- Actualités : flux distant/JSON, ajout à la liste de sujets à prier et suppression.
- Programmes : tâches périodiques, rappels visuels, notifications navigateur et export calendrier `.ics`.
- Synchronisation : Supabase, authentification anonyme ou e-mail, export/import JSON et points de restauration locaux.
- Autres vues : guide, présentation, progression et capsules vidéo.

Le code contient **79 actions déléguées** dans le gestionnaire central. Le fichier `app.js` concentre encore état, rendu, événements, logique métier, persistance et synchronisation ; il reste monolithique.

## 3. Inventaire et cohérence éditoriale

### 3.1 Volumes confirmés dans `data.js`

| Espace | Volume |
|---|---:|
| P1 — Fille de la promesse | 42 |
| P2 — Élan Famille | 383 |
| P3 — Fondement vie spirituelle | 31 |
| P4 — Génération Lumière | 10 |
| P5 — Source de vie | 66 |
| **Total** | **532** |

Les 383 entrées de P2 se répartissent en 176 sujets `CHILD`, 160 `PARENT` et 47 `MINISTER`. P1 comprend 8 méditations, 5 quiz, 8 modules, 6 prières, 5 défis, 7 ateliers, 1 ressource communautaire et 2 programmes.

P3 est structuré en cinq modules : 11, 3, 3, 7 et 7 ressources. Le document `LES FONDEMENTS DE LA VIE SPIRITUELLE .docx` annonce une compilation de **24 enseignements** ; l'application comporte 31 thèmes, dont les thèmes 25 à 31 sur la vie chrétienne et le monde numérique. Ces sept ressources supplémentaires doivent être considérées comme un complément éditorial, pas comme faisant partie des 24 enseignements de la compilation, tant que leur source éditoriale n'est pas formellement confirmée.

### 3.2 Documents Filles de Promesse

Le dossier PDF V1.1 et le DOCX « Filles_de_Promesse » décrivent une plateforme Web et Android, une base PostgreSQL/Supabase centrale, une bibliothèque commune, des contributions d'églises soumises à validation et une administration centrale. Ils décrivent un public féminin intergénérationnel de 8 à 100 ans.

Ce périmètre n'est pas encore matérialisé dans l'application actuelle : aucune inscription/gestion de comptes dans l'interface courante, aucun portail contributrice, aucun workflow de validation et aucune administration centrale opérationnelle n'ont été observés. La synchronisation Supabase actuelle ne couvre que les fiches personnelles, la progression et les notes.

**Écart à traiter sans fusionner arbitrairement les référentiels :**
- `data.js` définit cinq tranches féminines continues de 8 à 100 ans ;
- le seed SQL `sujets_priere_enfants_seed.sql` ajoute une tranche 0–7 ans ;
- le PDF V1.1 de Filles de Promesse indique 8–100 ans ;
- le DOCX V1.0/V1.1 comporte une formulation 0–7 ans dans son tableau de tranches.

Le référentiel d'âge doit donc être versionné et décidé avant toute migration. Le parcours 0–7 ans peut relever d'un module famille/parents plutôt que d'un compte personnel d'enfant ; cette option est une recommandation d'architecture, pas une décision déjà inscrite dans le code.

## 4. Audit de sécurité et données

### 4.1 Synchronisation de l'application actuelle

Le fichier `app/schema_sync_supabase.sql` met en place une isolation par propriétaire (`user_id = auth.uid()`) pour `private_notes`, `user_progress` et `synced_cards`, avec accès accordé au rôle `authenticated` et retrait des droits `anon`. C'est une amélioration par rapport à l'ancienne migration permissive.

**Limite majeure : les colonnes `private_notes.title` et `private_notes.body` sont stockées en clair dans PostgreSQL.** La RLS limite l'accès par compte mais ne chiffre pas le contenu. La formulation correcte est « données isolées par compte via RLS », pas « chiffrement de bout en bout » ni « inaccessible techniquement à l'administrateur de la base ».

Les sessions anonymes facilitent l'usage sur un appareil, mais ne constituent pas une identité récupérable sur un autre appareil sans rattachement à un compte. L'interface actuelle le précise partiellement.

### 4.2 Ancienne migration dangereuse

`gemini-code-1795077143555.sql` créait une politique `synced_cards` avec `USING (true)` et `WITH CHECK (true)`, autorisant un accès transversal aux lignes si les privilèges de table le permettaient. Le fichier a été neutralisé en V7.2 : il porte désormais un avertissement et ne crée plus de politique. Le schéma actuel supprime explicitement cette ancienne politique avant de créer la politique propriétaire.

Ne pas exécuter une ancienne copie de ce script issue d'un autre emplacement ou d'une sauvegarde.

### 4.3 Schéma métier de référence incomplet côté RLS

`gemini-code-1794842150852.sql` contient un modèle métier plus large (comptes, profils, rôles, églises, contenus, prières, jeux, défis, événements, signalements et journaux). Toutefois, RLS n'est activée que sur `profiles`, `private_prayer_entries`, `user_progress` et `contents` dans ce fichier. Les tables d'identité, de rôles, d'églises et plusieurs tables liées ne disposent pas ici d'une politique dédiée complète.

Le fichier a été marqué comme brouillon non exécutable en production. Il ne faut pas le lancer tel quel sur un projet Supabase réel. Les politiques doivent être définies table par table, par rôle et par opération, puis testées avec des comptes distincts (participante, contributrice, modératrice, administratrice).

### 4.4 Corrections SQL réalisées en V7.2

- Clarification des commentaires : RLS ne signifie pas chiffrement.
- Correction de la fonction `set_updated_at()` : la date est maintenant actualisée lors d'une mise à jour, au lieu de ne changer que si elle est nulle.
- Ajout du déclencheur de mise à jour pour `user_progress`.
- Neutralisation du script historique à politique permissive.
- Avertissement explicite sur le caractère incomplet du schéma métier V1.1.

Ces modifications sont des corrections de fichiers SQL locaux. **Aucune base distante n'a été modifiée ni testée.**

## 5. Protection des mineures et gouvernance

Les documents de conception prévoient une protection renforcée des mineures, l'absence de messagerie privée libre, des activités collectives encadrées, et des statistiques agrégées. Le README actuel recommande deux adultes responsables et un accord écrit parental pour les sorties, photos et vidéos.

Avant lancement public, il faut transformer ces principes en contrôles effectifs : minimisation des données, profils adaptés à l'âge, règles d'accès, consentements contextualisés, modération, signalement, conservation/suppression, gestion des incidents et contrôle des contenus sensibles. L'absence d'accord parental bloquant à l'inscription, telle que formulée dans le dossier V1.1, ne dispense pas de définir les obligations légales et les mesures de protection applicables aux mineures en Côte d'Ivoire. Une validation juridique locale est nécessaire.

## 6. Tests automatisés ajoutés

Le fichier `app/tests/data-integrity.test.js` utilise uniquement le module natif `node:test`. Il vérifie :

1. la présence des cinq espaces ;
2. les volumes de référence (42, 383, 31, 10, 66 ; total 532) ;
3. l'unicité des identifiants de ressources ;
4. la continuité des tranches d'âge 8–100 ans ;
5. la validité des codes d'âge utilisés par P1.

Commande depuis le dossier `app/` :

```bash
node --test tests/data-integrity.test.js
```

Résultat de la campagne locale V7.2 : **5 tests réussis, 0 échec**. Les vérifications syntaxiques `node --check` restent également nécessaires. Ces tests ne remplacent pas une recette navigateur, une revue de sécurité ni des tests d'isolation RLS sur une base Supabase.

## 7. État de maturité et priorités

| Domaine | État | Priorité |
|---|---|---|
| Accueil et navigation PWA | Fonctionnel en code ; validation navigateur encore manquante | Haute |
| Bibliothèques et données | 532 ressources inventoriées ; provenance/droits à documenter | Haute |
| Programmes et suivi local | Présents | Moyenne |
| Carnet personnel | Présent ; cloud en clair sous RLS | Critique avant cloud public |
| Comptes et profils centralisés | Non implémentés dans l'interface actuelle | Critique |
| Administration et workflow éditorial | Non implémentés | Critique |
| Gouvernance multi-églises | Décrite dans le dossier, non opérationnelle | Haute |
| Protection mineurs | Principes documentés, contrôles incomplets | Critique |
| Android natif | Non présent ; PWA uniquement | Après backend sécurisé |
| IA | À garder en phase 2 conformément au cadrage | Basse à ce stade |

## 8. Décisions d'architecture recommandées pour la suite

1. Conserver la PWA V7.x comme version de transition et sauvegarder les données locales existantes.
2. Séparer les projets/référentiels « Écosystème Chrétien » et « Filles de Promesse » dans les documents et les migrations, puis établir explicitement leur relation fonctionnelle.
3. Définir un modèle central versionné : utilisateurs/profils, tranches d'âge, rôles, églises contributrices, contenus, versions éditoriales, ciblage d'âge, validation, événements, signalements, audit et progression.
4. Concevoir les politiques RLS en deny-by-default, avec tests négatifs d'accès croisé. Aucun compte d'église ne doit lire les profils ou carnets individuels.
5. Concevoir le chiffrement des notes privées avant de promettre un carnet chiffré : chiffrement côté client, gestion/récupération des clés et conséquences de la perte de mot de passe à documenter.
6. Migrer progressivement le monolithe JS vers des modules testables, sans réécrire les 532 contenus ni supprimer les données locales.
7. Construire ensuite l'administration Web et l'application Android sur les mêmes services API et le même modèle de données.

## 9. Fichiers touchés en V7.2

- `app/schema_sync_supabase.sql` : commentaire de sécurité corrigé, déclencheurs `updated_at` corrigés/complétés.
- `gemini-code-1795077143555.sql` : ancienne migration permissive neutralisée.
- `gemini-code-1794842150852.sql` : avertissement de brouillon non prêt pour la production.
- `app/tests/data-integrity.test.js` : suite de tests statiques de cohérence des données.

Aucune donnée de contenu n'a été supprimée ou réécrite dans cette phase.
