# Matrice de recette RLS — à exécuter sur Supabase de préproduction

**Bloquant avant toute mise en production.** Ces cas ne sont pas déclarés réussis : ils constituent le protocole à exécuter avec de vrais JWT de test.

Identités à créer :
- `user_a` et `user_b` : participantes sans rôle privilégié ;
- `contributor_a` : contributrice active de l'église A ;
- `contributor_b` : contributrice active de l'église B ;
- `moderator` : rôle MODERATOR ;
- `platform_admin` : rôle PLATFORM_ADMIN attribué manuellement par un opérateur de confiance.

| Test | Action | Résultat attendu |
|---|---|---|
| RLS-01 | user_a lit son profil | Autorisé |
| RLS-02 | user_a lit/modifie le profil de user_b | Refusé / zéro ligne |
| RLS-03 | user_a lit un contenu PUBLISHED | Autorisé |
| RLS-04 | user_a lit un brouillon de contributor_a | Refusé / zéro ligne |
| RLS-05 | contributor_a lit son brouillon de l'église A | Autorisé |
| RLS-06 | contributor_a lit un brouillon de l'église B | Refusé / zéro ligne |
| RLS-07 | contributor_a crée un DRAFT lié à l'église A | Autorisé |
| RLS-08 | contributor_a crée un DRAFT lié à l'église B | Refusé |
| RLS-09 | contributor_a tente de changer le `source_church_id` du brouillon A vers B | Refusé |
| RLS-10 | contributor_a tente de publier directement son contenu | Refusé par la policy d'auteur ; publication réservée au modérateur/admin |
| RLS-11 | moderator lit un contenu soumis | Autorisé |
| RLS-12 | moderator publie un contenu validé | Autorisé ; vérifier séparément les transitions serveur |
| RLS-13 | user_a crée un signalement pour un contenu | Autorisé |
| RLS-14 | user_b lit le signalement de user_a | Refusé / zéro ligne |
| RLS-15 | moderator lit et traite le signalement | Autorisé |
| RLS-16 | contributor_a attribue PLATFORM_ADMIN à son compte | Refusé |
| RLS-17 | rôle anon lit toutes les tables centrales | Refusé |
| RLS-18 | contributor_a tente de lire un profil ou carnet personnel | Refusé |

## Conditions de validation

- Exécuter chaque cas avec un JWT de la personne concernée, pas avec `service_role`.
- Tester SELECT, INSERT, UPDATE et DELETE séparément, y compris les accès via API REST.
- Confirmer qu'une requête refusée ne retourne aucune donnée même si le client connaît l'UUID.
- Tester également les vues, fonctions RPC, exports, Storage et journaux, s'ils sont ajoutés.
- Conserver le résultat, la date, la version de migration et les identifiants de test non réels.
- Toute fuite inter-comptes ou inter-églises bloque le pilote.
