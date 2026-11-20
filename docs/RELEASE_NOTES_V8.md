# Notes de livraison — Écosystème Chrétien V8

Date : 19 novembre 2026

## Livrables
- Socle SQL central additif pour Supabase.
- Architecture cible séparant le portail généraliste et le parcours Filles de Promesse.
- Rôles et frontières d'accès documentés.
- Modèle de contribution d'église avec versions et revue centrale.
- Matrice de recette RLS multi-comptes.
- Tests statiques d'architecture ajoutés aux tests d'intégrité des 532 ressources.

## Résultats de tests locaux
- Syntaxe JS : validée sur `app.js`, `data.js`, `sw.js`.
- Tests automatisés Node : 11 réussis, 0 échec.
- Les tests valident les données et des invariants statiques du schéma ; ils ne prouvent pas l'isolation RLS sur un serveur PostgreSQL.

## Non réalisé / dépend d'accès ou d'une validation externe
- Pas de connexion ni migration sur un projet Supabase réel.
- Pas de tests PostgreSQL/RLS avec JWT distincts.
- Pas de déploiement web, domaine ou compte administrateur initial.
- Pas de build Android signé ni publication Play Store.
- Pas de validation juridique ivoirienne concernant les mineures et données personnelles.
- Pas de vérification complète des licences et droits d'auteur de chaque contenu.
- Pas de recette navigateur visuelle complète.

## Décision de sécurité
Ne pas ouvrir la synchronisation ni l'inscription publique à partir de cette livraison sans avoir exécuté la matrice RLS, validé le modèle d'identité et mis en place les parcours de protection des mineures.
