# Plan de livraison et de recette — version V8

## Livré dans le dépôt
- V7.1 : accueil général, navigation mobile ramenée à cinq entrées, total des cinq espaces et clarifications de confidentialité.
- V7.2 : audit fonctionnel/sécurité, neutralisation du SQL permissif historique, corrections de déclencheurs, tests de cohérence des données.
- V8 : architecture cible documentée, migration centrale additive, matrice de recette RLS et garde-fous éditoriaux.

## Tests locaux exécutés
- `node --check app/app.js`
- `node --check app/data.js`
- `node --check app/sw.js`
- `node --test app/tests/data-integrity.test.js`
- `node --test app/tests/platform-architecture.test.js`

## Recette non exécutée (dépendances externes)
- Exécution SQL sur Supabase de préproduction et tests RLS multi-comptes.
- Parcours navigateur complet sur Chrome/Firefox/Safari et Android réel.
- Vérification d'installation PWA, notifications, mode hors-ligne et restauration.
- Revue juridique locale sur données personnelles et mineures.
- Vérification des droits d'auteur des textes, prières, images, vidéos et traductions bibliques.
- Déploiement, domaine, comptes stores et signature Android.

## Critères d'acceptation avant pilote public
1. Aucun accès croisé entre participantes, églises ou carnets privés.
2. Rôles privilégiés attribués uniquement par procédure administrative auditée.
3. Workflow de publication testé de bout en bout.
4. Chaque ressource a un identifiant stable, une provenance et un statut de droits.
5. Les parcours mineurs sont validés et les mécanismes de signalement/modération fonctionnent.
6. Sauvegarde, export et suppression des données testés.
7. Tests d'accessibilité, performance mobile et mode dégradé réseau réalisés.
8. Procédure d'incident, contact de support et politique de confidentialité publiés.

## Limites de la livraison
La V8 est un paquet de développement prêt pour une revue et une préproduction. Elle ne constitue pas une mise en ligne publique, une certification de sécurité, une validation juridique ni une application Android compilée. Aucune ressource n'a été retirée du corpus historique.
