-- ============================================================================
-- ÉCOSYSTÈME CHRÉTIEN — SYNCHRONISATION SUPABASE (schema_sync_supabase.sql)
-- À exécuter dans Supabase > SQL Editor. Idempotent : peut être relancé sans risque.
--
-- Tables : synced_cards (fiches personnelles), user_progress (progression),
--          private_notes (notes personnelles)
-- Sécurité : RLS activée — chaque ligne est isolée par propriétaire.
-- IMPORTANT : title/body restent en clair dans PostgreSQL ; RLS n'est pas du
-- chiffrement de bout en bout. Ne pas présenter ce stockage comme chiffré.
--
-- PRÉREQUIS AUTH : Authentication > Providers > activer « Allow anonymous sign-ins »
-- (session automatique sans e-mail) et/ou Email (connexion multi-appareils).
-- ============================================================================

-- 1. NOTES PRIVÉES -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS private_notes (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL DEFAULT '',
    body        TEXT NOT NULL DEFAULT '',
    status      TEXT NOT NULL DEFAULT 'En cours' CHECK (status IN ('En cours', 'Exaucée', 'Archivée')),
    deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_private_notes_user ON private_notes (user_id, updated_at DESC);

-- 2. PROGRESSION ---------------------------------------------------------------
-- key = '<type>:<id>' (ex. 'read:p1-med-paix', 'prayed:PRY_001', 'steps:p1-defi-7jours')
CREATE TABLE IF NOT EXISTS user_progress (
    user_id     UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    key         TEXT NOT NULL,
    value       JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, key)
);

-- 3. FICHES PERSONNELLES (existait peut-être sans user_id : migration sûre) ------
CREATE TABLE IF NOT EXISTS synced_cards (
    id          TEXT PRIMARY KEY,
    project     TEXT NOT NULL,                 -- 'P1' | 'P2' | 'P3'
    title       TEXT NOT NULL,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE synced_cards ADD COLUMN IF NOT EXISTS user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE synced_cards ADD COLUMN IF NOT EXISTS deleted BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_synced_cards_user ON synced_cards (user_id, updated_at DESC);

-- 4. ROW LEVEL SECURITY ------------------------------------------------------
ALTER TABLE private_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE synced_cards  ENABLE ROW LEVEL SECURITY;

-- Supprime l'ancienne politique ouverte (USING (true)) si elle existe
DROP POLICY IF EXISTS "Allow read/write synced_cards" ON synced_cards;

DROP POLICY IF EXISTS private_notes_owner ON private_notes;
CREATE POLICY private_notes_owner ON private_notes
    FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_progress_owner ON user_progress;
CREATE POLICY user_progress_owner ON user_progress
    FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS synced_cards_owner ON synced_cards;
CREATE POLICY synced_cards_owner ON synced_cards
    FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Aucun accès pour le rôle anonyme (clé publique sans session)
REVOKE ALL ON private_notes, user_progress, synced_cards FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON private_notes, user_progress, synced_cards TO authenticated;

-- 5. MISE À JOUR AUTOMATIQUE DE updated_at (si non fourni par le client) -------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR NEW.updated_at IS NULL THEN
        NEW.updated_at := NOW();
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_notes_updated ON private_notes;
CREATE TRIGGER trg_notes_updated BEFORE INSERT OR UPDATE ON private_notes FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_cards_updated ON synced_cards;
CREATE TRIGGER trg_cards_updated BEFORE INSERT OR UPDATE ON synced_cards FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_progress_updated ON user_progress;
CREATE TRIGGER trg_progress_updated BEFORE INSERT OR UPDATE ON user_progress FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- NB : l'ancienne table synced_cards sans propriétaire (user_id NULL) devient
-- invisible pour tous après ce script ; migre ou supprime ces lignes si besoin :
--   DELETE FROM synced_cards WHERE user_id IS NULL;
