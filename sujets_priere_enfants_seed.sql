-- ============================================================================
-- FILLES DE PROMESSE — MODULE ENFANTS & FAMILLES (MIGRATION + SEED COMPLET)
-- Source : SUJET DE PRIERE ENFANT.pdf (34 pages)
-- Compatible avec le schéma PostgreSQL V1.1 de Filles de Promesse
-- ============================================================================

BEGIN;

-- 1. Extension optionnelle de age_groups pour couvrir 0-7 ans (Tout-petits)
ALTER TABLE age_groups DROP CONSTRAINT IF EXISTS age_groups_min_age_check;
ALTER TABLE age_groups ADD CONSTRAINT age_groups_min_age_check CHECK (min_age >= 0);
INSERT INTO age_groups (code, label, min_age, max_age, display_order)
VALUES ('KIDS_0_7', 'Tout-petits & Enfants (0-7 ans)', 0, 7, 0)
ON CONFLICT (code) DO NOTHING;

-- 2. Création des tables de classification des sujets de prière
CREATE TABLE IF NOT EXISTS prayer_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS prayer_taxonomy_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES prayer_taxonomy_categories(id) ON DELETE CASCADE,
    code VARCHAR(30) UNIQUE NOT NULL,
    slug VARCHAR(120) UNIQUE NOT NULL,
    name VARCHAR(160) NOT NULL,
    icon_name VARCHAR(50),
    color_hex VARCHAR(10),
    display_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS prayer_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) UNIQUE NOT NULL,
    group_code VARCHAR(30) NOT NULL REFERENCES prayer_groups(code) ON DELETE RESTRICT,
    prayer_type VARCHAR(30) NOT NULL CHECK (prayer_type IN ('THANKSGIVING', 'REQUEST', 'SPIRITUAL_WARFARE')),
    category_code VARCHAR(30) NOT NULL REFERENCES prayer_taxonomy_categories(code) ON DELETE RESTRICT,
    subcategory_code VARCHAR(30) REFERENCES prayer_taxonomy_categories(code) ON DELETE SET NULL,
    section_source VARCHAR(200),
    source_page INTEGER,
    bible_reference VARCHAR(120),
    has_name_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    content_original TEXT NOT NULL,
    content_kid_friendly TEXT NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS prayer_topic_age_groups (
    topic_id UUID NOT NULL REFERENCES prayer_topics(id) ON DELETE CASCADE,
    age_group_id UUID NOT NULL REFERENCES age_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (topic_id, age_group_id)
);

CREATE INDEX IF NOT EXISTS idx_prayer_topics_group ON prayer_topics(group_code);
CREATE INDEX IF NOT EXISTS idx_prayer_topics_type ON prayer_topics(prayer_type);
CREATE INDEX IF NOT EXISTS idx_prayer_topics_cat ON prayer_topics(category_code, subcategory_code);
CREATE INDEX IF NOT EXISTS idx_prayer_topics_placeholder ON prayer_topics(has_name_placeholder) WHERE has_name_placeholder = TRUE;

-- 3. Insertion des 3 Grands Groupes
INSERT INTO prayer_groups (code, name, description) VALUES ('CHILD', 'Prière de l''Enfant & du Jeune', 'Sujets à la 1ère personne ou adaptés pour la prière personnelle de l''enfant et de l''adolescent.') ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
INSERT INTO prayer_groups (code, name, description) VALUES ('PARENT', 'Intercession des Parents & Familles', 'Sujets d''intercession parentale, dévotions familiales, maternité, protection et consécration des enfants.') ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
INSERT INTO prayer_groups (code, name, description) VALUES ('MINISTER', 'Ministère aux Enfants & Faiseurs de Disciples', 'Équipement spirituel des encadreurs, évangélisation, chaînes de jeûne et intégration dans l''église.') ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 4. Insertion des 10 Catégories et 45 Sous-catégories
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_01', 'salut-et-nouvelle-naissance', '1. Salut & Nouvelle Naissance', 'sparkles', '#F59E0B', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_01'), 'SUB_01_01', 'salut-et-nouvelle-naissance-sub-01-01', 'Révélation de la Croix & Évangile', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_01'), 'SUB_01_02', 'salut-et-nouvelle-naissance-sub-01-02', 'Repentance & Conversion', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_01'), 'SUB_01_03', 'salut-et-nouvelle-naissance-sub-01-03', 'Baptême (Eau & Saint-Esprit)', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_01'), 'SUB_01_04', 'salut-et-nouvelle-naissance-sub-01-04', 'Assurance du Salut & Persévérance', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_02', 'intimite-avec-dieu', '2. Intimité avec Dieu & Vie Spirituelle', 'flame', '#EF4444', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_02'), 'SUB_02_01', 'intimite-avec-dieu-sub-02-01', 'RDQAD (Rencontres Dynamiques Quotidiens avec Dieu)', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_02'), 'SUB_02_02', 'intimite-avec-dieu-sub-02-02', 'Amour & Méditation de la Parole de Dieu', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_02'), 'SUB_02_03', 'intimite-avec-dieu-sub-02-03', 'Vie de Prière & Retraites (4x15 min)', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_02'), 'SUB_02_04', 'intimite-avec-dieu-sub-02-04', 'Vie de Jeûne & Intercession', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_02'), 'SUB_02_05', 'intimite-avec-dieu-sub-02-05', 'Lecture de Littérature Chrétienne', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_03', 'sanctification-et-peche', '3. Sanctification & Victoire sur le Péché', 'shield-check', '#10B981', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_03'), 'SUB_03_01', 'sanctification-et-peche-sub-03-01', 'Conviction & Haine du Péché', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_03'), 'SUB_03_02', 'sanctification-et-peche-sub-03-02', 'Brisement du « Moi » & Orgueil', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_03'), 'SUB_03_03', 'sanctification-et-peche-sub-03-03', 'Pureté Morale & Sexuelle', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_03'), 'SUB_03_04', 'sanctification-et-peche-sub-03-04', 'Intégrité, Vérité & Délivrance de la Fausseté', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_03'), 'SUB_03_05', 'sanctification-et-peche-sub-03-05', 'Crainte de Dieu', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_04', 'attitude-vis-a-vis-du-monde', '4. Attitude vis-à-vis du Monde & Valeurs', 'globe', '#6366F1', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_04'), 'SUB_04_01', 'attitude-vis-a-vis-du-monde-sub-04-01', 'Renoncement aux Vanités, Modes & Idoles', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_04'), 'SUB_04_02', 'attitude-vis-a-vis-du-monde-sub-04-02', 'Maîtrise des Écrans, Médias & Distractions', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_04'), 'SUB_04_03', 'attitude-vis-a-vis-du-monde-sub-04-03', 'Gestion de l''Argent, Dîmes & Contentement', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_04'), 'SUB_04_04', 'attitude-vis-a-vis-du-monde-sub-04-04', 'Vision du Royaume des Cieux', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_05', 'caractere-et-discipolat', '5. Caractère de Christ & Vie de Disciple', 'award', '#8B5CF6', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_05'), 'SUB_05_01', 'caractere-et-discipolat-sub-05-01', 'Fruit de l''Esprit & Humilité', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_05'), 'SUB_05_02', 'caractere-et-discipolat-sub-05-02', 'Pardon, Amour du Prochain & des Ennemis', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_05'), 'SUB_05_03', 'caractere-et-discipolat-sub-05-03', 'Évangélisation & Gagnement des Âmes', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_05'), 'SUB_05_04', 'caractere-et-discipolat-sub-05-04', 'Formation des Disciples & Comptes-Rendus', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_05'), 'SUB_05_05', 'caractere-et-discipolat-sub-05-05', 'Appartenance à l''Assemblée Locale', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_06', 'famille-et-parents', '6. Famille & Relations Parents-Enfants', 'heart', '#EC4899', 6) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_06'), 'SUB_06_01', 'famille-et-parents-sub-06-01', 'Dévotions & Cultes Familiaux', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_06'), 'SUB_06_02', 'famille-et-parents-sub-06-02', 'Obéissance, Respect & Honneur aux Parents', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_06'), 'SUB_06_03', 'famille-et-parents-sub-06-03', 'Harmonie Fraternelle & Climat de Confiance', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_06'), 'SUB_06_04', 'famille-et-parents-sub-06-04', 'Responsabilité & Consécration des Parents', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_07', 'vie-academique-et-etudes', '7. Vie Académique & Études', 'book-open', '#0EA5E9', 7) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_07'), 'SUB_07_01', 'vie-academique-et-etudes-sub-07-01', 'Intelligence, Mémoire & Excellence Scolaire', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_07'), 'SUB_07_02', 'vie-academique-et-etudes-sub-07-02', 'Discipline & Honnêteté aux Examens', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_07'), 'SUB_07_03', 'vie-academique-et-etudes-sub-07-03', 'Protection & Témoignage à l''École', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_07'), 'SUB_07_04', 'vie-academique-et-etudes-sub-07-04', 'Orientation, Provision & Adaptation (EMI)', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_08', 'protection-physique-spirituelle', '8. Protection Physique & Spirituelle', 'shield', '#14B8A6', 8) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_08'), 'SUB_08_01', 'protection-physique-spirituelle-sub-08-01', 'Santé & Guérison par Systèmes Corporels', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_08'), 'SUB_08_02', 'protection-physique-spirituelle-sub-08-02', 'Protection contre les Accidents & Dangers', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_08'), 'SUB_08_03', 'protection-physique-spirituelle-sub-08-03', 'Sécurité Sociale (Enlèvements, Drogues, Mauvaises Compagnies)', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_08'), 'SUB_08_04', 'protection-physique-spirituelle-sub-08-04', 'Bouclier Spirituel (Sorcellerie, Sectes, Oppressions)', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_08'), 'SUB_08_05', 'protection-physique-spirituelle-sub-08-05', 'Voyages Missionnaires & Absence des Parents', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_09', 'maternite-petite-enfance', '9. Maternité, Petite Enfance & Cas Spéciaux', 'baby', '#F97316', 9) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_09'), 'SUB_09_01', 'maternite-petite-enfance-sub-09-01', 'Couples sans Enfants & Conception', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_09'), 'SUB_09_02', 'maternite-petite-enfance-sub-09-02', 'Grossesse, Formation du Fœtus & Accouchement', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_09'), 'SUB_09_03', 'maternite-petite-enfance-sub-09-03', 'Nourrissons (0-3 ans), Allaitement & Sevrage', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_09'), 'SUB_09_04', 'maternite-petite-enfance-sub-09-04', 'Soutien aux Parents d''Enfants Malades', 4) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_09'), 'SUB_09_05', 'maternite-petite-enfance-sub-09-05', 'Consécration Complète de l''Enfant à Dieu', 5) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, icon_name, color_hex, display_order) VALUES (NULL, 'CAT_10', 'vision-missionnaire-2065', '10. Vision Missionnaire (EMI & Objectif 2065)', 'compass', '#EAB308', 10) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_10'), 'SUB_10_01', 'vision-missionnaire-2065-sub-10-01', 'Appel & But de la Vie dès le Jeune Âge', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_10'), 'SUB_10_02', 'vision-missionnaire-2065-sub-10-02', 'Enfants Missionnaires Internationaux (EMI)', 2) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_10'), 'SUB_10_03', 'vision-missionnaire-2065-sub-10-03', 'Ministère aux Enfants & Impact de T.A', 3) ON CONFLICT (code) DO NOTHING;
INSERT INTO prayer_taxonomy_categories (parent_id, code, slug, name, display_order) VALUES ((SELECT id FROM prayer_taxonomy_categories WHERE code = 'CAT_10'), 'SUB_10_04', 'vision-missionnaire-2065-sub-10-04', 'Objectif 2065 (Un Milliard de Disciples)', 4) ON CONFLICT (code) DO NOTHING;

-- 5. Insertion des 383 sujets de prière classifiés
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_001', 'PARENT', 'THANKSGIVING',
        'CAT_06', 'SUB_06_04',
        'Sujet de prière pour les enfants - Actions de grâces', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, merci pour le privilège d''être une mère d''enfants.', 'Seigneur, merci pour le privilège d''être une mère d''enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_002', 'PARENT', 'THANKSGIVING',
        'CAT_06', 'SUB_06_04',
        'Sujet de prière pour les enfants - Actions de grâces', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, merci pour ma responsabilité d''en prendre soin, de les instruire.', 'Seigneur, merci pour ma responsabilité d''en prendre soin, de les instruire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_003', 'PARENT', 'THANKSGIVING',
        'CAT_06', 'SUB_06_04',
        'Sujet de prière pour les enfants - Actions de grâces', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, merci pour le nombre d''enfants que Tu m''as accordé de porter dans mon sein.', 'Seigneur, merci pour le nombre d''enfants que Tu m''as accordé de porter dans mon sein.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_004', 'PARENT', 'THANKSGIVING',
        'CAT_06', 'SUB_06_04',
        'Sujet de prière pour les enfants - Actions de grâces', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, merci pour leur père et pour sa contribution dans leur instruction.', 'Seigneur, merci pour leur père et pour sa contribution dans leur instruction.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_005', 'PARENT', 'THANKSGIVING',
        'CAT_06', 'SUB_06_04',
        'Sujet de prière pour les enfants - Actions de grâces', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, merci pour Tes plans et desseins pour chacun de nos enfants dans cette vie et dans celle à venir.', 'Seigneur, merci pour Tes plans et desseins pour chacun de nos enfants dans cette vie et dans celle à venir.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_006', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, accorde-moi d''être un modèle agréable à Dieu pour chacun d''entre eux, de sorte qu''en m''imitant, ils s''attachent à Dieu.', 'Seigneur, accorde-moi d''être un modèle agréable à Dieu pour chacun d''entre eux, de sorte qu''en m''imitant, ils s''attachent à Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_007', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, ouvre mes yeux afin que je voie le reflet de ma vie chrétienne en chacun de mes enfants.', 'Seigneur, ouvre mes yeux afin que je voie le reflet de ma vie chrétienne en chacun de mes enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_008', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, donne-moi d''être vraie dans tous les domaines de ma vie et que ma vie aux yeux des hommes, concorde avec ma vie aux yeux de Dieu.', 'Seigneur, donne-moi d''être vraie dans tous les domaines de ma vie et que ma vie aux yeux des hommes, concorde avec ma vie aux yeux de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_009', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, aide-moi à grandir dans ma sanctification.', 'Seigneur, aide-moi à grandir dans ma sanctification.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_010', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, aide-moi à grandir dans ma consécration à Dieu.', 'Seigneur, aide-moi à grandir dans ma consécration à Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_011', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, que je me sépare des hommes pour me retirer dans Ta Présence, et non pour pécher.', 'Seigneur, que je me sépare des hommes pour me retirer dans Ta Présence, et non pour pécher.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_012', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, aide-moi à ramener Dieu dans ma maison et à œuvrer pour que chacun fasse de Dieu sa priorité chaque jour : a) Que les dévotions familiales soient établies ; b) Que nous ayons une période d''au moins 1 heure de prière et d''exhortation par semaine ; c) Que chacun de mes enfants puisse se donner aux RDQAD, à la lecture biblique (3 chap./jour), à la prière seul, aux dîmes et offrandes, au jeûne, à la communion fraternelle, aux réunions d''enseignement, à l''évangélisation.', 'Seigneur, aide-moi à ramener Dieu dans ma maison et à œuvrer pour que chacun fasse de Dieu sa priorité chaque jour : a) Que les dévotions familiales soient établies ; b) Que nous ayons une période d''au moins 1 heure de prière et d''exhortation par semaine ; c) Que chacun de mes enfants puisse se donner aux RDQAD, à la lecture biblique (3 chap./jour), à la prière seul, aux dîmes et offrandes, au jeûne, à la communion fraternelle, aux réunions d''enseignement, à l''évangélisation.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_013', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, crée dans le cœur de chacun le désir de Te connaître, de pouvoir discerner Ta Voix parmi d''autres.', 'Seigneur, mets dans mon cœur le désir de Te connaître, de pouvoir discerner Ta Voix parmi d''autres.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_014', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, crée un profond amour dans leur cœur pour leur père, afin que cela les pousse à crier à Toi pour lui, jusqu''à sa restauration.', 'Seigneur, crée un profond amour dans leur cœur pour leur père, afin que cela les pousse à crier à Toi pour lui, jusqu''à sa restauration.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_015', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, qu''un climat de confiance naisse entre eux et nous, leurs parents.', 'Seigneur, qu''un climat de confiance naisse entre eux et nous, leurs parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_016', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, crée dans leur cœur le désir de rester avec leur père.', 'Seigneur, crée dans leur cœur le désir de rester avec leur père.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_017', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, délivre-les de toute pensée négative sur leur père.', 'Seigneur, protège-moi et libère-moi de toute pensée négative sur leur père.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_018', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, accorde à leur père de leur offrir l''amour et la tendresse dont ils ont besoin.', 'Seigneur, accorde à leur père de leur offrir l''amour et la tendresse dont ils ont besoin.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_019', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, révèle-Toi à chacun de ces enfants, d''une manière toute fraîche, et qu''ils connaissent une nouvelle crise de conversion.', 'Seigneur, révèle-Toi à chacun de ces enfants, d''une manière toute fraîche, et qu''ils connaissent une nouvelle crise de conversion.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_020', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_01',
        'Sujet de prière pour les enfants - Requêtes familiales', 1, 'Proverbes 22:6',
        FALSE, 'Seigneur, qu''avant 20 ans, chacun reçoive de Toi un appel clair du but de sa vie.', 'Seigneur, qu''avant 20 ans, chacun reçoive de Toi un appel clair du but de sa vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_021', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, accorde à chaque enfant la révélation du péché personnel comme Dieu le voit : en pensées, dans ses goûts, dans l''apparence, dans les valeurs, en paroles, dans ses choix, dans les regards, en acte, dans le toucher, dans les possessions, par rapport au sexe opposé, dans l''utilisation de l''argent, et l''amour de la célébrité.', 'Seigneur, accorde à chaque enfant la révélation du péché personnel comme Dieu le voit : en pensées, dans ses goûts, dans l''apparence, dans les valeurs, en paroles, dans ses choix, dans les regards, en acte, dans le toucher, dans les possessions, par rapport au sexe opposé, dans l''utilisation de l''argent, et l''amour de la célébrité.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_022', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne à chaque enfant une profonde conviction du péché.', 'Seigneur, donne à chaque enfant une profonde conviction du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_023', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, bénis chaque enfant avec un cœur bon et honnête, pour accepter ce que ses aînés spirituels voient et pointent en lui comme péché, même s''il ne comprend pas.', 'Seigneur, bénis chaque enfant avec un cœur bon et honnête, pour accepter ce que ses aînés spirituels voient et pointent en lui comme péché, même s''il ne comprend pas.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_024', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, que leurs âmes connaissent l''angoisse à cause du péché.', 'Seigneur, que leurs âmes connaissent l''angoisse à cause du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_025', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, bénis-les avec la tristesse selon Dieu à cause du péché.', 'Seigneur, bénis-les avec la tristesse selon Dieu à cause du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_026', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, crée en eux une haine totale du péché sous toutes ses formes.', 'Seigneur, crée en eux une haine totale du péché sous toutes ses formes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_027', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, qu''ils haïssent tout plaisir, tout gain qu''un quelconque péché pourrait lui procurer.', 'Seigneur, aide-moi à ce que je haïssent tout plaisir, tout gain qu''un quelconque péché pourrait lui procurer.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_028', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, bénis-les avec la capacité d''abandonner totalement le péché sous toutes ses formes.', 'Seigneur, bénis-les avec la capacité d''abandonner totalement le péché sous toutes ses formes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_029', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur une fraîche vision de la croix où : a) Le péché a été crucifié ; b) Christ a été crucifié à cause de lui ; c) Le monde a été crucifié pour lui et lui pour le monde ; d) Le « moi » a été crucifié ; e) Christ a souffert.', 'Seigneur, donne-leur une fraîche vision de la croix où : a) Le péché a été crucifié ; b) Christ a été crucifié à cause de lui ; c) Le monde a été crucifié pour lui et lui pour le monde ; d) Le « moi » a été crucifié ; e) Christ a souffert.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_030', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur une fraîche vision de cela qui a été accompli sur la croix.', 'Seigneur, donne-leur une fraîche vision de cela qui a été accompli sur la croix.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_031', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal de l''amour des choses du monde.', 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal de l''amour des choses du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_032', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, ouvre leurs yeux afin qu''ils voient les choses du monde telles qu''elles sont : vaines, passagères, éphémères.', 'Seigneur, ouvre leurs yeux afin qu''ils voient les choses du monde telles qu''elles sont : vaines, passagères, éphémères.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_033', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, ouvre leurs yeux, afin qu''ils voient que chaque chose du monde lutte pour occuper une place dans son cœur.', 'Seigneur, ouvre leurs yeux, afin qu''ils voient que chaque chose du monde lutte pour occuper une place dans son cœur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_034', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur de discerner ces choses du monde qui ont déjà occupé leur cœur, et par la puissance de Ton Saint-Esprit, conduis-les à les arracher de leur cœur.', 'Seigneur, donne-leur de discerner ces choses du monde qui ont déjà occupé leur cœur, et par la puissance de Ton Saint-Esprit, conduis-les à les arracher de leur cœur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_035', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal de l''amour du monde, de ces choses que le monde considère comme glorieuses.', 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal de l''amour du monde, de ces choses que le monde considère comme glorieuses.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_036', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal du « moi ».', 'Seigneur, donne-leur d''expérimenter un abandon radical et brutal du « moi ».'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_037', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, par Ta puissance, amène chacun des enfants à discerner dans sa vie les différentes manifestations du « moi » : ingratitude envers Dieu, parents, dirigeants, enseignants, amis ; égoïsme, chicheté, apitoiement sur soi-même, plaintes, murmures, indépendance, désir d''être vu/aimé/apprécié, esprit de patron, manque de respect, amour de la télévision, protection de soi-même, peur de souffrir pour Ta cause, autojustification, manque de pardon, haine, amertume, jugement des autres.', 'Seigneur, par Ta puissance, amène chacun des enfants à discerner dans sa vie les différentes manifestations du « moi » : ingratitude envers Dieu, parents, dirigeants, enseignants, amis ; égoïsme, chicheté, apitoiement sur soi-même, plaintes, murmures, indépendance, désir d''être vu/aimé/apprécié, esprit de patron, manque de respect, amour de la télévision, protection de soi-même, peur de souffrir pour Ta cause, autojustification, manque de pardon, haine, amertume, jugement des autres.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_038', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, crée en eux une profonde haine de la vie centrée sur le « moi ».', 'Seigneur, crée en eux une profonde haine de la vie centrée sur le « moi ».'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_039', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, fais en sorte que chacun de mes enfants puisse se remettre entièrement à Toi dès son jeune âge, et qu''ils Te remettent leur tout, tout ce qu''ils sont et qu''ils seront, tout ce qu''ils ont et qu''ils auront.', 'Seigneur, fais en sorte que chacun de mes enfants puisse se remettre entièrement à Toi dès son jeune âge, et qu''ils Te remettent leur tout, tout ce qu''ils sont et qu''ils seront, tout ce qu''ils ont et qu''ils auront.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_040', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, que chaque enfant expérimente la vie remplie du Saint-Esprit dès son jeune âge.', 'Seigneur, que chaque enfant expérimente la vie remplie du Saint-Esprit dès son jeune âge.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_041', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, que ce jour se lève sur ma famille où tous mes enfants dès leur jeune âge reçoivent de Toi le but de leur vie, de manière claire et distincte.', 'Seigneur, que ce jour se lève sur ma famille où tous mes enfants dès leur jeune âge reçoivent de Toi le but de leur vie, de manière claire et distincte.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_042', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, pendant qu''ils grandissent, donne-leur de ne pas perdre de vue l''appel de Dieu dans leur vie.', 'Seigneur, pendant qu''ils grandissent, donne-leur de ne pas perdre de vue l''appel de Dieu dans leur vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_043', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_01',
        'Réveil spirituel dans la vie de chaque enfant et jeune', 1, 'Galates 2:20',
        FALSE, 'Seigneur, qu''ils puissent T''offrir un service saignant dans la puissance de Ton Saint-Esprit, dès son jeune âge.', 'Seigneur, aide-moi à ce que je puissent T''offrir un service saignant dans la puissance de Ton Saint-Esprit, dès son jeune âge.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_044', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci pour le but pour lequel Tu as appelé chacun de mes enfants à être saint.', 'Seigneur, merci pour le but pour lequel Tu as appelé chacun de mes enfants à être saint.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_045', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci de ce que Tes desseins éternels sont pour ceux qui sont saints.', 'Seigneur, merci de ce que Tes desseins éternels sont pour ceux qui sont saints.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_046', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci pour tous mes enfants qui sont déjà sauvés.', 'Seigneur, merci pour tous mes enfants qui sont déjà sauvés.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_047', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci d''avoir appelé mes tout-petits à Te connaître, Toi, le seul Vrai Dieu, et Jésus-Christ que Tu as envoyé.', 'Seigneur, merci d''avoir appelé mes tout-petits à Te connaître, Toi, le seul Vrai Dieu, et Jésus-Christ que Tu as envoyé.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_048', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci de ce que chacun de mes enfants est un enfant spécial, et que Dieu connaît par son nom.', 'Seigneur, merci de ce que chacun de mes enfants est un enfant spécial, et que Dieu connaît par son nom.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_049', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, merci de ce que c''est Toi qui as envoyé chacun de ces enfants dans notre famille.', 'Seigneur, merci de ce que c''est Toi qui as envoyé chacun de ces enfants dans notre famille.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_050', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, accorde à chaque enfant de connaître une fraîche rencontre avec Dieu, et Christ le Sanctificateur, afin d''être béni avec : une connaissance du péché selon Dieu, une tristesse selon Dieu, une confession du péché à Dieu et à l''homme, un abandon du péché, une restitution à Dieu et à l''homme, le pardon selon Dieu, une haine du péché selon Dieu.', 'Seigneur Jésus, aide-moi à connaître une fraîche rencontre avec Dieu, et Christ le Sanctificateur, afin d''être béni avec : une connaissance du péché selon Dieu, une tristesse selon Dieu, une confession du péché à Dieu et à l''homme, un abandon du péché, une restitution à Dieu et à l''homme, le pardon selon Dieu, une haine du péché selon Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_051', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, accorde à chaque enfant de haïr : l''ingratitude, la fausseté (mensonge, malhonnêteté, hypocrisie, ruse, dissimulation, duplicité, tricherie, fraude), le manque de pardon, l''amertume, la colère, l''entêtement envers les aînés, le niveau de vie très élevé, le vol, le sommeil en excès, la saleté, la paresse, l''indiscipline et le désordre, l''amour de la nourriture, l''autojustification, les manifestations impures de la puberté, les ambitions mondaines, la rébellion, la gloutonnerie, les querelles, les bagarres, les insultes, la désobéissance, l''escroquerie, les murmures, les plaintes.', 'Seigneur Jésus, aide-moi à haïr : l''ingratitude, la fausseté (mensonge, malhonnêteté, hypocrisie, ruse, dissimulation, duplicité, tricherie, fraude), le manque de pardon, l''amertume, la colère, l''entêtement envers les aînés, le niveau de vie très élevé, le vol, le sommeil en excès, la saleté, la paresse, l''indiscipline et le désordre, l''amour de la nourriture, l''autojustification, les manifestations impures de la puberté, les ambitions mondaines, la rébellion, la gloutonnerie, les querelles, les bagarres, les insultes, la désobéissance, l''escroquerie, les murmures, les plaintes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_052', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, accorde à chacun des enfants d''abandonner chacun de ces péchés et d''en être délivré.', 'Seigneur, accorde à chacun des enfants d''abandonner chacun de ces péchés et d''en être délivré.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_053', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, donne à chacun des enfants de haïr les mauvaises compagnies et de s''en séparer.', 'Seigneur, donne à chacun des enfants de haïr les mauvaises compagnies et de s''en séparer.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_054', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, donne à chaque enfant de se séparer de toutes mauvaises influences et de haïr les œuvres des ténèbres.', 'Seigneur Jésus, aide-moi à se séparer de toutes mauvaises influences et de haïr les œuvres des ténèbres.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_055', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, révèle à chaque enfant que Tu comptes sur lui, et qu''il ne Te sera utile que si son cœur est pur et rempli du Saint-Esprit.', 'Seigneur, révèle à chaque enfant que Tu comptes sur lui, et qu''il ne Te sera utile que si son cœur est pur et rempli du Saint-Esprit.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_056', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, donne à chaque enfant de conserver son corps dans la sainteté et la pureté absolue.', 'Seigneur Jésus, aide-moi à conserver son corps dans la sainteté et la pureté absolue.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_057', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, dès leur jeune âge, accorde à ces enfants de voir combien destructif est le péché.', 'Seigneur, dès leur jeune âge, accorde à ces enfants de voir combien destructif est le péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_058', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, délivre chacun du mensonge du diable qui les pousse à tomber dans le péché pour montrer à leurs parents qu''ils ne peuvent plus les contrôler.', 'Seigneur, délivre chacun du mensonge du diable qui les pousse à tomber dans le péché pour montrer à leurs parents qu''ils ne peuvent plus les contrôler.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_059', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, donne à chaque enfant de haïr, de se séparer et d''abandonner tout péché d''immoralité sexuelle et de garder sa pureté avant le mariage.', 'Seigneur Jésus, aide-moi à haïr, de se séparer et d''abandonner tout péché d''immoralité sexuelle et de garder sa pureté avant le mariage.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_060', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Réveil dans l''attitude vis-à-vis du péché (I)', 2, '1 Thessaloniciens 4:3-4',
        FALSE, 'Seigneur, accorde à chaque enfant de Te consacrer ses émotions.', 'Seigneur Jésus, aide-moi à Te consacrer ses émotions.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_061', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, merci parce que Ta parfaite volonté est que {PRENOM} soit saint(e).', 'Seigneur, merci parce que Ta parfaite volonté est que [Mon Prénom] soit saint(e).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_062', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, merci pour Jésus-Christ, la sanctification de {PRENOM}.', 'Seigneur, merci pour Jésus-Christ, la sanctification de [Mon Prénom].'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_063', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, merci parce que Toi-même, Tu es à l''œuvre pour sanctifier {PRENOM}.', 'Seigneur, merci parce que Toi-même, Tu es à l''œuvre pour sanctifier [Mon Prénom].'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_064', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, ouvre les yeux de {PRENOM} pour voir la laideur et l''horreur du péché.', 'Seigneur, ouvre les yeux de [Mon Prénom] pour voir la laideur et l''horreur du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_065', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, accorde à {PRENOM} la révélation du fait que chaque péché est comme un couteau enfoncé dans Ton cœur, et il Te fait mal.', 'Seigneur, accorde à [Mon Prénom] la révélation du fait que chaque péché est comme un couteau enfoncé dans Ton cœur, et il Te fait mal.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_066', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, donne à {PRENOM} de ressentir la douleur que Tu ressens chaque fois qu''il/elle pèche.', 'Seigneur, donne à [Mon Prénom] de ressentir la douleur que Tu ressens chaque fois qu''il/elle pèche.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_067', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        FALSE, 'Seigneur, accorde-lui de se repentir de tout son cœur avec une ferme détermination d''enlever ce couteau de Ton cœur.', 'Seigneur, accorde-lui de se repentir de tout son cœur avec une ferme détermination d''enlever ce couteau de Ton cœur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_068', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, donne à {PRENOM} de haïr la compagnie des pécheurs et qu''il/elle s''en sépare.', 'Seigneur, donne à [Mon Prénom] de haïr la compagnie des pécheurs et qu''il/elle s''en sépare.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_069', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, donne à {PRENOM} de haïr tous les péchés commis par les enfants de son âge : mensonge, vol, bagarres, insultes, rébellion contre les parents et l''autorité, et toute forme d''impureté.', 'Seigneur, donne à [Mon Prénom] de haïr tous les péchés commis par les enfants de son âge : mensonge, vol, bagarres, insultes, rébellion contre les parents et l''autorité, et toute forme d''impureté.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_070', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, donne à {PRENOM} la révélation de ce qu''aucun pécheur n''entrera dans Ton Royaume.', 'Seigneur, donne à [Mon Prénom] la révélation de ce qu''aucun pécheur n''entrera dans Ton Royaume.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_071', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, accorde à {PRENOM} de se détourner du péché par crainte de Dieu, et non par crainte des conséquences du péché.', 'Seigneur, accorde à [Mon Prénom] de se détourner du péché par crainte de Dieu, et non par crainte des conséquences du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_072', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, accorde à {PRENOM} de se détourner du péché par crainte de Dieu, et non par crainte de la punition corporelle.', 'Seigneur, accorde à [Mon Prénom] de se détourner du péché par crainte de Dieu, et non par crainte de la punition corporelle.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_073', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, accorde à {PRENOM} d''abandonner tout péché, parce qu''il/elle veut être agréable à Dieu.', 'Seigneur, accorde à [Mon Prénom] d''abandonner tout péché, parce qu''il/elle veut être agréable à Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_074', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, accorde à {PRENOM} de se garder pur(e) et saint(e), loin de toutes souillures, parce que Dieu est saint.', 'Seigneur, accorde à [Mon Prénom] de se garder pur(e) et saint(e), loin de toutes souillures, parce que Dieu est saint.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_075', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        FALSE, 'Seigneur, qu''il/elle soit un Josias, ayant cru petit/jeune, s''étant gardé pur et saint jusqu''à l''âge adulte, pour Dieu.', 'Seigneur, qu''il/elle soit un Josias, ayant cru petit/jeune, s''étant gardé pur et saint jusqu''à l''âge adulte, pour Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_076', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, que {PRENOM} Te serve dans la sainteté et la pureté tous les jours de sa vie.', 'Seigneur, que [Mon Prénom] Te serve dans la sainteté et la pureté tous les jours de sa vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_077', 'PARENT', 'REQUEST',
        'CAT_03', 'SUB_03_05',
        'Réveil dans l''attitude vis-à-vis du péché (II - Personnalisé)', 3, 'Lévitique 19:2 ; Apocalypse 21:27',
        TRUE, 'Seigneur, sois glorifié par {PRENOM} et par sa vie et son service à Toi.', 'Seigneur, sois glorifié par [Mon Prénom] et par sa vie et son service à Toi.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_078', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que nos enfants deviennent des chercheurs de DIEU par : a. Les rencontres dynamiques quotidiennes avec DIEU ; b. Les retraites de prières (15 minutes x 4) ; c. La lecture biblique ; d. La lecture de nos littératures chrétiennes ; e. Le jeûne.', 'Seigneur, que nos enfants deviennent des chercheurs de DIEU par : a. Les rencontres dynamiques quotidiennes avec DIEU ; b. Les retraites de prières (15 minutes x 4) ; c. La lecture biblique ; d. La lecture de nos littératures chrétiennes ; e. Le jeûne.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_079', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que nous parents puissions veiller sur la vie de méditation de nos enfants.', 'Seigneur, que nous parents puissions veiller sur la vie de méditation de nos enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_080', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que nous parents puissions contrôler la méditation de nos enfants.', 'Seigneur, que nous parents puissions contrôler la méditation de nos enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_081', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que l''utilisation des 4 x 15 minutes de retraites de prières soit enseignée aux enfants.', 'Seigneur, que l''utilisation des 4 x 15 minutes de retraites de prières soit enseignée aux enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_082', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, crée la faim de Toi-même dans le cœur de nos enfants afin qu''ils puissent lire Ta Parole chaque jour.', 'Seigneur, crée la faim de Toi-même dans le cœur de nos enfants afin qu''ils puissent lire Ta Parole chaque jour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_083', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, crée dans leur cœur une profonde haine du péché.', 'Seigneur, crée dans leur cœur une profonde haine du péché.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_084', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, crée dans leur cœur une profonde haine du monde et des choses du monde. Qu''ils en soient radicalement séparés.', 'Seigneur, crée dans leur cœur une profonde haine du monde et des choses du monde. Qu''ils en soient radicalement séparés.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_085', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, accorde que les ministres aux enfants soient des chercheurs de DIEU par les RDQAD, les retraites de prière (4x15 min), la lecture biblique, la littérature chrétienne, le jeûne, les comptes rendus, la prière seul et la prière avec les autres.', 'Seigneur, accorde que les ministres aux enfants soient des chercheurs de DIEU par les RDQAD, les retraites de prière (4x15 min), la lecture biblique, la littérature chrétienne, le jeûne, les comptes rendus, la prière seul et la prière avec les autres.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_086', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, accorde que les ministres aux enfants soient préoccupés par l''impact de leur ministère pendant et après, et que cela les pousse à se retirer dans Ta présence pendant au moins trois heures pour rechercher Ta puissance.', 'Seigneur, accorde que les ministres aux enfants soient préoccupés par l''impact de leur ministère pendant et après, et que cela les pousse à se retirer dans Ta présence pendant au moins trois heures pour rechercher Ta puissance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_087', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, crée de la crainte dans leur cœur de se présenter devant les enfants juste avec leur connaissance intellectuelle charnelle.', 'Seigneur, crée de la crainte dans leur cœur de se présenter devant les enfants juste avec leur connaissance intellectuelle charnelle.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_088', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, révèle à chaque ministre aux enfants ce qu''est le ministère aux enfants à la CMCI et ce que cela exige.', 'Seigneur, révèle à chaque ministre aux enfants ce qu''est le ministère aux enfants à la CMCI et ce que cela exige.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_089', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, ouvre les yeux de chacun pour voir que l''avenir de l''Église dépend de ce qu''ils auront été eux-mêmes et de ce qu''ils auront enseigné aux enfants.', 'Seigneur, ouvre les yeux de chacun pour voir que l''avenir de l''Église dépend de ce qu''ils auront été eux-mêmes et de ce qu''ils auront enseigné aux enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_090', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, suscite des ministres qui seront totalement saisis et possédés par le désir de voir les enfants profondément transformés par DIEU, et qui s''investiront dans le jeûne et la prière pour les enfants.', 'Seigneur, suscite des ministres qui seront totalement saisis et possédés par le désir de voir les enfants profondément transformés par DIEU, et qui s''investiront dans le jeûne et la prière pour les enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_091', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, qu''ils jeûnent et prient pour les enfants de façon incessante, persistante, de plus en plus croissante.', 'Seigneur, aide-moi à ce que je jeûnent et prient pour les enfants de façon incessante, persistante, de plus en plus croissante.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_092', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, j''amène à l''existence une chambre, un lieu de prière pour les enfants, où les gens prieront sans cesse pour les enfants.', 'Seigneur, j''amène à l''existence une chambre, un lieu de prière pour les enfants, où les gens prieront sans cesse pour les enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_093', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, j''amène à l''existence une chaîne de jeûne de 24 heures par personne pour les enfants, afin que ces derniers soient couverts 24 heures sur 24.', 'Seigneur, j''amène à l''existence une chaîne de jeûne de 24 heures par personne pour les enfants, afin que ces derniers soient couverts 24 heures sur 24.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_094', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les enfants et le ministère aux enfants dans les nations soient 24 heures sur 24 présentés à DIEU au travers des jeûnes et prières.', 'Seigneur, que les enfants et le ministère aux enfants dans les nations soient 24 heures sur 24 présentés à DIEU au travers des jeûnes et prières.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_095', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, élargis le cœur des ministres aux enfants pour porter la croissance en nombre des enfants.', 'Seigneur, élargis le cœur des ministres aux enfants pour porter la croissance en nombre des enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_096', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les enfants qui ont cru soient faits disciples par quelqu''un qui connaît la valeur d''un enfant devant Toi.', 'Seigneur, que les enfants qui ont cru soient faits disciples par quelqu''un qui connaît la valeur d''un enfant devant Toi.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_097', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que la formation des enfants disciples soit prise au sérieux.', 'Seigneur, que la formation des enfants disciples soit prise au sérieux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_098', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que des prières de qualité et en quantité soient investies pour libérer la puissance nécessaire pour amener les enfants à DIEU.', 'Seigneur, que des prières de qualité et en quantité soient investies pour libérer la puissance nécessaire pour amener les enfants à DIEU.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_099', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les prières soient investies sur les enfants pour les garder dans Ta bergerie et les y établir jusqu''à Ton retour.', 'Seigneur, que les prières soient investies sur les enfants pour les garder dans Ta bergerie et les y établir jusqu''à Ton retour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_100', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, qu''aucun ministre aux enfants ne reste oisif dans le ministère aux enfants mais que chacun s''investisse sur les enfants.', 'Seigneur, qu''aucun ministre aux enfants ne reste oisif dans le ministère aux enfants mais que chacun s''investisse sur les enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_101', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les enfants de ce ministère aux enfants soient justes devant DIEU.', 'Seigneur, que les enfants de ce ministère aux enfants soient justes devant DIEU.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_102', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, oins tous ceux-là qui prêchent aux enfants et les conduisent au Seigneur.', 'Seigneur, oins tous ceux-là qui prêchent aux enfants et les conduisent au Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_103', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que dès leur conversion, ils soient baptisés dans l''eau et dans le SAINT-ESPRIT.', 'Seigneur, que dès leur conversion, ils soient baptisés dans l''eau et dans le SAINT-ESPRIT.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_104', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que tous les enfants puissent donner leurs dîmes et offrandes.', 'Seigneur, que tous les enfants puissent donner leurs dîmes et offrandes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_105', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, protège tout enfant qui rend ministère en public (chant, récits, sketches, etc.).', 'Seigneur, protège tout enfant qui rend ministère en public (chant, récits, sketches, etc.).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_106', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les parents puissent consacrer leurs enfants.', 'Seigneur, que les parents puissent consacrer leurs enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_107', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les parents conduisent les enfants à se consacrer eux-mêmes.', 'Seigneur, que les parents conduisent les enfants à se consacrer eux-mêmes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_108', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, suscite du ministère aux enfants des enfants avec des ministères spécifiques : évangélisation, enseignement, prophétie, exhortation, prière, jeûne.', 'Seigneur, suscite du ministère aux enfants des enfants avec des ministères spécifiques : évangélisation, enseignement, prophétie, exhortation, prière, jeûne.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_109', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les dévotions familiales deviennent une réalité et soient établies dans toute famille de croyants.', 'Seigneur, que les dévotions familiales deviennent une réalité et soient établies dans toute famille de croyants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_110', 'MINISTER', 'REQUEST',
        'CAT_02', 'SUB_02_03',
        'Réveil dans l''attitude vis-à-vis de la prière et la méditation', 3, '1 Timothée 4:12',
        FALSE, 'Seigneur, que les enfants connaissent un grand réveil dans leur attitude vis-à-vis du péché sous toutes ses formes.', 'Seigneur, que les enfants connaissent un grand réveil dans leur attitude vis-à-vis du péché sous toutes ses formes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_111', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, crée dans le cœur de chaque EMI (enfant missionnaire international) une profonde haine du monde et des choses qui sont dans le monde.', 'Seigneur, crée dans le cœur de chaque EMI (enfant missionnaire international) une profonde haine du monde et des choses qui sont dans le monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_112', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, révèle aux enfants le fait que le monde et tout ce qui s''y trouve sont jugés et passeront, afin qu''ils ne se laissent pas séduire.', 'Seigneur, révèle aux enfants le fait que le monde et tout ce qui s''y trouve sont jugés et passeront, afin qu''ils ne se laissent pas séduire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_113', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, accorde à chaque enfant de haïr, d''abandonner et d''être délivré de : l''amour de la télévision, des compagnies du monde, l''admiration des stars, le désir d''être admiré par le sexe opposé, les coiffures et vêtements/chaussures à la mode, les bijoux et produits de beauté excessifs, les balades sans but, la musique et danse mondaines, la recherche de gloire personnelle.', 'Seigneur Jésus, aide-moi à haïr, d''abandonner et d''être délivré de : l''amour de la télévision, des compagnies du monde, l''admiration des stars, le désir d''être admiré par le sexe opposé, les coiffures et vêtements/chaussures à la mode, les bijoux et produits de beauté excessifs, les balades sans but, la musique et danse mondaines, la recherche de gloire personnelle.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_114', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, donne à chacun d''aimer être méprisé, insulté, marginalisé par les autres enfants à cause de Christ.', 'Seigneur, donne à chacun d''aimer être méprisé, insulté, marginalisé par les autres enfants à cause de Christ.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_115', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, donne à chacun de haïr le fruit provenant du péché, quelque bon ou « sucré » pourrait-il être.', 'Seigneur, donne à chacun de haïr le fruit provenant du péché, quelque bon ou « sucré » pourrait-il être.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_116', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les de l''amour des friandises.', 'Seigneur, protège-moi et libère-moi de l''amour des friandises.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_117', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les de l''amour des dons, des cadeaux, des choses gratuites.', 'Seigneur, protège-moi et libère-moi de l''amour des dons, des cadeaux, des choses gratuites.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_118', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les de l''amour des films mondains et immoraux.', 'Seigneur, protège-moi et libère-moi de l''amour des films mondains et immoraux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_119', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les de l''amour des romans-photos.', 'Seigneur, protège-moi et libère-moi de l''amour des romans-photos.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_120', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les du désir de faire comme les enfants de son âge.', 'Seigneur, délivre-les du désir de faire comme les enfants de son âge.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_121', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les du désir de recevoir des lettres ou messages sentimentaux de quelqu''un du sexe opposé.', 'Seigneur, délivre-les du désir de recevoir des lettres ou messages sentimentaux de quelqu''un du sexe opposé.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_122', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les du désir d''être comme l''une des grandes vedettes du monde.', 'Seigneur, délivre-les du désir d''être comme l''une des grandes vedettes du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_123', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, délivre-les de l''amour de la célébrité et de la poursuite de la gloire personnelle.', 'Seigneur, protège-moi et libère-moi de l''amour de la célébrité et de la poursuite de la gloire personnelle.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_124', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, donne à chacun une révélation de : la gloire de la vie chrétienne, la gloire d''être saint, la gloire d''être consacré, la gloire de vivre totalement pour Jésus, la gloire de l''éternité avec Dieu, la gloire de l''intimité avec Dieu, la gloire d''être un amoureux de Dieu.', 'Seigneur, donne à chacun une révélation de : la gloire de la vie chrétienne, la gloire d''être saint, la gloire d''être consacré, la gloire de vivre totalement pour Jésus, la gloire de l''éternité avec Dieu, la gloire de l''intimité avec Dieu, la gloire d''être un amoureux de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_125', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, qu''aucun d''eux ne bâtisse une quelconque relation mondaine.', 'Seigneur, qu''aucun d''eux ne bâtisse une quelconque relation mondaine.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_126', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, révèle à ces enfants la beauté du Royaume des Cieux et qu''ils apprennent à l''aimer.', 'Seigneur, révèle à ces enfants la beauté du Royaume des Cieux et qu''ils apprennent à l''aimer.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_127', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_04', 'SUB_04_01',
        'Réveil dans l''attitude vis-à-vis du monde et des choses du monde', 4, '1 Jean 2:15-17',
        FALSE, 'Seigneur, que ce jour se lève où chacun pourra dire : « Le monde avec tout ce qu''il peut offrir de meilleur a perdu sa saveur. Mon royaume c''est le Royaume du Seigneur Jésus. Je lui appartiens », et que cela soit travaillé dans tous les domaines de sa vie.', 'Seigneur, que ce jour se lève où chacun pourra dire : « Le monde avec tout ce qu''il peut offrir de meilleur a perdu sa saveur. Mon royaume c''est le Royaume du Seigneur Jésus. Je lui appartiens », et que cela soit travaillé dans tous les domaines de sa vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_128', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne à chacun de mes enfants la révélation de ce qu''est avoir l''intimité avec Dieu.', 'Seigneur, donne à chacun de mes enfants la révélation de ce qu''est avoir l''intimité avec Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_129', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, crée dans leurs cœurs un profond désir de connaître Dieu comme son Père à lui, de l''entendre lui parler chaque jour.', 'Seigneur, crée dans leurs cœurs un profond désir de connaître Dieu comme son Père à lui, de l''entendre lui parler chaque jour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_130', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne-leur la révélation de la sainteté de Dieu, afin qu''en aucun moment il ne se présente à Toi avec un quelconque péché dans sa vie.', 'Seigneur, donne-leur la révélation de la sainteté de Dieu, afin qu''en aucun moment il ne se présente à Toi avec un quelconque péché dans sa vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_131', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''ils reçoivent de Toi un message clair chaque fois qu''ils méditent. Donne-leur la capacité de T''entendre et T''obéir promptement.', 'Seigneur, aide-moi à ce que je reçoivent de Toi un message clair chaque fois qu''ils méditent. Donne-leur la capacité de T''entendre et T''obéir promptement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_132', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''ils usent de violence pour se réveiller très tôt le matin pour Te rencontrer.', 'Seigneur, aide-moi à ce que je usent de violence pour se réveiller très tôt le matin pour Te rencontrer.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_133', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''étant ainsi exposés à Ta Parole sur une base quotidienne, ils soient profondément transformés.', 'Seigneur, qu''étant ainsi exposés à Ta Parole sur une base quotidienne, ils soient profondément transformés.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_134', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''ils aient au moins 5 RDQAD (rencontres dynamiques quotidiennes avec Dieu) par semaine.', 'Seigneur, aide-moi à ce que je aient au moins 5 RDQAD (rencontres dynamiques quotidiennes avec Dieu) par semaine.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_135', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, bénis chacun de mes enfants avec la capacité de s''imposer une discipline qui lui permettra de lire entièrement la Bible une fois par an.', 'Seigneur, bénis chacun de mes enfants avec la capacité de s''imposer une discipline qui lui permettra de lire entièrement la Bible une fois par an.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_136', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne-leur d''aimer profondément Ta Parole, afin qu''ils la lisent non pour calmer leur conscience, mais parce qu''ils l''aiment.', 'Seigneur, donne-leur d''aimer profondément Ta Parole, afin qu''ils la lisent non pour calmer leur conscience, mais parce qu''ils l''aiment.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_137', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, parle-leur pendant qu''ils la lisent.', 'Seigneur, parle-leur pendant qu''ils la lisent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_138', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, que la condition de leur cœur leur soit exposée pendant qu''ils lisent Ta Parole, et donne-leur l''honnêteté de cœur pour abandonner tout ce qui n''est pas conforme.', 'Seigneur, que la condition de leur cœur leur soit exposée pendant qu''ils lisent Ta Parole, et donne-leur l''honnêteté de cœur pour abandonner tout ce qui n''est pas conforme.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_139', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, purifie-les et sanctifie-les pendant qu''ils lisent Ta Parole.', 'Seigneur, purifie-les et sanctifie-les pendant qu''ils lisent Ta Parole.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_140', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, conduis-les à mémoriser certaines portions de la Bible, qu''ils réciteront souvent.', 'Seigneur, conduis-les à mémoriser certaines portions de la Bible, qu''ils réciteront souvent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_141', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne-leur la capacité de garder Ta Parole dans leur cœur pour la mettre en pratique.', 'Seigneur, donne-leur la capacité de garder Ta Parole dans leur cœur pour la mettre en pratique.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_142', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, crée dans le cœur de chacun de mes enfants la capacité de Te croire pour pouvoir prier.', 'Seigneur, mets dans mon cœur de mes enfants la capacité de Te croire pour pouvoir prier.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_143', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, révèle-Toi à eux comme leur Père personnel, et qu''ils se sentent libres de venir à Toi pour Te parler.', 'Seigneur, révèle-Toi à eux comme leur Père personnel, et qu''ils se sentent libres de venir à Toi pour Te parler.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_144', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''ils puissent respecter et aimer les retraites de 15 minutes de prière pour enfants.', 'Seigneur, aide-moi à ce que je puissent respecter et aimer les retraites de 15 minutes de prière pour enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_145', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, délivre-les de toute paresse.', 'Seigneur, protège-moi et libère-moi de toute paresse.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_146', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne-leur d''être prompts à crier à Toi en tout temps, et surtout quand ils sont en danger.', 'Seigneur, donne-leur d''être prompts à crier à Toi en tout temps, et surtout quand ils sont en danger.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_147', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, donne-leur d''aimer Ta présence pour pouvoir souvent se retirer seuls dans Ta présence.', 'Seigneur, donne-leur d''aimer Ta présence pour pouvoir souvent se retirer seuls dans Ta présence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_148', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, qu''ils prient souvent avec les autres frères.', 'Seigneur, aide-moi à ce que je prient souvent avec les autres frères.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_149', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, que ce jour se lève où mes enfants jeûneront tous les mercredis pour leur nation.', 'Seigneur, que ce jour se lève où mes enfants jeûneront tous les mercredis pour leur nation.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_150', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, puissent mes enfants se distinguer dès leur jeune âge comme des ministres du jeûne.', 'Seigneur, puissent mes enfants se distinguer dès leur jeune âge comme des ministres du jeûne.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_151', 'CHILD', 'REQUEST',
        'CAT_02', 'SUB_02_01',
        'Réveil dans l''intimité avec Dieu - RDQAD, Parole, Prière & Jeûne', 5, 'Psaume 63:2',
        FALSE, 'Seigneur, délivre chacun de mes enfants de l''amour de la nourriture et de la peur de mourir en jeûnant.', 'Seigneur, délivre chacun de mes enfants de l''amour de la nourriture et de la peur de mourir en jeûnant.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_152', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, merci pour tous mes enfants en qui Tu as mis le don d''évangélisation, protège cela.', 'Seigneur, merci pour tous mes enfants en qui Tu as mis le don d''évangélisation, protège cela.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_153', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, révèle-Toi à chacun de mes enfants pour qu''ils voient la condition de perdition des autres enfants et qu''ils leur prêchent.', 'Seigneur, révèle-Toi à chacun de mes enfants pour qu''ils voient la condition de perdition des autres enfants et qu''ils leur prêchent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_154', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que mes enfants soient un moyen au travers duquel les adultes parviendront à Ta connaissance.', 'Seigneur, que mes enfants soient un moyen au travers duquel les adultes parviendront à Ta connaissance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_155', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que chacun de mes enfants disciplinés ait aussi un disciple.', 'Seigneur, que chacun de mes enfants disciplinés ait aussi un disciple.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_156', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, donne à chacun de mes enfants de comprendre lui-même l''évangile par révélation pour pouvoir le présenter aux perdus.', 'Seigneur Jésus, aide-moi à comprendre lui-même l''évangile par révélation pour pouvoir le présenter aux perdus.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_157', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, préserve mes enfants de toute fausse doctrine.', 'Seigneur, préserve mes enfants de toute fausse doctrine.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_158', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que chacun de mes enfants nés de nouveau dans la CMCI ait un faiseur de disciple au sens propre du terme.', 'Seigneur, que chacun de mes enfants nés de nouveau dans la CMCI ait un faiseur de disciple au sens propre du terme.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_159', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, qu''une véritable relation de confiance et de transparence mutuelle soit établie entre l''enfant disciple et son faiseur de disciple.', 'Seigneur, qu''une véritable relation de confiance et de transparence mutuelle soit établie entre l''enfant disciple et son faiseur de disciple.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_160', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, protège chacun de mes enfants croyants de toute régression.', 'Seigneur, protège chacun de mes enfants croyants de toute régression.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_161', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, ouvre les yeux de chacun de mes enfants afin qu''ils voient ce que signifie « investir dans la banque du ciel » en donnant leurs dîmes et offrandes.', 'Seigneur, ouvre les yeux de chacun de mes enfants afin qu''ils voient ce que signifie « investir dans la banque du ciel » en donnant leurs dîmes et offrandes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_162', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, délivre-les de l''amour de l''argent, de la vanité et des choses du monde qui pourraient les pousser à dépenser leur argent dans l''achat des inutilités.', 'Seigneur, protège-moi et libère-moi de l''amour de l''argent, de la vanité et des choses du monde qui pourraient les pousser à dépenser leur argent dans l''achat des inutilités.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_163', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, donne à chacun de mes enfants la capacité de rendre compte dans tous les domaines de sa vie (marche avec Dieu, finances, études, autres).', 'Seigneur, donne à chacun de mes enfants la capacité de rendre compte dans tous les domaines de sa vie (marche avec Dieu, finances, études, autres).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_164', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que chacun de mes enfants soit intégré dans une assemblée de maison et qu''il y aille fidèlement par amour pour Toi.', 'Seigneur, que chacun de mes enfants soit intégré dans une assemblée de maison et qu''il y aille fidèlement par amour pour Toi.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_165', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que tous mes enfants authentiquement convertis soient baptisés dans l''eau et participent à la table du Seigneur.', 'Seigneur, que tous mes enfants authentiquement convertis soient baptisés dans l''eau et participent à la table du Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_166', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que chacun de mes enfants soit ambitieux pour le Seigneur pour lire au moins 6 livres chrétiens par an.', 'Seigneur, que chacun de mes enfants soit ambitieux pour le Seigneur pour lire au moins 6 livres chrétiens par an.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_167', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que le culte familial soit établi dans notre foyer et que chacun de mes enfants y soit présent et participe grandement.', 'Seigneur, que le culte familial soit établi dans notre foyer et que chacun de mes enfants y soit présent et participe grandement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_168', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que tous les petits apprennent à lire la Bible pendant les dévotions familiales.', 'Seigneur, que tous les petits apprennent à lire la Bible pendant les dévotions familiales.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_169', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que les dévotions familiales ne soient ni des moments de longue prédication ni de réprimandes, mais des moments remplis de Ta joie et de Ta paix profonde.', 'Seigneur, que les dévotions familiales ne soient ni des moments de longue prédication ni de réprimandes, mais des moments remplis de Ta joie et de Ta paix profonde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_170', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_03',
        'Réveil dans l''intimité avec Dieu - Évangélisation, Disciples, Dîmes & Culte Familial', 6, 'Matthieu 28:19-20 ; Matthieu 6:20',
        FALSE, 'Seigneur, que mes enfants prennent tellement goût au culte familial qu''ils seront les premiers à se réveiller et appeler les parents.', 'Seigneur, que mes enfants prennent tellement goût au culte familial qu''ils seront les premiers à se réveiller et appeler les parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_171', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'I. Lecture biblique : Qu''il apprenne à lire pendant les dévotions familiales et qu''il lise au moins 3 chapitres par jour afin d''achever sa Bible cette année.', 'I. Lecture biblique : Qu''il apprenne à lire pendant les dévotions familiales et qu''il lise au moins 3 chapitres par jour afin d''achever sa Bible cette année.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_172', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'II. Vie de RDQAD : Qu''il médite par écrit au moins cinq (5) fois par semaine, rencontre Dieu, entende Sa voix et Lui obéisse.', 'II. Vie de RDQAD : Qu''il médite par écrit au moins cinq (5) fois par semaine, rencontre Dieu, entende Sa voix et Lui obéisse.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_173', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'III. Vie de prière : Qu''il s''établisse dans les 4 retraites de prière de 15 minutes par jour et aime se retirer seul dans la présence de Dieu.', 'III. Vie de prière : Qu''il s''établisse dans les 4 retraites de prière de 15 minutes par jour et aime se retirer seul dans la présence de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_174', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'IV. Littérature chrétienne : Que sa faim et sa soif pour Dieu le poussent à lire une littérature chrétienne par mois.', 'IV. Littérature chrétienne : Que sa faim et sa soif pour Dieu le poussent à lire une littérature chrétienne par mois.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_175', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'V. Vie de dons à Dieu : Qu''il donne ses dîmes et ses offrandes chaque mois à partir de son argent de poche et des dons reçus.', 'V. Vie de dons à Dieu : Qu''il donne ses dîmes et ses offrandes chaque mois à partir de son argent de poche et des dons reçus.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_176', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'VI. Vie de jeûne : Qu''il jeûne un jour par semaine pour sa nation et ait aussi 3 jours de jeûne complet par mois.', 'VI. Vie de jeûne : Qu''il jeûne un jour par semaine pour sa nation et ait aussi 3 jours de jeûne complet par mois.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_177', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'VII. Dévotions familiales : Qu''il participe aux dévotions familiales (au moins 5 fois par semaine) et partage ce qu''il a reçu de la lecture du jour.', 'VII. Dévotions familiales : Qu''il participe aux dévotions familiales (au moins 5 fois par semaine) et partage ce qu''il a reçu de la lecture du jour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_178', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'VIII. Évangélisation : Qu''il soit capable par le Saint-Esprit de rendre clairement témoignage de son salut, gagne des âmes et fasse des disciples.', 'VIII. Évangélisation : Qu''il soit capable par le Saint-Esprit de rendre clairement témoignage de son salut, gagne des âmes et fasse des disciples.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_179', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'IX. Comptes-rendus : Qu''il rende compte de sa vie spirituelle, académique et financière dans un vrai cahier de compte-rendu.', 'IX. Comptes-rendus : Qu''il rende compte de sa vie spirituelle, académique et financière dans un vrai cahier de compte-rendu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_180', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'X. Église locale : Qu''il soit un membre actif d''une assemblée dans la nation et participe aux programmes de l''Église.', 'X. Église locale : Qu''il soit un membre actif d''une assemblée dans la nation et participe aux programmes de l''Église.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_181', 'CHILD', 'REQUEST',
        'CAT_10', 'SUB_10_02',
        'Réveil spirituel dans la vie des Enfants Missionnaires Internationaux (E.M.I.)', 7, 'Actes 1:8',
        FALSE, 'XI. Volonté de Dieu & 2065 : Qu''il reçoive la révélation qu''il est un missionnaire à part entière, aime leur champ de mission, et fasse partie du milliard de disciples en 2065 qui offrent au Seigneur une obéissance totale en toutes choses.', 'XI. Volonté de Dieu & 2065 : Qu''il reçoive la révélation qu''il est un missionnaire à part entière, aime leur champ de mission, et fasse partie du milliard de disciples en 2065 qui offrent au Seigneur une obéissance totale en toutes choses.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_182', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, crée la faim et la soif pour la Parole de Dieu dans le cœur de {PRENOM}.', 'Seigneur, crée la faim et la soif pour la Parole de Dieu dans le cœur de [Mon Prénom].'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_183', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, fais que cette faim et cette soif pour la Parole de Dieu s''approfondissent et s''intensifient chaque jour dans le cœur de {PRENOM}.', 'Seigneur, fais que cette faim et cette soif pour la Parole de Dieu s''approfondissent et s''intensifient chaque jour dans le cœur de [Mon Prénom].'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_184', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, qu''elles poussent {PRENOM} à lire abondamment la Bible.', 'Seigneur, qu''elles poussent [Mon Prénom] à lire abondamment la Bible.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_185', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, qu''elles poussent {PRENOM} à se retirer pour lire la Bible.', 'Seigneur, qu''elles poussent [Mon Prénom] à se retirer pour lire la Bible.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_186', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, qu''elles poussent {PRENOM} à la méditer jour et nuit (Josué 1:8).', 'Seigneur, qu''elles poussent [Mon Prénom] à la méditer jour et nuit (Josué 1:8).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_187', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, que Ta Parole ne s''éloigne point de la bouche de {PRENOM} (Josué 1:8).', 'Seigneur, que Ta Parole ne s''éloigne point de la bouche de [Mon Prénom] (Josué 1:8).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_188', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, donne à {PRENOM} de serrer Ta Parole dans son cœur (Psaume 119:11).', 'Seigneur, donne à [Mon Prénom] de serrer Ta Parole dans son cœur (Psaume 119:11).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_189', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, donne à {PRENOM} de se diriger d''après Ta Parole, afin de rendre pur son sentier (Psaume 119:9).', 'Seigneur, donne à [Mon Prénom] de se diriger d''après Ta Parole, afin de rendre pur son sentier (Psaume 119:9).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_190', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, ouvre les yeux de {PRENOM} afin qu''il/elle contemple les merveilles de Ta Parole (Psaume 119:18).', 'Seigneur, ouvre les yeux de [Mon Prénom] afin qu''il/elle contemple les merveilles de Ta Parole (Psaume 119:18).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_191', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, pendant que {PRENOM} lit Ta Parole et la médite, donne-lui d''aimer la vérité et de marcher dans la vérité (Psaume 119:30).', 'Seigneur, pendant que [Mon Prénom] lit Ta Parole et la médite, donne-lui d''aimer la vérité et de marcher dans la vérité (Psaume 119:30).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_192', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, donne à {PRENOM} de grandir dans la sanctification pendant qu''il/elle lit Ta Parole (Jean 17:17).', 'Seigneur, donne à [Mon Prénom] de grandir dans la sanctification pendant qu''il/elle lit Ta Parole (Jean 17:17).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_193', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, révèle à {PRENOM} les secrets de Ton cœur pendant qu''il/elle lit Ta Parole.', 'Seigneur, révèle à [Mon Prénom] les secrets de Ton cœur pendant qu''il/elle lit Ta Parole.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_194', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, qu''aucun événement, aucun degré de persécution ne pousse {PRENOM} à abandonner Ta Parole (Psaume 119:87).', 'Seigneur, qu''aucun événement, aucun degré de persécution ne pousse [Mon Prénom] à abandonner Ta Parole (Psaume 119:87).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_195', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, révèle à {PRENOM} la puissance créatrice de Ta Parole, afin qu''il/elle puisse la proclamer sur sa propre vie.', 'Seigneur, révèle à [Mon Prénom] la puissance créatrice de Ta Parole, afin qu''il/elle puisse la proclamer sur sa propre vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_196', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        FALSE, 'Seigneur, devant les choix de cette vie, donne-lui d''être guidé(e) et éclairé(e) par Ta Parole (Psaume 119:105).', 'Seigneur, devant les choix de cette vie, donne-lui d''être guidé(e) et éclairé(e) par Ta Parole (Psaume 119:105).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_197', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, affermis les pas de {PRENOM} dans Ta Parole et ne laisse aucune iniquité dominer sur lui/elle (Psaume 119:133).', 'Seigneur, affermis les pas de [Mon Prénom] dans Ta Parole et ne laisse aucune iniquité dominer sur lui/elle (Psaume 119:133).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_198', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, accorde à {PRENOM} de mémoriser des portions de Ta Parole et qu''il/elle les utilise en temps de crise, de combat.', 'Seigneur, accorde à [Mon Prénom] de mémoriser des portions de Ta Parole et qu''il/elle les utilise en temps de crise, de combat.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_199', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, donne à {PRENOM} d''aimer chanter Ta Parole avec de belles mélodies (Psaume 119:172).', 'Seigneur, donne à [Mon Prénom] d''aimer chanter Ta Parole avec de belles mélodies (Psaume 119:172).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_200', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, que la Bible devienne le livre de poche de {PRENOM}, le livre qu''il/elle aimera plus que tous les autres livres.', 'Seigneur, que la Bible devienne le livre de poche de [Mon Prénom], le livre qu''il/elle aimera plus que tous les autres livres.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_201', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, pendant que {PRENOM} lit Ta Parole, transforme-le/la en un(e) amoureux(se) du Seigneur.', 'Seigneur, pendant que [Mon Prénom] lit Ta Parole, transforme-le/la en un(e) amoureux(se) du Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_202', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, bénis {PRENOM} avec la capacité d''obéir à Tes commandements pendant qu''il/elle s''applique à les garder dans son cœur.', 'Seigneur, bénis [Mon Prénom] avec la capacité d''obéir à Tes commandements pendant qu''il/elle s''applique à les garder dans son cœur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_203', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, révèle à {PRENOM} toutes les bénédictions réservées à ceux qui observent Tes commandements et qui les aiment (Jean 14:21).', 'Seigneur, révèle à [Mon Prénom] toutes les bénédictions réservées à ceux qui observent Tes commandements et qui les aiment (Jean 14:21).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_204', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, transforme {PRENOM} en un(e) amoureux(se) de Dieu et un(e) amoureux(se) de Sa Parole.', 'Seigneur, transforme [Mon Prénom] en un(e) amoureux(se) de Dieu et un(e) amoureux(se) de Sa Parole.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_205', 'PARENT', 'REQUEST',
        'CAT_02', 'SUB_02_02',
        'Réveil dans l''attitude vis-à-vis de la Parole de Dieu', 8, 'Psaumes 119:105 ; Josué 1:8',
        TRUE, 'Seigneur, reçois toute la gloire pour cela que Tu accompliras dans la vie de {PRENOM}.', 'Seigneur, reçois toute la gloire pour cela que Tu accompliras dans la vie de [Mon Prénom].'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_206', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci Seigneur pour la protection que Tu accordes à mes enfants chaque jour.', 'Merci Seigneur pour la protection que Tu accordes à mes enfants chaque jour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_207', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci de les avoir protégés dans le sein maternel.', 'Merci de les avoir protégés dans le sein maternel.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_208', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci de les avoir protégés pendant les premiers mois de leur existence.', 'Merci de les avoir protégés pendant les premiers mois de leur existence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_209', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci Seigneur de ce que chacun est né avec tous ses organes.', 'Merci Seigneur de ce que chacun est né avec tous ses organes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_210', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci Seigneur pour Tes Anges qui campent autour d''eux chaque minute, chaque heure, chaque jour.', 'Merci Seigneur pour Tes Anges qui campent autour d''eux chaque minute, chaque heure, chaque jour.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_211', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci Seigneur pour la protection à la maison, à l''école, pendant leurs jeux, pendant le sommeil.', 'Merci Seigneur pour la protection à la maison, à l''école, pendant leurs jeux, pendant le sommeil.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_212', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci Seigneur pour la santé dont ils jouissent.', 'Merci Seigneur pour la santé dont ils jouissent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_213', 'PARENT', 'THANKSGIVING',
        'CAT_08', 'SUB_08_01',
        'Protection des enfants - Actions de grâces', 9, 'Psaume 91:11',
        FALSE, 'Merci pour la capacité de résister aux maladies.', 'Merci pour la capacité de résister aux maladies.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_214', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les enfants âgés de 0 à 9 mois contre toutes les maladies infantiles (rougeole, coqueluche, tuberculose, varicelle, poliomyélite, tétanos, maladies virales, paludisme cérébral).', 'Seigneur, protège les enfants âgés de 0 à 9 mois contre toutes les maladies infantiles (rougeole, coqueluche, tuberculose, varicelle, poliomyélite, tétanos, maladies virales, paludisme cérébral).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_215', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les enfants âgés de 9 mois à 3 ans contre toute maladie pouvant attaquer les enfants de leur âge et celles dues à la poussée dentaire.', 'Seigneur, protège les enfants âgés de 9 mois à 3 ans contre toute maladie pouvant attaquer les enfants de leur âge et celles dues à la poussée dentaire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_216', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, que les vaccins qui leur sont administrés soient bons et efficaces pour les immuniser.', 'Seigneur, que les vaccins qui leur sont administrés soient bons et efficaces pour les immuniser.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_217', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège tous les enfants à l''âge scolaire.', 'Seigneur, protège tous les enfants à l''âge scolaire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_218', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les enfants contre les accidents domestiques et extérieurs : noyades, électrocutions, chutes, explosions, brûlures, morsures d''animaux ou piqûres d''insectes venimeux.', 'Seigneur, protège les enfants contre les accidents domestiques et extérieurs : noyades, électrocutions, chutes, explosions, brûlures, morsures d''animaux ou piqûres d''insectes venimeux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_219', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les enfants contre tout enlèvement, abus et toute forme de violence.', 'Seigneur, protège les enfants contre tout enlèvement, abus et toute forme de violence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_220', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège la santé globale de chaque enfant : peau, yeux et vue, oreilles et ouïe, appareil digestif, appareil respiratoire, appareil circulatoire et sang, appareil excréteur, appareil reproducteur, système nerveux, os et muscles.', 'Seigneur, protège la santé globale de chaque enfant : peau, yeux et vue, oreilles et ouïe, appareil digestif, appareil respiratoire, appareil circulatoire et sang, appareil excréteur, appareil reproducteur, système nerveux, os et muscles.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_221', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège-les contre les balles perdues, tout projectile pendant leurs jeux et toute maladie due au changement de climat.', 'Seigneur, protège-moi contre les balles perdues, tout projectile pendant leurs jeux et toute maladie due au changement de climat.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_222', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les enfants avant, pendant et après le sevrage contre toute maladie de malnutrition.', 'Seigneur, protège les enfants avant, pendant et après le sevrage contre toute maladie de malnutrition.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_223', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège-les contre les agressions et les oppressions spirituelles.', 'Seigneur, protège-moi contre les agressions et les oppressions spirituelles.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_224', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège-les contre le paludisme, la fièvre, la grippe et toute épidémie.', 'Seigneur, protège-moi contre le paludisme, la fièvre, la grippe et toute épidémie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_225', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, préserve-les des jeux dangereux et de l''absorption accidentelle de produits toxiques ou d''objets dangereux, ainsi que de l''asphyxie.', 'Seigneur, préserve-les des jeux dangereux et de l''absorption accidentelle de produits toxiques ou d''objets dangereux, ainsi que de l''asphyxie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_226', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, purifie leur sang de tout germe de maladie et qu''ils soient tous en parfait état de santé.', 'Seigneur, purifie leur sang de tout germe de maladie et qu''ils soient tous en parfait état de santé.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_227', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, dès leur jeune âge, éloigne d''eux tout agent de l''ennemi, tout sataniste cherchant à les introduire dans une secte quelconque.', 'Seigneur, dès leur jeune âge, éloigne d''eux tout agent de l''ennemi, tout sataniste cherchant à les introduire dans une secte quelconque.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_228', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège-les contre les catastrophes naturelles (foudre, inondations, séismes, glissements de terrain).', 'Seigneur, protège-moi contre les catastrophes naturelles (foudre, inondations, séismes, glissements de terrain).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_229', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège-les contre les mauvaises influences (drogués, délinquants, trafiquants).', 'Seigneur, protège-moi contre les mauvaises influences (drogués, délinquants, trafiquants).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_230', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, protège les familles partant des nations pour le champ de mission : à la montée de l''avion, durant le vol, leurs documents, à l''atterrissage, dès leurs premiers pas sur le sol de la nation d''accueil jusqu''à leur lieu de résidence.', 'Seigneur, protège les familles partant des nations pour le champ de mission : à la montée de l''avion, durant le vol, leurs documents, à l''atterrissage, dès leurs premiers pas sur le sol de la nation d''accueil jusqu''à leur lieu de résidence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_231', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_02',
        'Protection physique, médicale, spirituelle et voyages', 9, 'Psaume 121:7-8',
        FALSE, 'Seigneur, qu''ils veillent dans la prière pendant que leurs parents sont absents pour le ministère et qu''ils connaissent un réveil spirituel dès leur arrivée sur le champ de mission.', 'Seigneur, aide-moi à ce que je veillent dans la prière pendant que leurs parents sont absents pour le ministère et qu''ils connaissent un réveil spirituel dès leur arrivée sur le champ de mission.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('WOMEN_30_49', 'SENIORS_50_100', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_232', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, merci pour le niveau scolaire de chacun des enfants, pour ceux qui sont à l''âge scolaire et pour les hommes et femmes qui les enseignent.', 'Seigneur, merci pour le niveau scolaire de chacun des enfants, pour ceux qui sont à l''âge scolaire et pour les hommes et femmes qui les enseignent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_233', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, ouvre l''intelligence de chaque enfant afin qu''aucun d''entre eux ne puisse ni reprendre une classe ni être renvoyé de l''établissement.', 'Seigneur, ouvre mon intelligence afin qu''aucun d''entre eux ne puisse ni reprendre une classe ni être renvoyé de l''établissement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_234', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, qu''ils aiment l''école, travaillent dur afin de Te glorifier par leurs résultats scolaires.', 'Seigneur, aide-moi à ce que je aiment l''école, travaillent dur afin de Te glorifier par leurs résultats scolaires.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_235', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, rends-les très attentifs en classe et éloigne d''eux les troubleurs ; qu''ils participent aux cours.', 'Seigneur, rends-les très attentifs en classe et éloigne d''eux les troubleurs ; qu''ils participent aux cours.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_236', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, qu''ils soient ponctuels, respectueux et reconnus comme disciplinés et faisant tous leurs devoirs.', 'Seigneur, aide-moi à ce que je soient ponctuels, respectueux et reconnus comme disciplinés et faisant tous leurs devoirs.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_237', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, accorde-leur la capacité de s''adapter à tout système scolaire et d''apprendre rapidement la langue de la nation où ils étudient.', 'Seigneur, accorde-leur la capacité de s''adapter à tout système scolaire et d''apprendre rapidement la langue de la nation où ils étudient.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_238', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, donne à chacun des enfants d''aimer ses enseignants et de ne pas critiquer les systèmes d''enseignement.', 'Seigneur, donne à chacun des enfants d''aimer ses enseignants et de ne pas critiquer les systèmes d''enseignement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_239', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, délivre-les de toute paresse et de toute tendance à l''oisiveté.', 'Seigneur, protège-moi et libère-moi de toute paresse et de toute tendance à l''oisiveté.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_240', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, qu''aucun d''eux ne soit trouvé ni parmi les tricheurs, ni parmi les mauvais élèves.', 'Seigneur, qu''aucun d''eux ne soit trouvé ni parmi les tricheurs, ni parmi les mauvais élèves.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_241', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, sépare-les de toutes mauvaises compagnies à l''école et protège-les contre toute injustice dans les notes.', 'Seigneur, sépare-les de toutes mauvaises compagnies à l''école et protège-les contre toute injustice dans les notes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_242', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, qu''ils apprennent non seulement pour passer, mais pour être parmi les meilleurs.', 'Seigneur, aide-moi à ce que je apprennent non seulement pour passer, mais pour être parmi les meilleurs.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_243', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, protège leur foi au milieu des non-croyants qui les entourent, et donne-leur de tenir ferme.', 'Seigneur, protège leur foi au milieu des non-croyants qui les entourent, et donne-leur de tenir ferme.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_244', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, donne-leur toute la discipline dont ils ont besoin dans l''utilisation du temps, pour le travail académique, les travaux domestiques et les affaires du Seigneur.', 'Seigneur, donne-leur toute la discipline dont ils ont besoin dans l''utilisation du temps, pour le travail académique, les travaux domestiques et les affaires du Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_245', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, pourvois à tout ce dont ils ont besoin tout le long de l''année scolaire (fournitures scolaires, pension, place dans les établissements).', 'Seigneur, pourvois à tout ce dont ils ont besoin tout le long de l''année scolaire (fournitures scolaires, pension, place dans les établissements).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_246', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, protège-les contre le surmenage, les trous de mémoire et l''oubli tout le long de leur vie scolaire.', 'Seigneur, protège-moi contre le surmenage, les trous de mémoire et l''oubli tout le long de leur vie scolaire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_247', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, que leurs résultats soient améliorés trimestre après trimestre, et que personne ne tombe dans la paresse après un bon résultat.', 'Seigneur, que leurs résultats soient améliorés trimestre après trimestre, et que personne ne tombe dans la paresse après un bon résultat.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_248', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, donne à ceux qui sont dans les classes d''examen la capacité de comprendre toutes les matières enseignées pour mieux travailler lors des examens.', 'Seigneur, donne à ceux qui sont dans les classes d''examen la capacité de comprendre toutes les matières enseignées pour mieux travailler lors des examens.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_249', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, donne-leur d''être vrais et transparents, afin de ne cacher à leurs parents aucun problème rencontré à l''école ; que leurs copies et bulletins soient présentés à leurs parents.', 'Seigneur, donne-leur d''être vrais et transparents, afin de ne cacher à leurs parents aucun problème rencontré à l''école ; que leurs copies et bulletins soient présentés à leurs parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_250', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, qu''ils soient éveillés sur le fait qu''on les regarde, qu''on les imite et qu''ils donnent le bon exemple.', 'Seigneur, aide-moi à ce que je soient éveillés sur le fait qu''on les regarde, qu''on les imite et qu''ils donnent le bon exemple.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_251', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, que les enfants puissent haïr la médiocrité et travailler dur pour de bons résultats.', 'Seigneur, que les enfants puissent haïr la médiocrité et travailler dur pour de bons résultats.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_252', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, donne-leur la capacité d''aimer les enseignants et les matières les plus difficiles.', 'Seigneur, donne-leur la capacité d''aimer les enseignants et les matières les plus difficiles.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_253', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, que la poursuite des diplômes ne soit pas une idole et qu''ils ne se détournent jamais de Dieu sous prétexte qu''ils veulent étudier.', 'Seigneur, que la poursuite des diplômes ne soit pas une idole et qu''ils ne se détournent jamais de Dieu sous prétexte qu''ils veulent étudier.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_254', 'CHILD', 'REQUEST',
        'CAT_07', 'SUB_07_01',
        'Vie académique et études - Actions de grâces & Requêtes', 12, 'Daniel 1:17 ; Deutéronome 28:13',
        FALSE, 'Seigneur, que chacun proclame des paroles positives sur lui-même en rapport avec le travail scolaire et les résultats.', 'Seigneur, que chacun proclame des paroles positives sur lui-même en rapport avec le travail scolaire et les résultats.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_255', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, merci de ce qu''il grandit au milieu de Ta Parole qu''il écoute au moins une fois par jour, et pour la vie des parents qui lui présente l''évangile.', 'Seigneur, merci de ce qu''il grandit au milieu de Ta Parole qu''il écoute au moins une fois par jour, et pour la vie des parents qui lui présente l''évangile.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_256', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, envoie vers mes enfants un croyant rempli de Ton Saint-Esprit qui croit qu''un enfant peut croire et qui lui présentera clairement l''évangile.', 'Seigneur, envoie vers mes enfants un croyant rempli de Ton Saint-Esprit qui croit qu''un enfant peut croire et qui lui présentera clairement l''évangile.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_257', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, ouvre leur intelligence et leur esprit pour comprendre les choses spirituelles et être attentifs.', 'Seigneur, ouvre leur intelligence et leur esprit pour comprendre les choses spirituelles et être attentifs.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_258', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, donne-leur la révélation de Jésus-Christ qui a porté tous leurs péchés à la croix, qui est mort pour eux, enseveli avec eux, ressuscité et intronisé avec eux, et qui intercède pour eux.', 'Seigneur, donne-leur la révélation de Jésus-Christ qui a porté tous leurs péchés à la croix, qui est mort pour eux, enseveli avec eux, ressuscité et intronisé avec eux, et qui intercède pour eux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_259', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, crée dans le cœur de cet enfant un brûlant désir d''être sauvé, afin qu''il pose lui-même la question : « Que faire donc pour être sauvé ? »', 'Seigneur, crée dans le cœur de cet enfant un brûlant désir d''être sauvé, afin qu''il pose lui-même la question : « Que faire donc pour être sauvé ? »'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_260', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, nous le séparons de toute familiarité avec la Parole de Dieu qu''il écoute chaque fois.', 'Seigneur, nous le séparons de toute familiarité avec la Parole de Dieu qu''il écoute chaque fois.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_261', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, qu''ils soient conduits à la prière de repentance avec tout le sérieux que cela exige.', 'Seigneur, aide-moi à ce que je soient conduits à la prière de repentance avec tout le sérieux que cela exige.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_262', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, qu''ils soient conduits aux eaux du baptême sans tarder et reçoivent l''assurance du salut par Ton Saint-Esprit.', 'Seigneur, aide-moi à ce que je soient conduits aux eaux du baptême sans tarder et reçoivent l''assurance du salut par Ton Saint-Esprit.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_263', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, que les croyants adultes croient qu''il est sauvé et le considèrent comme disciple du Seigneur Jésus.', 'Seigneur, que les croyants adultes croient qu''il est sauvé et le considèrent comme disciple du Seigneur Jésus.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_264', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, qu''il soit baptisé dans le Saint-Esprit et qu''un faiseur de disciple travaille cela dans le jeûne et la prière.', 'Seigneur, qu''il soit baptisé dans le Saint-Esprit et qu''un faiseur de disciple travaille cela dans le jeûne et la prière.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_265', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, remplis-le de Ton zèle pour prêcher même aux grandes personnes.', 'Seigneur, remplis-le de Ton zèle pour prêcher même aux grandes personnes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_266', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, donne-lui de recevoir Ton appel sur sa vie dans son tendre âge et d''y travailler au fur et à mesure qu''il grandira.', 'Seigneur, donne-lui de recevoir Ton appel sur sa vie dans son tendre âge et d''y travailler au fur et à mesure qu''il grandira.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_267', 'PARENT', 'REQUEST',
        'CAT_01', 'SUB_01_02',
        'Vie chrétienne : Salut, baptêmes et intégration dans l''Église', 13, 'Actes 2:38 ; Romains 6:4',
        FALSE, 'Seigneur, accorde-lui la capacité de vivre sa vie chrétienne partout où il se trouvera, que le fruit de l''Esprit abonde en lui et qu''il soit intègre et radical.', 'Seigneur, accorde-lui la capacité de vivre sa vie chrétienne partout où il se trouvera, que le fruit de l''Esprit abonde en lui et qu''il soit intègre et radical.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_268', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Seigneur, donne-leur de se joindre à l''assemblée et aide-les à ne point rétrograder ni quitter l''assemblée.', 'Seigneur, donne-leur de se joindre à l''assemblée et aide-les à ne point rétrograder ni quitter l''assemblée.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_269', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur une vision de l''Église de Maison pour voir leur besoin des frères et de l''assemblée.', 'Père, donne-leur une vision de l''Église de Maison pour voir leur besoin des frères et de l''assemblée.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_270', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur la capacité de suivre un mentor spirituel et suscite quelqu''un dans l''Assemblée à qui ils seront attachés avec foi et confiance.', 'Père, donne-leur la capacité de suivre un mentor spirituel et suscite quelqu''un dans l''Assemblée à qui ils seront attachés avec foi et confiance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_271', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, brise toutes les chaînes du passé qui les tiennent encore liés (attachements religieux, liens familiaux négatifs, amis mondains).', 'Père, brise toutes les chaînes du passé qui les tiennent encore liés (attachements religieux, liens familiaux négatifs, amis mondains).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_272', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur une connaissance divine du péché comme étant une attaque directe à la divinité, une trahison de Dieu et un poignard dans le cœur de Dieu.', 'Père, donne-leur une connaissance divine du péché comme étant une attaque directe à la divinité, une trahison de Dieu et un poignard dans le cœur de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_273', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur de connaître une haine divine et une repentance selon Dieu de tout péché d''immoralité, d''amour de l''argent (dettes, vol, escroquerie, corruption), de fausseté (mensonge, demi-vérités, exagérations) et d''orgueil.', 'Père, donne-leur de connaître une haine divine et une repentance selon Dieu de tout péché d''immoralité, d''amour de l''argent (dettes, vol, escroquerie, corruption), de fausseté (mensonge, demi-vérités, exagérations) et d''orgueil.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_274', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, brise et sépare-les de toute élévation de cœur, indépendance, déloyauté, apitoiement sur soi, justification de soi et réactions du « moi ».', 'Père, brise et sépare-les de toute élévation de cœur, indépendance, déloyauté, apitoiement sur soi, justification de soi et réactions du « moi ».'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_275', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, révèle-leur le monde pour ce qu''il est, ouvre leurs yeux pour voir que l''amitié avec le monde est inimitié contre Dieu, et brise tout désir pour la célébrité ou les positions du monde.', 'Père, révèle-leur le monde pour ce qu''il est, ouvre leurs yeux pour voir que l''amitié avec le monde est inimitié contre Dieu, et brise tout désir pour la célébrité ou les positions du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_276', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, crée une crise de consécration dans leurs vies afin qu''ils placent sur l''autel tout ce qu''ils sont (corps, âme et esprit), tout leur temps, leur énergie et leurs biens.', 'Père, crée une crise de consécration dans leurs vies afin qu''ils placent sur l''autel tout ce qu''ils sont (corps, âme et esprit), tout leur temps, leur énergie et leurs biens.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_277', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur de connaître une plénitude quotidienne du Saint-Esprit et d''exceller dans la poursuite de Dieu (prière individuelle, lecture biblique, dîmes, littérature chrétienne, réunions spirituelles).', 'Père, donne-leur de connaître une plénitude quotidienne du Saint-Esprit et d''exceller dans la poursuite de Dieu (prière individuelle, lecture biblique, dîmes, littérature chrétienne, réunions spirituelles).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_278', 'MINISTER', 'SPIRITUAL_WARFARE',
        'CAT_05', 'SUB_05_05',
        'Prier pour un croyant pour du fruit qui demeure', 14, 'Jean 15:16',
        FALSE, 'Père, donne-leur de grandir dans la connaissance de Dieu qui les stabilisera en dépit des difficultés, et de porter du fruit abondant dans l''évangélisation.', 'Père, donne-leur de grandir dans la connaissance de Dieu qui les stabilisera en dépit des difficultés, et de porter du fruit abondant dans l''évangélisation.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_279', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Seigneur, merci de ce qu''un enfant consacré à Dieu est un enfant totalement différent, et merci pour le privilège de Te consacrer chaque enfant.', 'Seigneur, merci de ce qu''un enfant consacré à Dieu est un enfant totalement différent, et merci pour le privilège de Te consacrer chaque enfant.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_280', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous séparons chaque enfant missionnaire de lui-même, de ses ambitions personnelles, ses plans, ses droits, ses goûts, ses pensées, ses émotions, sa volonté, ses études et ses diplômes.', 'Nous séparons chaque enfant missionnaire de lui-même, de ses ambitions personnelles, ses plans, ses droits, ses goûts, ses pensées, ses émotions, sa volonté, ses études et ses diplômes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_281', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous séparons chacun de nos enfants de tout héritage spirituel négatif de la famille paternelle ou maternelle, des ambitions purement humaines de ses parents, et des offres du monde.', 'Nous séparons chacun de nos enfants de tout héritage spirituel négatif de la famille paternelle ou maternelle, des ambitions purement humaines de ses parents, et des offres du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_282', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous séparons chacun de nos enfants du diable et des agents du diable, et de tous leurs plans et projets contre lui.', 'Nous séparons chacun de nos enfants du diable et des agents du diable, et de tous leurs plans et projets contre lui.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_283', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous consacrons chacun de nos enfants corps, âme et esprit au Seigneur.', 'Nous consacrons chacun de nos enfants corps, âme et esprit au Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_284', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous séparons leur pensée, leurs émotions, leur volonté, leur conscience, leur intuition et leur communion d''eux-mêmes, du diable et du monde, et nous les consacrons à Dieu.', 'Nous séparons leur pensée, leurs émotions, leur volonté, leur conscience, leur intuition et leur communion d''eux-mêmes, du diable et du monde, et nous les consacrons à Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_285', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Que ces enfants soient tout cela que Dieu a voulu qu''ils soient bien avant la fondation du monde.', 'Que ces enfants soient tout cela que Dieu a voulu qu''ils soient bien avant la fondation du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_286', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Nous détruisons tout gène de malédiction hérité et libérons les bénédictions de Dieu sur eux.', 'Nous détruisons tout gène de malédiction hérité et libérons les bénédictions de Dieu sur eux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_287', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Seigneur, que nous les parents puissions nous asseoir pour consacrer ensemble chacun de nos enfants et renoncer à nos droits égoïstes sur eux.', 'Seigneur, que nous les parents puissions nous asseoir pour consacrer ensemble chacun de nos enfants et renoncer à nos droits égoïstes sur eux.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_288', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_09', 'SUB_09_05',
        'Consécration des Enfants Missionnaires Internationaux', 15, '1 Samuel 1:27-28 ; Romains 12:1',
        FALSE, 'Seigneur, accorde à chacun de mes enfants de se consacrer à Dieu lui-même et que le message sur la consécration leur soit enseigné dans les moindres détails.', 'Seigneur Jésus, aide-moi à se consacrer à Dieu lui-même et que le message sur la consécration leur soit enseigné dans les moindres détails.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_289', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, merci pour la relation qui lie mes enfants à leur père et à leur mère, et parce que les enfants sont une bénédiction de Dieu.', 'Seigneur, merci pour la relation qui lie mes enfants à leur père et à leur mère, et parce que les enfants sont une bénédiction de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_290', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, Ta parfaite volonté est qu''il y ait la paix et l''harmonie dans les foyers de Tes élus. Nous détruisons tous les plans de l''ennemi visant à voler cette paix.', 'Seigneur, Ta parfaite volonté est qu''il y ait la paix et l''harmonie dans les foyers de Tes élus. Nous détruisons tous les plans de l''ennemi visant à voler cette paix.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_291', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, nous détruisons tous les plans du diable poussant les enfants à se rebeller contre les parents, à être ingrats, à mépriser l''autorité parentale ou à fuir le foyer.', 'Seigneur, nous détruisons tous les plans du diable poussant les enfants à se rebeller contre les parents, à être ingrats, à mépriser l''autorité parentale ou à fuir le foyer.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_292', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, que les parents ramènent Dieu dans leur foyer en ayant au moins 5 dévotions familiales par semaine auxquelles tous les enfants prennent part.', 'Seigneur, que les parents ramènent Dieu dans leur foyer en ayant au moins 5 dévotions familiales par semaine auxquelles tous les enfants prennent part.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_293', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, que les enfants fassent confiance à leurs parents en partageant avec eux toute difficulté et expérience de la journée.', 'Seigneur, que les enfants fassent confiance à leurs parents en partageant avec eux toute difficulté et expérience de la journée.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_294', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, bénis les enfants avec la capacité d''accepter d''être corrigés par leurs parents comme étant pour leur bien, et de pardonner à leurs parents, frères et sœurs.', 'Seigneur, bénis les enfants avec la capacité d''accepter d''être corrigés par leurs parents comme étant pour leur bien, et de pardonner à leurs parents, frères et sœurs.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_295', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, dispose le cœur des enfants à accepter et aimer l''appel de Dieu dans la vie de leurs parents.', 'Seigneur, dispose le cœur des enfants à accepter et aimer l''appel de Dieu dans la vie de leurs parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_296', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, que les parents travaillent dur pour être remplis du Saint-Esprit afin d''élever leurs enfants dans la crainte de Dieu.', 'Seigneur, que les parents travaillent dur pour être remplis du Saint-Esprit afin d''élever leurs enfants dans la crainte de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_297', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, détruis tous les plans du diable poussant les parents à prononcer des paroles négatives sur leurs enfants, et bénis-nous avec la capacité de prophétiser du bien pour nos enfants.', 'Seigneur, détruis tous les plans du diable poussant les parents à prononcer des paroles négatives sur leurs enfants, et bénis-nous avec la capacité de prophétiser du bien pour nos enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_298', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, par la puissance du Saint-Esprit, que le cœur des parents revienne à leurs enfants et vice-versa.', 'Seigneur, par la puissance du Saint-Esprit, que le cœur des parents revienne à leurs enfants et vice-versa.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_299', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, ouvre les yeux des parents sur leur responsabilité de s''assurer que chacun de leurs enfants est sauvé, baptisé, fait disciple, reçoit l''appel de Dieu et sert à la maison.', 'Seigneur, ouvre les yeux des parents sur leur responsabilité de s''assurer que chacun de leurs enfants est sauvé, baptisé, fait disciple, reçoit l''appel de Dieu et sert à la maison.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_300', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, qu''aucun enfant ne soit inscrit dans un établissement scolaire ou envoyé dans une famille hors de Ta parfaite volonté.', 'Seigneur, qu''aucun enfant ne soit inscrit dans un établissement scolaire ou envoyé dans une famille hors de Ta parfaite volonté.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_301', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_03',
        'Relation entre parents et enfants & Responsabilité des parents', 16, 'Malachie 4:6 ; Éphésiens 6:1-4',
        FALSE, 'Seigneur, que les parents veillent sur l''environnement et les fréquentations de leurs enfants et exercent une discipline selon la direction du Saint-Esprit.', 'Seigneur, que les parents veillent sur l''environnement et les fréquentations de leurs enfants et exercent une discipline selon la direction du Saint-Esprit.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_302', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, conduis les jeunes couples dans la planification familiale selon Ton temps marqué et Ta volonté parfaite.', 'Seigneur, conduis les jeunes couples dans la planification familiale selon Ton temps marqué et Ta volonté parfaite.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_303', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, sélectionne Toi-même le jour de la fécondation, protège la nidation et le développement harmonieux de l''œuf, de l''embryon et du fœtus jusqu''à terme.', 'Seigneur, sélectionne Toi-même le jour de la fécondation, protège la nidation et le développement harmonieux de l''œuf, de l''embryon et du fœtus jusqu''à terme.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_304', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, que nous soyons préparés physiquement, émotionnellement, psychologiquement et spirituellement pour recevoir l''enfant et prier pour lui avant sa naissance.', 'Seigneur, que nous soyons préparés physiquement, émotionnellement, psychologiquement et spirituellement pour recevoir l''enfant et prier pour lui avant sa naissance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_305', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, éloigne de nous toute mondanité dans la préparation de la layette et que nous acceptions avec joie le sexe de l''enfant que Tu nous donneras.', 'Seigneur, éloigne de nous toute mondanité dans la préparation de la layette et que nous acceptions avec joie le sexe de l''enfant que Tu nous donneras.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_306', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, que toutes les parties et organes du corps du fœtus soient parfaitement formés avant la naissance (cœur, cerveau, système nerveux, appareil digestif, excréteur, reproducteur, poumons, sens, sang et ossature) sans aucune anomalie.', 'Seigneur, que toutes les parties et organes du corps du fœtus soient parfaitement formés avant la naissance (cœur, cerveau, système nerveux, appareil digestif, excréteur, reproducteur, poumons, sens, sang et ossature) sans aucune anomalie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_307', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, choisis Toi-même le personnel médical et la clinique appropriée tout le long de la grossesse jusqu''à l''accouchement.', 'Seigneur, choisis Toi-même le personnel médical et la clinique appropriée tout le long de la grossesse jusqu''à l''accouchement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_308', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, protège la mère durant toute la grossesse (tension, glycémie, santé, harmonie conjugale) et délivre-la de toute peur le jour de l''accouchement.', 'Seigneur, protège la mère durant toute la grossesse (tension, glycémie, santé, harmonie conjugale) et délivre-la de toute peur le jour de l''accouchement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_309', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, sois au contrôle de tout le processus de l''accouchement, de l''ouverture du col à l''expulsion du bébé, sans complication ni hémorragie.', 'Seigneur, sois au contrôle de tout le processus de l''accouchement, de l''ouverture du col à l''expulsion du bébé, sans complication ni hémorragie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_310', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_02',
        'Foyers missionnaires, conception, grossesse et accouchement', 18, 'Psaume 139:13-16',
        FALSE, 'Seigneur, protège le nouveau-né dès sa naissance, accorde à la mère une bonne récupération et suffisamment de lait pour nourrir le bébé, et que ce nouveau-né Te soit consacré.', 'Seigneur, protège le nouveau-né dès sa naissance, accorde à la mère une bonne récupération et suffisamment de lait pour nourrir le bébé, et que ce nouveau-né Te soit consacré.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_311', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_05',
        'Protection des enfants pendant l''absence des parents pour le ministère', 20, 'Psaume 121:3-8',
        FALSE, 'Seigneur, protège ces enfants pendant l''absence des parents contre toute maladie subite, tout accident, tout enlèvement ou abus, toute intoxication et toute oppression spirituelle ou catastrophe naturelle.', 'Seigneur, protège ces enfants pendant l''absence des parents contre toute maladie subite, tout accident, tout enlèvement ou abus, toute intoxication et toute oppression spirituelle ou catastrophe naturelle.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_312', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_05',
        'Protection des enfants pendant l''absence des parents pour le ministère', 20, 'Psaume 121:3-8',
        FALSE, 'Seigneur, protège ces enfants contre toute régression spirituelle et préserve-les de se livrer au péché ou aux mauvaises fréquentations en l''absence de leurs parents.', 'Seigneur, protège ces enfants contre toute régression spirituelle et préserve-les de se livrer au péché ou aux mauvaises fréquentations en l''absence de leurs parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_313', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_05',
        'Protection des enfants pendant l''absence des parents pour le ministère', 20, 'Psaume 121:3-8',
        FALSE, 'Seigneur, bénis chaque famille avec un frère ou une sœur radicalement consacré(e) à Dieu qui veillera sur les enfants avec vigilance dans la prière pendant l''absence des parents.', 'Seigneur, bénis chaque famille avec un frère ou une sœur radicalement consacré(e) à Dieu qui veillera sur les enfants avec vigilance dans la prière pendant l''absence des parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_314', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_05',
        'Protection des enfants pendant l''absence des parents pour le ministère', 20, 'Psaume 121:3-8',
        FALSE, 'Seigneur, pourvois aux besoins matériels de chaque famille pendant l''absence des parents.', 'Seigneur, pourvois aux besoins matériels de chaque famille pendant l''absence des parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_315', 'PARENT', 'SPIRITUAL_WARFARE',
        'CAT_08', 'SUB_08_05',
        'Protection des enfants pendant l''absence des parents pour le ministère', 20, 'Psaume 121:3-8',
        FALSE, 'Seigneur, que les enfants soient conduits à prier pour leurs parents en mission et continuent fidèlement leur lecture biblique, leur méditation et leur vie de prière.', 'Seigneur, que les enfants soient conduits à prier pour leurs parents en mission et continuent fidèlement leur lecture biblique, leur méditation et leur vie de prière.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_316', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        TRUE, 'Seigneur, donne aux parents de {PRENOM} de croire que Tu peux et veux le/la guérir, et délivre-les de tout apitoiement sur soi et de tout découragement.', 'Seigneur, donne aux parents de [Mon Prénom] de croire que Tu peux et veux le/la guérir, et délivre-les de tout apitoiement sur soi et de tout découragement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_317', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, accorde à chaque parent de veiller sur sa marche avec Dieu afin que personne ne rétrograde à cause de l''état de santé de l''enfant.', 'Seigneur, accorde à chaque parent de veiller sur sa marche avec Dieu afin que personne ne rétrograde à cause de l''état de santé de l''enfant.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_318', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, accorde aux parents de vivre en harmonie sans s''accuser mutuellement, et de traiter l''enfant malade avec amour, tendresse et compassion sans en faire une idole.', 'Seigneur, accorde aux parents de vivre en harmonie sans s''accuser mutuellement, et de traiter l''enfant malade avec amour, tendresse et compassion sans en faire une idole.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_319', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, bénis ces parents avec la force intérieure pour s''élever au-dessus de l''épreuve et rendre ministère à d''autres familles.', 'Seigneur, bénis ces parents avec la force intérieure pour s''élever au-dessus de l''épreuve et rendre ministère à d''autres familles.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_320', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, merci pour Ta parfaite volonté concernant les couples sans enfants ; donne-leur de Te consacrer leur attente et d''entrer dans Ton repos.', 'Seigneur, merci pour Ta parfaite volonté concernant les couples sans enfants ; donne-leur de Te consacrer leur attente et d''entrer dans Ton repos.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_321', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, guéris et restaure pleinement la fertilité de chaque couple selon Ton temps convenable, et bénis-les avec un enfant de Ton choix.', 'Seigneur, guéris et restaure pleinement la fertilité de chaque couple selon Ton temps convenable, et bénis-les avec un enfant de Ton choix.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_322', 'PARENT', 'REQUEST',
        'CAT_09', 'SUB_09_04',
        'Soutien aux parents d''enfants malades & Couples sans enfants', 21, 'Marc 9:23 ; 1 Samuel 1:17',
        FALSE, 'Seigneur, ouvre leurs yeux afin qu''ils considèrent chaque enfant comme un don prêté par Dieu, afin de l''élever pour Toi et pour Ta gloire.', 'Seigneur, ouvre leurs yeux afin qu''ils considèrent chaque enfant comme un don prêté par Dieu, afin de l''élever pour Toi et pour Ta gloire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_323', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, merci de ce qu''à la croix Tu as eu la victoire sur tout esprit cherchant à troubler les enfants dès l''âge de dix ans.', 'Seigneur, merci de ce qu''à la croix Tu as eu la victoire sur tout esprit cherchant à troubler les enfants dès l''âge de dix ans.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_324', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, révèle à mes enfants combien éphémère est cet âge, afin qu''ils ne se laissent pas tromper par leur jeunesse ni attirer par les vanités du monde.', 'Seigneur, révèle à mes enfants combien éphémère est cet âge, afin qu''ils ne se laissent pas tromper par leur jeunesse ni attirer par les vanités du monde.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_325', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, délivre-les des passions de la jeunesse : l''auto-admiration, l''attrait précoce et désordonné pour le sexe opposé, les contenus impurs, les compagnies mondaines et l''esclavage de la mode (langage, coiffure, vêtements, danses).', 'Seigneur, délivre-les des passions de la jeunesse : l''auto-admiration, l''attrait précoce et désordonné pour le sexe opposé, les contenus impurs, les compagnies mondaines et l''esclavage de la mode (langage, coiffure, vêtements, danses).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_326', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, délivre-les de tout esprit d''indépendance, d''insolence envers les aînés et de tout désir de fuir l''autorité parentale.', 'Seigneur, protège-moi et libère-moi de tout esprit d''indépendance, d''insolence envers les aînés et de tout désir de fuir l''autorité parentale.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_327', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, brise l''orgueil de leur vie et détruis toute haute pensée qu''ils ont d''eux-mêmes.', 'Seigneur, brise l''orgueil de leur vie et détruis toute haute pensée qu''ils ont d''eux-mêmes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_328', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, sépare-les de toute mauvaise compagnie et éloigne d''eux le désir d''aller goûter aux plaisirs du monde avant de revenir servir Dieu.', 'Seigneur, sépare-les de toute mauvaise compagnie et éloigne d''eux le désir d''aller goûter aux plaisirs du monde avant de revenir servir Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_329', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, délivre-les de toute distraction dans les réunions et bénis-les avec la capacité d''aimer Ta présence.', 'Seigneur, protège-moi et libère-moi de toute distraction dans les réunions et bénis-les avec la capacité d''aimer Ta présence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_330', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, délivre-les de l''immoralité sexuelle sous toutes ses formes (en pensées, en paroles et en actes) et protège leur pureté jusqu''au jour de leur mariage selon Ta volonté.', 'Seigneur, protège-moi et libère-moi de l''immoralité sexuelle sous toutes ses formes (en pensées, en paroles et en actes) et protège leur pureté jusqu''au jour de leur mariage selon Ta volonté.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_331', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, qu''ils soient transparents envers leurs faiseurs de disciples et envers leurs parents afin d''être aidés en temps de tentation.', 'Seigneur, aide-moi à ce que je soient transparents envers leurs faiseurs de disciples et envers leurs parents afin d''être aidés en temps de tentation.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_332', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, délivre-les de la naïveté émotionnelle, de la convoitise, du mensonge, des commérages et de l''amour de l''argent.', 'Seigneur, protège-moi et libère-moi de la naïveté émotionnelle, de la convoitise, du mensonge, des commérages et de l''amour de l''argent.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_333', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, bénis-les avec le don de contentement, la simplicité de cœur, l''honnêteté, la soumission, l''humilité et la crainte de Dieu en tout temps.', 'Seigneur, bénis-les avec le don de contentement, la simplicité de cœur, l''honnêteté, la soumission, l''humilité et la crainte de Dieu en tout temps.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_334', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, fortifie leur foi afin que, même moqués ou raillés par leurs camarades, ils tiennent ferme et prêchent par leur vie.', 'Seigneur, fortifie leur foi afin que, même moqués ou raillés par leurs camarades, ils tiennent ferme et prêchent par leur vie.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_335', 'CHILD', 'SPIRITUAL_WARFARE',
        'CAT_03', 'SUB_03_03',
        'Enfants à l''âge de la puberté et adolescence', 22, '2 Timothée 2:22 ; Ecclésiaste 11:9-10',
        FALSE, 'Seigneur, accorde aux parents la sagesse pour savoir comment accompagner et conseiller les enfants à l''âge de la puberté avec amour et fermeté.', 'Seigneur, accorde aux parents la sagesse pour savoir comment accompagner et conseiller les enfants à l''âge de la puberté avec amour et fermeté.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_336', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, merci pour l''enfant {PRENOM}, car chaque enfant est un don pour ses parents.', 'Seigneur, merci pour l''enfant [Mon Prénom], car chaque enfant est un don pour ses parents.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_337', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, merci parce que c''est Toi qui as tissé {PRENOM} et écrit dans Ton livre ses jours avant qu''aucun d''eux n''ait existé (Psaume 139:15-16).', 'Seigneur, merci parce que c''est Toi qui as tissé [Mon Prénom] et écrit dans Ton livre ses jours avant qu''aucun d''eux n''ait existé (Psaume 139:15-16).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_338', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, accorde à {PRENOM} de T''aimer de tout son cœur, de toute son âme, de toute sa pensée et de toute sa force, et d''aimer son prochain comme lui-même (Marc 12:30).', 'Seigneur, accorde à [Mon Prénom] de T''aimer de tout son cœur, de toute son âme, de toute sa pensée et de toute sa force, et d''aimer son prochain comme lui-même (Marc 12:30).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_339', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, donne à {PRENOM} d''obéir à ses parents selon le Seigneur et d''honorer son père et sa mère afin d''être heureux et de vivre longtemps sur la terre (Éphésiens 6:1-3).', 'Seigneur, donne à [Mon Prénom] d''obéir à ses parents selon le Seigneur et d''honorer son père et sa mère afin d''être heureux et de vivre longtemps sur la terre (Éphésiens 6:1-3).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_340', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, garde {PRENOM} continuellement sous Ton regard bienveillant et ne le/la conduis pas à la tentation, mais délivre-le/la du mal (Matthieu 6:13).', 'Seigneur, garde [Mon Prénom] continuellement sous Ton regard bienveillant et ne le/la conduis pas à la tentation, mais délivre-le/la du mal (Matthieu 6:13).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_341', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, déracine de la vie de {PRENOM} tout ce que Tu n''as pas planté, et fais germer et prospérer ce que Toi-même Tu as planté en lui/elle (Matthieu 15:13).', 'Seigneur, déracine de la vie de [Mon Prénom] tout ce que Tu n''as pas planté, et fais germer et prospérer ce que Toi-même Tu as planté en lui/elle (Matthieu 15:13).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_342', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, forme Christ en {PRENOM} et accorde-lui d''être enseigné(e) sur la voie qu''il/elle doit suivre (Galates 4:19 ; Proverbes 22:6).', 'Seigneur, forme Christ en [Mon Prénom] et accorde-lui d''être enseigné(e) sur la voie qu''il/elle doit suivre (Galates 4:19 ; Proverbes 22:6).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_343', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, accorde à {PRENOM} de Te connaître dès sa tendre enfance et de Te choisir en temps de crise.', 'Seigneur, accorde à [Mon Prénom] de Te connaître dès sa tendre enfance et de Te choisir en temps de crise.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_344', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, fais que {PRENOM} marche d''une manière digne de Toi, porte du fruit dans le caractère et soit prompt à écouter, lent à parler et lent à la colère (Colossiens 1:10 ; Jacques 1:19).', 'Seigneur, fais que [Mon Prénom] marche d''une manière digne de Toi, porte du fruit dans le caractère et soit prompt à écouter, lent à parler et lent à la colère (Colossiens 1:10 ; Jacques 1:19).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_345', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, fais que {PRENOM} prospère à tous égards et soit en bonne santé comme prospère l''état de son âme (3 Jean 2).', 'Seigneur, fais que [Mon Prénom] prospère à tous égards et soit en bonne santé comme prospère l''état de son âme (3 Jean 2).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_346', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_01',
        'Sujets de prière personnalisés pour l''enfant (Psaume 139)', 24, 'Psaumes 139:15-16 ; Marc 12:30 ; Éphésiens 6:1-3 ; 3 Jean 2',
        TRUE, 'Seigneur, accorde à {PRENOM} de travailler dur à la maison et à l''école, d''aimer méditer Ta Parole, de prier seul et avec les autres, de jeûner, de donner à Dieu, de rendre compte et d''être un témoin de l''évangile au quartier et à l''école.', 'Seigneur, accorde à [Mon Prénom] de travailler dur à la maison et à l''école, d''aimer méditer Ta Parole, de prier seul et avec les autres, de jeûner, de donner à Dieu, de rendre compte et d''être un témoin de l''évangile au quartier et à l''école.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_347', 'MINISTER', 'REQUEST',
        'CAT_10', 'SUB_10_03',
        'L''Être et le Faire du Ministre aux Enfants & Protection individuelle', 24, 'Deutéronome 6:5 ; Jean 15:7-8 ; Matthieu 16:24',
        FALSE, 'Le Faire du Ministre aux Enfants : Pratiquer fidèlement les 13 piliers (RDQAD, Lecture biblique, Littérature chrétienne, Prière seule, Prière avec les autres, Jeûne, Gagnement des âmes, Être disciple, Donner à Dieu, Rendre compte, Membre actif de l''assemblée, Prière familiale, Retraites pour le progrès personnel).', 'Le Faire du Ministre aux Enfants : Pratiquer fidèlement les 13 piliers (RDQAD, Lecture biblique, Littérature chrétienne, Prière seule, Prière avec les autres, Jeûne, Gagnement des âmes, Être disciple, Donner à Dieu, Rendre compte, Membre actif de l''assemblée, Prière familiale, Retraites pour le progrès personnel).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_348', 'MINISTER', 'REQUEST',
        'CAT_10', 'SUB_10_03',
        'L''Être et le Faire du Ministre aux Enfants & Protection individuelle', 24, 'Deutéronome 6:5 ; Jean 15:7-8 ; Matthieu 16:24',
        FALSE, 'L''Être du Ministre aux Enfants : Cultiver les 9 fondements (Amour suprême pour le Seigneur, Amour suprême pour les frères, Séparation d''avec les liens familiaux charnels, Renoncement à soi-même, Renoncement au monde, Porter la croix, Porter du fruit, Demeurer dans la Parole, Séparation d''avec le péché).', 'L''Être du Ministre aux Enfants : Cultiver les 9 fondements (Amour suprême pour le Seigneur, Amour suprême pour les frères, Séparation d''avec les liens familiaux charnels, Renoncement à soi-même, Renoncement au monde, Porter la croix, Porter du fruit, Demeurer dans la Parole, Séparation d''avec le péché).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_349', 'MINISTER', 'REQUEST',
        'CAT_10', 'SUB_10_03',
        'L''Être et le Faire du Ministre aux Enfants & Protection individuelle', 24, 'Deutéronome 6:5 ; Jean 15:7-8 ; Matthieu 16:24',
        FALSE, 'Protection d''un enfant : Seigneur, merci pour la protection accordée depuis le sein maternel jusqu''à ce jour, et protège-le contre toute maladie, tout empoisonnement, toute pratique de sorcellerie, tout accident, toute violence, les mauvaises compagnies et les effets destructeurs des écrans et jeux de hasard.', 'Protection d''un enfant : Seigneur, merci pour la protection accordée depuis le sein maternel jusqu''à ce jour, et protège-le contre toute maladie, tout empoisonnement, toute pratique de sorcellerie, tout accident, toute violence, les mauvaises compagnies et les effets destructeurs des écrans et jeux de hasard.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('YOUNG_WOMEN_18_29', 'WOMEN_30_49', 'SENIORS_50_100')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_350', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        FALSE, 'Seigneur, merci de ce que Tu as toujours pourvu pour la scolarité des enfants, de la maternelle jusqu''à l''université.', 'Seigneur, merci de ce que Tu as toujours pourvu pour la scolarité des enfants, de la maternelle jusqu''à l''université.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_351', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        FALSE, 'Seigneur, conduis-nous dans le choix des établissements scolaires selon Tes plans et desseins, et écarte de leur environnement scolaire toute mauvaise influence.', 'Seigneur, conduis-nous dans le choix des établissements scolaires selon Tes plans et desseins, et écarte de leur environnement scolaire toute mauvaise influence.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_352', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        FALSE, 'Seigneur, protège les fournitures scolaires de chaque enfant tout au long de l''année contre toute perte, vol ou détérioration.', 'Seigneur, protège les fournitures scolaires de chaque enfant tout au long de l''année contre toute perte, vol ou détérioration.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_353', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        FALSE, 'Seigneur, protège-les contre toute brimade, toute intimidation visant à les pousser à renoncer à leur foi, et donne-leur d''être exemplaires par leur discipline et leurs résultats.', 'Seigneur, protège-moi contre toute brimade, toute intimidation visant à les pousser à renoncer à leur foi, et donne-leur d''être exemplaires par leur discipline et leurs résultats.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_354', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        FALSE, 'Seigneur, nous cachons la vie de chaque enfant et sa santé sous le sang de Jésus-Christ tout le long de cette année scolaire.', 'Seigneur, nous cachons la vie de chaque enfant et sa santé sous le sang de Jésus-Christ tout le long de cette année scolaire.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_355', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        TRUE, 'Seigneur, délivre {PRENOM} de toute familiarité avec Ta Parole et donne-lui de recevoir de fraîches révélations pendant qu''il/elle écoute l''enseignement.', 'Seigneur, délivre [Mon Prénom] de toute familiarité avec Ta Parole et donne-lui de recevoir de fraîches révélations pendant qu''il/elle écoute l''enseignement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_356', 'PARENT', 'REQUEST',
        'CAT_07', 'SUB_07_04',
        'Vie académique des EMI & Impact du ministère sur les enfants', 26, 'Ésaïe 54:13',
        TRUE, 'Seigneur, révèle-Toi à {PRENOM} comme Seigneur, Sauveur personnel et Sanctificateur, et transforme-le/la en un vaillant soldat pour Christ.', 'Seigneur, révèle-Toi à [Mon Prénom] comme Seigneur, Sauveur personnel et Sanctificateur, et transforme-le/la en un vaillant soldat pour Christ.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_357', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Seigneur, merci pour le Ministère aux Enfants qui commence à 90% dans le foyer grâce aux parents qui sont les ministres n°1 pour leurs enfants.', 'Seigneur, merci pour le Ministère aux Enfants qui commence à 90% dans le foyer grâce aux parents qui sont les ministres n°1 pour leurs enfants.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_358', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que nous les parents établissions les dévotions familiales comme une école de base tôt le matin et mettions du temps à part pour chaque enfant individuellement.', 'Que nous les parents établissions les dévotions familiales comme une école de base tôt le matin et mettions du temps à part pour chaque enfant individuellement.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_359', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que nous apprenions à nos enfants à travailler de leurs mains plutôt que de s''endetter ou de rechercher des gains faciles (Proverbes 6:1-11).', 'Que nous apprenions à nos enfants à travailler de leurs mains plutôt que de s''endetter ou de rechercher des gains faciles (Proverbes 6:1-11).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_360', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que nous enseignions nos enfants à accepter la discipline du Seigneur sans se plaindre (Proverbes 3:11-12) et à accepter un « NON » de Dieu ou de l''homme.', 'Que nous enseignions nos enfants à accepter la discipline du Seigneur sans se plaindre (Proverbes 3:11-12) et à accepter un « NON » de Dieu ou de l''homme.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_361', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que nos enfants soient des Esther, des Salomon, des Abel et des Isaac dans leur obéissance, leur loyauté et leur amour des choses de Dieu.', 'Que nos enfants soient des Esther, des Salomon, des Abel et des Isaac dans leur obéissance, leur loyauté et leur amour des choses de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_362', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que mes enfants gardent leur cœur plus que toute autre chose, car de lui viennent les sources de la vie (Proverbes 4:23).', 'Que mes enfants gardent leur cœur plus que toute autre chose, car de lui viennent les sources de la vie (Proverbes 4:23).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_363', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que mes enfants soient intègres dans les affaires financières, aiment la vérité et la pureté de cœur et de corps.', 'Que mes enfants soient intègres dans les affaires financières, aiment la vérité et la pureté de cœur et de corps.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_364', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que mes enfants soient fiers de leur appartenance à Christ, satisfaits de ce que leurs parents leur donnent, et qu''ils ne brûlent jamais du désir d''être riches.', 'Que mes enfants soient fiers de leur appartenance à Christ, satisfaits de ce que leurs parents leur donnent, et qu''ils ne brûlent jamais du désir d''être riches.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_365', 'PARENT', 'REQUEST',
        'CAT_06', 'SUB_06_02',
        'Proverbes 1 à 9 : Une école d''enfants & Proclamation sur les agneaux', 27, 'Proverbes 1:8-16 ; Proverbes 3:11-12 ; Proverbes 4:23 ; Proverbes 6:1-11',
        FALSE, 'Que mes enfants soient sages, gagnent des âmes et deviennent des instruments pour l''accomplissement des desseins éternels de Dieu.', 'Que mes enfants soient sages, gagnent des âmes et deviennent des instruments pour l''accomplissement des desseins éternels de Dieu.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_366', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, accorde à {PRENOM} d''aimer le Seigneur de tout son cœur, de toute son âme et de toute sa force, et d''expulser tout rival de son cœur.', 'Seigneur, accorde à [Mon Prénom] d''aimer le Seigneur de tout son cœur, de toute son âme et de toute sa force, et d''expulser tout rival de son cœur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_367', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, accorde à {PRENOM} d''aimer Tes commandements et de les observer par amour, même lorsque cela lui coûte.', 'Seigneur, accorde à [Mon Prénom] d''aimer Tes commandements et de les observer par amour, même lorsque cela lui coûte.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_368', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        FALSE, 'Seigneur, qu''il/elle s''exerce à obéir dans les petites choses afin de pouvoir aussi T''obéir dans les grandes choses.', 'Seigneur, qu''il/elle s''exerce à obéir dans les petites choses afin de pouvoir aussi T''obéir dans les grandes choses.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_369', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, accorde à {PRENOM} d''aimer tous les frères en Christ, de pardonner de tout son cœur à ceux qui l''ont offensé, et de rejeter la calomnie, les commérages, l''amertume et les plaintes.', 'Seigneur, accorde à [Mon Prénom] d''aimer tous les frères en Christ, de pardonner de tout son cœur à ceux qui l''ont offensé, et de rejeter la calomnie, les commérages, l''amertume et les plaintes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_370', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, délivre {PRENOM} de la justification de soi, de l''amour-propre et du désir d''être vu ou acclamé ; donne-lui d''accepter les critiques et corrections avec joie et reconnaissance.', 'Seigneur, délivre [Mon Prénom] de la justification de soi, de l''amour-propre et du désir d''être vu ou acclamé ; donne-lui d''accepter les critiques et corrections avec joie et reconnaissance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_371', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, accorde à {PRENOM} de se réjouir avec celui qui est promu, de demander pardon et de supplier pour servir.', 'Seigneur, accorde à [Mon Prénom] de se réjouir avec celui qui est promu, de demander pardon et de supplier pour servir.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_372', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, donne à {PRENOM} de connaître le contentement en Christ et de dépendre de Toi pour voir ses besoins satisfaits.', 'Seigneur, donne à [Mon Prénom] de connaître le contentement en Christ et de dépendre de Toi pour voir ses besoins satisfaits.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_373', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, donne à {PRENOM} d''aimer lire, étudier, mémoriser et obéir à Ta Parole chaque jour davantage.', 'Seigneur, donne à [Mon Prénom] d''aimer lire, étudier, mémoriser et obéir à Ta Parole chaque jour davantage.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_374', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, transforme le cœur de {PRENOM} afin qu''il/elle soit capable d''aimer ses ennemis, de bénir ceux qui le/la maudissent et de prier pour ceux qui le/la maltraitent (Matthieu 5:44).', 'Seigneur, transforme le cœur de [Mon Prénom] afin qu''il/elle soit capable d''aimer ses ennemis, de bénir ceux qui le/la maudissent et de prier pour ceux qui le/la maltraitent (Matthieu 5:44).'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_375', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, donne à {PRENOM} d''être toujours joyeux(se), en paix avec tous les hommes, doux(ce) et tendre sans être lâche, prompt(e) à écouter et lent(e) à se mettre en colère.', 'Seigneur, donne à [Mon Prénom] d''être toujours joyeux(se), en paix avec tous les hommes, doux(ce) et tendre sans être lâche, prompt(e) à écouter et lent(e) à se mettre en colère.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_376', 'CHILD', 'REQUEST',
        'CAT_05', 'SUB_05_02',
        'Devenir et demeurer un disciple-amoureux du Seigneur Jésus', 30, 'Luc 14:26-33 ; Matthieu 5:44 ; Jean 17:3',
        TRUE, 'Seigneur, accorde à {PRENOM} de se soumettre à ses parents et de les honorer partout où il/elle se trouve, et qu''en lui/elle rayonne la joie d''appartenir au Seigneur.', 'Seigneur, accorde à [Mon Prénom] de se soumettre à ses parents et de les honorer partout où il/elle se trouve, et qu''en lui/elle rayonne la joie d''appartenir au Seigneur.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_377', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        FALSE, 'Seigneur, crée la faim et la soif pour la Parole de Dieu dans le cœur de mes enfants afin que rien d''autre ne puisse combler ce vide que seule Ta Parole peut combler.', 'Seigneur, crée la faim et la soif pour la Parole de Dieu dans le cœur de mes enfants afin que rien d''autre ne puisse combler ce vide que seule Ta Parole peut combler.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_378', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        FALSE, 'Seigneur, amène chacun de mes enfants à mémoriser des portions de Ta Parole et fais que la Bible devienne leur livre de poche.', 'Seigneur, amène chacun de mes enfants à mémoriser des portions de Ta Parole et fais que la Bible devienne leur livre de poche.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_379', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        FALSE, 'Seigneur, crée la crainte de Dieu dans le cœur de chacun de mes enfants afin qu''ils fuient le mal et pratiquent le bien par crainte de Dieu et non par crainte du regard des hommes.', 'Seigneur, crée la crainte de Dieu dans le cœur de chacun de mes enfants afin qu''ils fuient le mal et pratiquent le bien par crainte de Dieu et non par crainte du regard des hommes.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_380', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        FALSE, 'Seigneur, oins-le de courage pour faire victorieusement face aux assauts de l''ennemi.', 'Seigneur, oins-le de courage pour faire victorieusement face aux assauts de l''ennemi.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_381', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        TRUE, 'Seigneur, ouvre l''esprit de {PRENOM} pour comprendre l''évangile qui lui sera prêché et accorde-lui le don de la vraie repentance.', 'Seigneur, ouvre l''esprit de [Mon Prénom] pour comprendre l''évangile qui lui sera prêché et accorde-lui le don de la vraie repentance.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_382', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        TRUE, 'Seigneur, sauve {PRENOM}, donne-lui l''assurance du salut, le baptême dans l''eau et dans le Saint-Esprit, et bénis-le/la avec un vrai faiseur de disciple.', 'Seigneur, sauve [Mon Prénom], donne-lui l''assurance du salut, le baptême dans l''eau et dans le Saint-Esprit, et bénis-le/la avec un vrai faiseur de disciple.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;
WITH ins AS (
    INSERT INTO prayer_topics (
        code, group_code, prayer_type, category_code, subcategory_code,
        section_source, source_page, bible_reference, has_name_placeholder,
        content_original, content_kid_friendly
    ) VALUES (
        'PRY_383', 'CHILD', 'REQUEST',
        'CAT_01', 'SUB_01_04',
        'La faim de la Parole, la crainte de Dieu & le salut d''un enfant', 33, 'Jean 17:3 ; Jean 10:27 ; Proverbes 1:7',
        TRUE, 'Seigneur, que {PRENOM} ne rétrograde jamais, grandisse dans la foi, serve Dieu en Son temps marqué et fasse partie du milliard de disciples en 2065.', 'Seigneur, que [Mon Prénom] ne rétrograde jamais, grandisse dans la foi, serve Dieu en Son temps marqué et fasse partie du milliard de disciples en 2065.'
    )
    ON CONFLICT (code) DO UPDATE SET content_original = EXCLUDED.content_original
    RETURNING id
)
INSERT INTO prayer_topic_age_groups (topic_id, age_group_id)
SELECT ins.id, ag.id FROM ins CROSS JOIN age_groups ag
WHERE ag.code IN ('GIRLS_8_13', 'TEENS_14_17', 'YOUNG_WOMEN_18_29', 'WOMEN_30_49')
ON CONFLICT DO NOTHING;

COMMIT;