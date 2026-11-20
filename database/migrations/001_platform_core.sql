-- ============================================================================
-- ECOSYSTEME CHRETIEN / FILLES DE PROMESSE — SOCLE CENTRAL V1
-- Supabase PostgreSQL. MIGRATION ADDITIVE : ne modifie aucune table V7.x.
-- Ne pas executer en production avant revue humaine, backup et tests RLS.
-- Authentification deleguee a Supabase Auth (auth.users).
-- Aucun secret/service_role ne doit etre place dans le client.
-- ============================================================================

begin;
create extension if not exists pgcrypto;

-- Profils minimaux : ne pas collecter date de naissance/adresse par defaut.
create table if not exists public.platform_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  country_code char(2) not null default 'CI',
  preferred_language text not null default 'fr',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_roles (
  code text primary key check (code in ('PARTICIPANT','CHURCH_CONTRIBUTOR','MODERATOR','PLATFORM_ADMIN')),
  label text not null
);
insert into public.platform_roles(code,label) values
 ('PARTICIPANT','Participante'),
 ('CHURCH_CONTRIBUTOR','Contributrice d’église'),
 ('MODERATOR','Modératrice'),
 ('PLATFORM_ADMIN','Administratrice centrale')
on conflict (code) do nothing;

create table if not exists public.platform_user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role_code text not null references public.platform_roles(code) on delete restrict,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key(user_id, role_code)
);

create table if not exists public.churches (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  denomination text,
  city text,
  country_code char(2) not null default 'CI',
  status text not null default 'PENDING' check (status in ('PENDING','ACTIVE','SUSPENDED','ARCHIVED')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.church_memberships (
  church_id uuid not null references public.churches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  membership_role text not null check (membership_role in ('CONTRIBUTOR','CHURCH_ADMIN')),
  status text not null default 'PENDING' check (status in ('PENDING','ACTIVE','SUSPENDED')),
  created_at timestamptz not null default now(),
  primary key(church_id,user_id)
);

-- Le contenu est partage par plateforme. Une contribution d'eglise n'est
-- visible au public qu'apres validation centrale (status=PUBLISHED).
create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  stable_key text unique,
  space_code text not null check (space_code in ('P1','P2','P3','P4','P5')),
  content_type text not null,
  audience_scope text not null default 'ALL' check (audience_scope in ('ALL','FILLE_PROMESSE','FAMILY','YOUTH','ADULTS')),
  age_group_code text, -- reference versionnee a definir; pas de tranche inventee ici
  source_church_id uuid references public.churches(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  status text not null default 'DRAFT' check (status in ('DRAFT','SUBMITTED','IN_REVIEW','CHANGES_REQUESTED','APPROVED','PUBLISHED','REJECTED','ARCHIVED')),
  current_version integer not null default 1 check (current_version > 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_content_public on public.content_items(space_code,status,published_at desc);
create index if not exists idx_content_church on public.content_items(source_church_id,status,updated_at desc);

create table if not exists public.content_versions (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.content_items(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  title text not null check (char_length(title) between 1 and 220),
  summary text,
  body jsonb not null default '{}'::jsonb,
  bible_references text[] not null default '{}',
  editorial_source text,
  rights_status text not null default 'UNVERIFIED' check (rights_status in ('UNVERIFIED','ORIGINAL','LICENSED','PUBLIC_DOMAIN','PERMISSION_GRANTED')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique(content_id,version_number)
);

create table if not exists public.content_reviews (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.content_items(id) on delete cascade,
  version_number integer not null,
  reviewer_id uuid not null references auth.users(id) on delete restrict,
  decision text not null check (decision in ('APPROVED','CHANGES_REQUESTED','REJECTED','PUBLISHED')),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  content_id uuid references public.content_items(id) on delete set null,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason_code text not null check (reason_code in ('SAFETY','COPYRIGHT','THEOLOGY','PRIVACY','ERROR','OTHER')),
  details text,
  status text not null default 'OPEN' check (status in ('OPEN','IN_REVIEW','RESOLVED','DISMISSED')),
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Helpers SECURITY DEFINER pour eviter les recursions RLS sur les tables de roles.
create or replace function public.has_platform_role(p_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.platform_user_roles r
    where r.user_id = (select auth.uid()) and r.role_code = p_role
  );
$$;

create or replace function public.is_church_member(p_church uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.church_memberships m
    where m.church_id = p_church and m.user_id = (select auth.uid())
      and m.status = 'ACTIVE'
  );
$$;

create or replace function public.can_edit_church_content(p_church uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.church_memberships m
    where m.church_id = p_church and m.user_id = (select auth.uid())
      and m.status = 'ACTIVE' and m.membership_role in ('CONTRIBUTOR','CHURCH_ADMIN')
  );
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end;
$$;

-- RLS : activee partout, aucune policy anon. Les grants ne remplacent pas RLS.
alter table public.platform_profiles enable row level security;
alter table public.platform_roles enable row level security;
alter table public.platform_user_roles enable row level security;
alter table public.churches enable row level security;
alter table public.church_memberships enable row level security;
alter table public.content_items enable row level security;
alter table public.content_versions enable row level security;
alter table public.content_reviews enable row level security;
alter table public.content_reports enable row level security;
alter table public.platform_audit_log enable row level security;

-- Profils : uniquement son propre profil. Pas de lecture administrative globale.
create policy profile_select_self on public.platform_profiles for select to authenticated using (user_id=(select auth.uid()));
create policy profile_insert_self on public.platform_profiles for insert to authenticated with check (user_id=(select auth.uid()));
create policy profile_update_self on public.platform_profiles for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

create policy roles_read_authenticated on public.platform_roles for select to authenticated using (true);
create policy user_roles_read_self_or_admin on public.platform_user_roles for select to authenticated
 using (user_id=(select auth.uid()) or public.has_platform_role('PLATFORM_ADMIN'));
create policy user_roles_admin_manage on public.platform_user_roles for all to authenticated
 using (public.has_platform_role('PLATFORM_ADMIN')) with check (public.has_platform_role('PLATFORM_ADMIN'));

create policy churches_read_active_or_member on public.churches for select to authenticated
 using (status='ACTIVE' or created_by=(select auth.uid()) or public.is_church_member(id) or public.has_platform_role('PLATFORM_ADMIN'));
create policy churches_create_authenticated on public.churches for insert to authenticated
 with check (created_by=(select auth.uid()) and status='PENDING');
create policy churches_admin_update on public.churches for update to authenticated
 using (public.has_platform_role('PLATFORM_ADMIN')) with check (public.has_platform_role('PLATFORM_ADMIN'));
create policy church_members_read_self_or_admin on public.church_memberships for select to authenticated
 using (user_id=(select auth.uid()) or public.has_platform_role('PLATFORM_ADMIN'));
create policy church_members_admin_manage on public.church_memberships for all to authenticated
 using (public.has_platform_role('PLATFORM_ADMIN')) with check (public.has_platform_role('PLATFORM_ADMIN'));

-- Items : tout utilisateur authentifie lit les contenus publies. Un auteur ou
-- membre actif peut lire ses brouillons. Seuls contributeurs peuvent creer
-- dans leur eglise ; les statuts de publication restent sous moderation centrale.
create policy content_read_published_or_owned on public.content_items for select to authenticated
 using (status='PUBLISHED' or created_by=(select auth.uid()) or
        (source_church_id is not null and public.can_edit_church_content(source_church_id)) or
        public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'));
create policy content_insert_personal_draft on public.content_items for insert to authenticated
 with check (created_by=(select auth.uid()) and status='DRAFT' and source_church_id is null);
create policy content_insert_church_draft on public.content_items for insert to authenticated
 with check (created_by=(select auth.uid()) and status='DRAFT' and source_church_id is not null and public.can_edit_church_content(source_church_id));
create policy content_update_author_draft on public.content_items for update to authenticated
 using (created_by=(select auth.uid()) and status in ('DRAFT','CHANGES_REQUESTED'))
 with check (created_by=(select auth.uid()) and status in ('DRAFT','SUBMITTED','CHANGES_REQUESTED') and
   (source_church_id is null or public.can_edit_church_content(source_church_id)));
create policy content_moderator_update on public.content_items for update to authenticated
 using (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'))
 with check (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'));

create policy versions_read_if_parent_readable on public.content_versions for select to authenticated
 using (exists(select 1 from public.content_items c where c.id=content_id and
       (c.status='PUBLISHED' or c.created_by=(select auth.uid()) or
        (c.source_church_id is not null and public.can_edit_church_content(c.source_church_id)) or
        public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'))));
create policy versions_insert_author_or_editor on public.content_versions for insert to authenticated
 with check (created_by=(select auth.uid()) and exists(
   select 1 from public.content_items c where c.id=content_id and
   (c.created_by=(select auth.uid()) or (c.source_church_id is not null and public.can_edit_church_content(c.source_church_id)))
 ));

create policy reviews_read_moderators on public.content_reviews for select to authenticated
 using (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'));
create policy reviews_insert_moderators on public.content_reviews for insert to authenticated
 with check (reviewer_id=(select auth.uid()) and
   (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN')));

create policy reports_insert_self on public.content_reports for insert to authenticated
 with check (reporter_id=(select auth.uid()) and status='OPEN');
create policy reports_read_reporter_or_moderator on public.content_reports for select to authenticated
 using (reporter_id=(select auth.uid()) or public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'));
create policy reports_update_moderators on public.content_reports for update to authenticated
 using (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'))
 with check (public.has_platform_role('MODERATOR') or public.has_platform_role('PLATFORM_ADMIN'));

create policy audit_admin_read on public.platform_audit_log for select to authenticated
 using (public.has_platform_role('PLATFORM_ADMIN'));

-- Pas de droits pour anon ; acces authentifie strictement limite aux operations RLS.
revoke all on public.platform_profiles, public.platform_roles, public.platform_user_roles,
 public.churches, public.church_memberships, public.content_items, public.content_versions,
 public.content_reviews, public.content_reports, public.platform_audit_log from anon;
grant select,insert,update on public.platform_profiles to authenticated;
grant select on public.platform_roles to authenticated;
grant select,insert,update,delete on public.platform_user_roles to authenticated;
grant select,insert,update on public.churches to authenticated;
grant select,insert,update,delete on public.church_memberships to authenticated;
grant select,insert,update on public.content_items to authenticated;
grant select,insert on public.content_versions to authenticated;
grant select,insert on public.content_reviews to authenticated;
grant select,insert,update on public.content_reports to authenticated;
grant select on public.platform_audit_log to authenticated;

-- Les fonctions helper ne sont executables que par les utilisateurs connectes.
revoke all on function public.has_platform_role(text) from public, anon;
revoke all on function public.is_church_member(uuid) from public, anon;
revoke all on function public.can_edit_church_content(uuid) from public, anon;
grant execute on function public.has_platform_role(text) to authenticated;
grant execute on function public.is_church_member(uuid) to authenticated;
grant execute on function public.can_edit_church_content(uuid) to authenticated;

-- updated_at
 drop trigger if exists trg_platform_profiles_updated on public.platform_profiles;
 create trigger trg_platform_profiles_updated before update on public.platform_profiles for each row execute function public.touch_updated_at();
 drop trigger if exists trg_churches_updated on public.churches;
 create trigger trg_churches_updated before update on public.churches for each row execute function public.touch_updated_at();
 drop trigger if exists trg_content_items_updated on public.content_items;
 create trigger trg_content_items_updated before update on public.content_items for each row execute function public.touch_updated_at();
 drop trigger if exists trg_content_reports_updated on public.content_reports;
 create trigger trg_content_reports_updated before update on public.content_reports for each row execute function public.touch_updated_at();

commit;

-- LIMITES CONNUES A TRAITER AVANT PROD :
-- 1) Les roles PLATFORM_ADMIN/MODERATOR doivent etre attribues via canal admin fiable.
-- 2) Verifier les changements de status par transition (trigger serveur dedie).
-- 3) Ajouter tests RLS avec plusieurs comptes et roles dans un projet Supabase jetable.
-- 4) Definir la taxonomie d'age et les consentements avec validation juridique CI.
-- 5) Ne pas stocker notes de priere sensibles dans content_items/content_versions.
-- 6) Le journal d'audit doit etre alimente par triggers serveur, pas par le navigateur.
