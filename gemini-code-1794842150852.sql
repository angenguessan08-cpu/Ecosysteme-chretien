-- BROUILLON DE MODÈLE MÉTIER — NE PAS EXÉCUTER EN PRODUCTION EN L'ÉTAT.
-- L'audit V7.2 a relevé une couverture RLS incomplète : plusieurs tables
-- (notamment users, privacy_settings, user_roles, churches et contributions)
-- n'ont pas de politiques dédiées dans ce fichier. Les droits doivent être
-- revus et testés avant toute migration réelle. Voir AUDIT_SECURITE_V7_2.md.

-- ============================================================================
-- FILLES DE PROMESSE — SCHÉMA DE BASE DE DONNÉES POSTGRESQL (V1.1)
-- Architecture : Plateforme centrale inter-églises, multi-générationnelle (8-100 ans)
-- ============================================================================

-- Extension pour la génération d'UUID et le chiffrement
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. RÉFÉRENTIELS : RÔLES & TRANCHES D'ÂGE (OUVERTES JUSQU'À 100 ANS)
-- ============================================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL, -- PARTICIPANT, ANIMATOR, CHURCH_CONTRIBUTOR, MODERATOR, SUPER_ADMIN
    label VARCHAR(100) NOT NULL,
    description TEXT
);

INSERT INTO roles (code, label, description) VALUES
('PARTICIPANT', 'Participante', 'Accès à la bibliothèque, méditations, prières privées, jeux et défis'),
('ANIMATOR', 'Animatrice', 'Encadrement des activités et ateliers collectifs assignés'),
('CHURCH_CONTRIBUTOR', 'Contributrice d''église', 'Soumission de ressources éditoriales pour validation'),
('MODERATOR', 'Modératrice', 'Examen des signalements et vérification des contenus'),
('SUPER_ADMIN', 'Administratrice centrale', 'Administration complète de la plateforme');

CREATE TABLE age_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    label VARCHAR(100) NOT NULL,
    min_age INTEGER NOT NULL CHECK (min_age >= 5),
    max_age INTEGER NOT NULL CHECK (max_age >= min_age AND max_age <= 120),
    display_order INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO age_groups (code, label, min_age, max_age, display_order) VALUES
('GIRLS_8_13', 'Filles & Pré-ados (8-13 ans)', 8, 13, 1),
('TEENS_14_17', 'Adolescentes (14-17 ans)', 14, 17, 2),
('YOUNG_WOMEN_18_29', 'Jeunes femmes (18-29 ans)', 18, 29, 3),
('WOMEN_30_49', 'Femmes actives (30-49 ans)', 30, 49, 4),
('SENIORS_50_100', 'Femmes d''expérience & Aînées (50-100 ans)', 50, 100, 5);

-- ============================================================================
-- 2. UTILISATEURS, PROFILS & CONFIDENTIALITÉ (INSCRIPTION LIBRE SANS BLOCAGE)
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(60) UNIQUE NOT NULL, -- Permet l'inscription sans email obligatoire
    email VARCHAR(255) UNIQUE,            -- Optionnel (ex: pour jeunes filles sans email)
    phone VARCHAR(30) UNIQUE,             -- Optionnel (contexte mobile Afrique de l'Ouest)
    password_hash TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DELETED')),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    age_group_id UUID NOT NULL REFERENCES age_groups(id),
    avatar_code VARCHAR(50) DEFAULT 'default_dove',
    country_code CHAR(2) DEFAULT 'CI',
    preferred_language VARCHAR(10) DEFAULT 'fr',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    show_in_group_activities BOOLEAN NOT NULL DEFAULT TRUE,
    allow_activity_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    offline_sync_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, role_id)
);

-- ============================================================================
-- 3. ÉGLISES CONTRIBUTRICES (SANS ACCÈS AUX DONNÉES DES PARTICIPANTES)
-- ============================================================================

CREATE TABLE churches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    denomination VARCHAR(100),
    city VARCHAR(100),
    country_code CHAR(2) DEFAULT 'CI',
    contact_email VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE church_contributors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    church_id UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(church_id, user_id)
);

-- ============================================================================
-- 4. BIBLIOTHÈQUE CENTRALE & WORKFLOW DE VALIDATION ÉDITORIALE
-- ============================================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_code VARCHAR(50) NOT NULL, -- BIBLE, DEVOTIONAL, PRAYER, MOTIVATION, CREATIVITY, CHALLENGE
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    display_order INTEGER DEFAULT 0
);

CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    summary TEXT,
    content_type VARCHAR(40) NOT NULL CHECK (
        content_type IN ('DEVOTIONAL', 'PRAYER_GUIDE', 'BIBLE_GAME', 'MOTIVATION', 'WORKSHOP', 'CHALLENGE', 'PATHWAY')
    ),
    source_type VARCHAR(20) NOT NULL DEFAULT 'CENTRAL' CHECK (
        source_type IN ('CENTRAL', 'CHURCH', 'PARTNER')
    ),
    church_id UUID REFERENCES churches(id) ON DELETE SET NULL,
    estimated_minutes INTEGER DEFAULT 5,
    difficulty_level VARCHAR(20) DEFAULT 'ALL' CHECK (difficulty_level IN ('ALL', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED')),
    cover_image_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (
        status IN ('DRAFT', 'REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')
    ),
    created_by UUID NOT NULL REFERENCES users(id),
    validated_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Contrainte : si source_type = 'CHURCH', church_id est obligatoire
    CONSTRAINT chk_church_source CHECK (
        (source_type = 'CHURCH' AND church_id IS NOT NULL) OR (source_type <> 'CHURCH')
    )
);

-- Liaison N-N : Un contenu peut cibler plusieurs tranches d'âge (ex: 14-17 ans et 18-29 ans, ou toutes)
CREATE TABLE content_age_groups (
    content_id UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    age_group_id UUID NOT NULL REFERENCES age_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (content_id, age_group_id)
);

-- Liaison N-N : Un contenu peut appartenir à plusieurs catégories
CREATE TABLE content_categories (
    content_id UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (content_id, category_id)
);

-- ============================================================================
-- 5. MODULES PÉDAGOGIQUES (MÉDITATIONS, PRIÈRES, JEUX, DÉFIS, ATELIERS)
-- ============================================================================

-- 5.1. Méditations quotidiennes & thématiques
CREATE TABLE devotionals (
    content_id UUID PRIMARY KEY REFERENCES contents(id) ON DELETE CASCADE,
    theme VARCHAR(150) NOT NULL,
    bible_reference VARCHAR(120) NOT NULL, -- Ex: "Psaume 23:1-6"
    bible_text TEXT NOT NULL,
    explanation TEXT NOT NULL,
    daily_application TEXT NOT NULL,
    reflection_question TEXT NOT NULL,
    optional_prayer TEXT
);

-- 5.2. Fiches de prières de la bibliothèque
CREATE TABLE prayer_guides (
    content_id UUID PRIMARY KEY REFERENCES contents(id) ON DELETE CASCADE,
    bible_reference VARCHAR(120),
    bible_verse TEXT,
    context_explanation TEXT,
    prayer_points JSONB NOT NULL DEFAULT '[]', -- Liste structurée des sujets de prière
    suggested_prayer TEXT
);

-- 5.3. Journal de prière PERSONNEL (Strictement privé et chiffré)
CREATE TABLE private_prayer_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    related_content_id UUID REFERENCES contents(id) ON DELETE SET NULL,
    title VARCHAR(150),
    encrypted_note TEXT NOT NULL, -- Chiffrement applicatif avant insertion
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ANSWERED', 'ARCHIVED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5.4. Jeux et quiz bibliques
CREATE TABLE games (
    content_id UUID PRIMARY KEY REFERENCES contents(id) ON DELETE CASCADE,
    game_type VARCHAR(30) NOT NULL CHECK (game_type IN ('QUIZ_MCQ', 'TRUE_FALSE', 'CHARACTER_MATCH', 'CHRONOLOGY')),
    bible_book VARCHAR(80),
    pedagogical_summary TEXT
);

CREATE TABLE game_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(content_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    bible_reference VARCHAR(100),
    explanation TEXT NOT NULL, -- Retour pédagogique affiché après réponse
    display_order INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE game_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES game_questions(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE
);

-- 5.5. Défis éducatifs & créatifs
CREATE TABLE challenges (
    content_id UUID PRIMARY KEY REFERENCES contents(id) ON DELETE CASCADE,
    challenge_type VARCHAR(30) NOT NULL CHECK (challenge_type IN ('READING', 'CREATIVITY', 'PERSONAL_GROWTH', 'COMMUNITY')),
    duration_days INTEGER DEFAULT 7,
    reward_badge_code VARCHAR(60)
);

CREATE TABLE challenge_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES challenges(content_id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    title VARCHAR(150) NOT NULL,
    instruction TEXT NOT NULL,
    UNIQUE(challenge_id, step_number)
);

-- ============================================================================
-- 6. PROGRESSION ÉDUCATIVE & RÉCOMPENSES (SANS NOTATION DE LA FOI)
-- ============================================================================

CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
    educational_score INTEGER CHECK (educational_score IS NULL OR educational_score >= 0), -- Uniquement pour jeux/quiz
    progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(60) UNIQUE NOT NULL,
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    badge_icon VARCHAR(60) NOT NULL,
    category VARCHAR(40) NOT NULL -- REGULARITY, BIBLE_KNOWLEDGE, CREATIVITY, COOPERATION
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- ============================================================================
-- 7. ÉVÉNEMENTS ENCADRÉS, MODÉRATION & JOURNAL D'AUDIT
-- ============================================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(180) NOT NULL,
    description TEXT NOT NULL,
    source_type VARCHAR(20) NOT NULL DEFAULT 'CENTRAL' CHECK (source_type IN ('CENTRAL', 'CHURCH')),
    church_id UUID REFERENCES churches(id) ON DELETE SET NULL,
    event_mode VARCHAR(20) NOT NULL CHECK (event_mode IN ('ONLINE', 'IN_PERSON', 'HYBRID')),
    location_label VARCHAR(200),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    max_participants INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED', 'COMPLETED')),
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'REGISTERED' CHECK (status IN ('REGISTERED', 'CANCELLED', 'ATTENDED')),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    target_type VARCHAR(30) NOT NULL CHECK (target_type IN ('CONTENT', 'EVENT', 'USER_BEHAVIOR', 'TECHNICAL')),
    target_id UUID NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
    handled_by UUID REFERENCES users(id),
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action_code VARCHAR(80) NOT NULL, -- CONTENT_APPROVED, ROLE_CHANGED, USER_SUSPENDED, DATA_EXPORTED
    target_entity VARCHAR(50) NOT NULL,
    target_id UUID,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 8. INDEX DE PERFORMANCE (OPTIMISATION CONNEXIONS MOBILES LIMITÉES)
-- ============================================================================

CREATE INDEX idx_contents_status_published ON contents(status, published_at DESC) WHERE status = 'PUBLISHED';
CREATE INDEX idx_contents_type ON contents(content_type);
CREATE INDEX idx_content_age_groups_age ON content_age_groups(age_group_id);
CREATE INDEX idx_user_progress_user ON user_progress(user_id, updated_at DESC);
CREATE INDEX idx_private_prayers_user ON private_prayer_entries(user_id, created_at DESC);
CREATE INDEX idx_events_upcoming ON events(starts_at ASC) WHERE status = 'PUBLISHED';

-- ============================================================================
-- 9. SÉCURITÉ AU NIVEAU DES LIGNES (ROW LEVEL SECURITY — RLS)
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE private_prayer_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents ENABLE ROW LEVEL SECURITY;

-- Règle 1 : Une participante ne lit et ne modifie que SON propre profil
CREATE POLICY "Users manage own profile" ON profiles
    FOR ALL USING (auth.uid() = user_id);

-- Règle 2 : Les notes de prière privées ne sont accessibles QUE par leur propriétaire
-- (Aucune église, animatrice ou contributrice ne peut les lire)
CREATE POLICY "Strict owner access to private prayers" ON private_prayer_entries
    FOR ALL USING (auth.uid() = user_id);

-- Règle 3 : Une participante ne consulte que SA progression personnelle
CREATE POLICY "Users manage own progress" ON user_progress
    FOR ALL USING (auth.uid() = user_id);

-- Règle 4 : Seuls les contenus au statut 'PUBLISHED' sont visibles par les participantes
CREATE POLICY "Participants read only published contents" ON contents
    FOR SELECT USING (status = 'PUBLISHED' OR created_by = auth.uid());