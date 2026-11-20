# Architecture cible — Écosystème Chrétien / Filles de Promesse

Version 1.0 — 19 novembre 2026

## 1. Périmètre produit

- **Écosystème Chrétien** : portail généraliste de ressources et d'outils bibliques, familiaux et spirituels, accessible à tous les publics.
- **Filles de Promesse** : programme/ministère dédié aux filles et femmes, hébergé comme un parcours clairement identifié dans l'écosystème, avec sa propre taxonomie éditoriale et ses règles de protection.
- **Églises** : partenaires/contributrices. Elles ne possèdent pas d'espace privé participant et ne consultent jamais les carnets ni les profils personnels des participantes.
- **Administration centrale** : gouverne les référentiels, comptes à privilèges, publications, signalements et règles de modération.
- **IA** : hors périmètre de cette première livraison ; phase ultérieure après gouvernance et sécurité.

Cette séparation évite de faire passer le référentiel féminin de Filles de Promesse pour une règle universelle de toute la plateforme.

## 2. Architecture logique

```text
PWA Web / future application Android
              |
      Supabase Auth (JWT)
              |
     PostgreSQL + RLS
       |       |       |
  Profils   Contenus  Églises & rôles
  privés    versionnés   contributions
       |       |       |
  Carnet   Modération  Administration
  local    centrale    centrale
```

Les clients Web et Android utilisent le même backend. Les opérations privilégiées (attribution de rôle, publication, suppression administrative, export de données) doivent passer par une fonction serveur contrôlée ou une interface admin protégée ; jamais par une clé `service_role` embarquée dans le client.

## 3. Rôles et frontières

| Rôle | Accès prévu |
|---|---|
| Visiteur | Accueil et contenus explicitement publics, selon la politique d'accès retenue |
| Participante | Bibliothèque publiée, progression et carnet propre |
| Contributrice d'église | Dépôt et correction de brouillons de son église ; aucun accès aux données des participantes |
| Modératrice | Revue des contenus et signalements ; pas d'accès par défaut aux carnets privés |
| Administratrice centrale | Gestion de la plateforme et des rôles selon principe du moindre privilège |

Les rôles ne sont jamais auto-attribuables par un utilisateur. L'attribution doit être contrôlée et journalisée côté serveur.

## 4. Modèle de données livré

La migration `database/migrations/001_platform_core.sql` introduit de façon additive :

- `platform_profiles`, `platform_roles`, `platform_user_roles` ;
- `churches`, `church_memberships` ;
- `content_items`, `content_versions`, `content_reviews` ;
- `content_reports`, `platform_audit_log`.

Le modèle distingue le contenu et ses versions éditoriales. Chaque ressource peut être liée à une église contributrice, mais elle n'est visible comme contenu commun qu'après publication centrale.

## 5. Référentiels non arbitrairement fusionnés

- Les cinq espaces existants P1–P5 et leurs 532 entrées restent préservés.
- Le code d'audience `ALL` est distinct de `FILLE_PROMESSE`, `FAMILY`, `YOUTH` et `ADULTS`.
- `age_group_code` reste nullable tant que la contradiction 0–7 / 8–100 présente entre documents et seeds n'a pas été validée. Aucun âge n'est déduit ou imposé à l'inscription dans cette migration.
- Le contenu éditorial doit être associé à une source et à un statut de droits (`UNVERIFIED` par défaut).

## 6. Sécurité et protection

- RLS activée sur chaque table de la migration ; aucun droit `anon`.
- Profils visibles uniquement par leur propriétaire dans cette première version.
- Les églises ne peuvent consulter que les contenus publiés ou leurs propres contributions.
- Les signalements sont visibles par leur auteur et les modératrices/administratrices.
- Les carnets personnels ne sont pas intégrés au schéma de contenus.
- Les notes de prière synchronisées de la V7.x restent un sujet distinct : stockage en clair sous RLS, donc pas de promesse de chiffrement de bout en bout.
- Pour les mineures : minimisation des données, consentement/autorisation appropriés, parcours adaptés, modération, signalement, rétention et procédure d'incident à faire valider par un conseil juridique en Côte d'Ivoire.

## 7. Déploiement progressif

1. Sauvegarder le projet et les données locales ; maintenir la V7.x utilisable.
2. Créer un projet Supabase de préproduction isolé.
3. Exécuter la migration uniquement en préproduction après revue SQL.
4. Tester avec au moins quatre identités distinctes : participante A, participante B, contributrice d'église, modératrice ; ajouter une administratrice.
5. Vérifier les refus d'accès croisé (profil, brouillon, carnet, signalement, rôle).
6. Construire les écrans d'authentification, profil, contribution et modération.
7. Importer les contenus en conservant identifiants stables, provenance et droits.
8. Effectuer une recette mobile/desktop et une revue de protection des mineures.
9. Publier un pilote fermé avant ouverture générale.

## 8. Ce que cette livraison ne fait pas

La migration SQL est un socle technique de préproduction, pas un backend certifié. Elle n'est pas exécutée sur un projet distant, les rôles privilégiés ne sont pas provisionnés, le workflow de publication n'a pas encore de validation transactionnelle serveur, les tests RLS multi-comptes restent à exécuter et aucune application Android native n'est générée. Aucun compte, hébergement ou domaine n'a été créé.
