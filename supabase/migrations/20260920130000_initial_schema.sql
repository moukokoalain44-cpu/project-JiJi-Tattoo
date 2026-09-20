-- Jiji Tattoo — database foundation
-- Supabase/PostgreSQL migration. Public quote tokens must be generated and
-- hashed by the API; this schema deliberately never stores the raw token.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.app_role as enum ('client', 'artist', 'admin');
create type public.service_kind as enum ('tattoo', 'piercing', 'skincare');
create type public.appointment_status as enum ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
create type public.quote_request_status as enum ('draft', 'submitted', 'in_review', 'quoted', 'accepted', 'declined', 'expired', 'cancelled');
create type public.quote_status as enum ('draft', 'sent', 'accepted', 'declined', 'expired', 'cancelled');
create type public.availability_status as enum ('available', 'held', 'booked', 'blocked');

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  service_kind public.service_kind not null,
  display_order integer not null default 0 check (display_order >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  service_kind public.service_kind not null,
  duration_minutes integer not null check (duration_minutes between 15 and 1440),
  price_from numeric(10, 2) check (price_from is null or price_from >= 0),
  price_to numeric(10, 2) check (price_to is null or price_to >= price_from),
  display_order integer not null default 0 check (display_order >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'client',
  display_name text,
  avatar_path text,
  bio text,
  instagram_handle text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.gallery_images (
  id uuid primary key default gen_random_uuid(),
  uploaded_by uuid references public.profiles(id) on delete set null,
  artist_id uuid references public.profiles(id) on delete set null,
  service_kind public.service_kind not null,
  category_id uuid references public.categories(id) on delete set null,
  title text,
  alt_text text,
  storage_path text not null unique,
  thumbnail_path text,
  is_published boolean not null default false,
  display_order integer not null default 0 check (display_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete set null,
  full_name text not null,
  email text not null,
  phone text,
  notes text,
  marketing_consent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clients_email_format check (email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')
);

create table public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references public.profiles(id) on delete cascade,
  service_kind public.service_kind not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.availability_status not null default 'available',
  hold_expires_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint availability_valid_range check (ends_at > starts_at),
  constraint availability_hold_expiry check (status <> 'held' or hold_expires_at is not null)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete restrict,
  artist_id uuid references public.profiles(id) on delete set null,
  service_id uuid not null references public.services(id) on delete restrict,
  availability_slot_id uuid references public.availability_slots(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'pending',
  client_notes text,
  internal_notes text,
  consent_to_publish_photos boolean not null default false,
  consent_to_publish_granted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointment_valid_range check (ends_at > starts_at),
  constraint appointment_consent_timestamp check (
    consent_to_publish_photos = false or consent_to_publish_granted_at is not null
  )
);

-- Pending/confirmed appointments cannot overlap for the same artist. The
-- range is half-open so adjacent appointments remain valid.
alter table public.appointments
  add constraint appointments_no_double_booking
  exclude using gist (
    artist_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  )
  where (artist_id is not null and status in ('pending', 'confirmed'));

create table public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  assigned_artist_id uuid references public.profiles(id) on delete set null,
  service_kind public.service_kind not null default 'tattoo',
  status public.quote_request_status not null default 'draft',
  title text,
  description text not null,
  placement text,
  size_description text,
  style text,
  public_token_hash bytea unique,
  token_expires_at timestamptz,
  consent_to_publish_photos boolean not null default false,
  consent_to_publish_granted_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quote_token_expiry check (
    public_token_hash is null or token_expires_at is not null
  ),
  constraint quote_consent_timestamp check (
    consent_to_publish_photos = false or consent_to_publish_granted_at is not null
  )
);

create table public.quote_request_attachments (
  id uuid primary key default gen_random_uuid(),
  quote_request_id uuid not null references public.quote_requests(id) on delete cascade,
  uploaded_by uuid references auth.users(id) on delete set null,
  storage_path text not null unique,
  original_filename text not null,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  file_size_bytes bigint not null check (file_size_bytes > 0 and file_size_bytes <= 10485760),
  created_at timestamptz not null default now()
);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  quote_request_id uuid not null references public.quote_requests(id) on delete restrict,
  issued_by uuid references public.profiles(id) on delete set null,
  status public.quote_status not null default 'draft',
  subtotal numeric(10, 2) not null default 0 check (subtotal >= 0),
  deposit_amount numeric(10, 2) not null default 0 check (deposit_amount >= 0),
  valid_until date,
  notes text,
  sent_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.quote_items (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  description text not null,
  quantity numeric(10, 2) not null default 1 check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  total_price numeric(10, 2) generated always as (round(quantity * unit_price, 2)) stored,
  created_at timestamptz not null default now()
);

create index services_category_idx on public.services(category_id);
create index services_kind_active_idx on public.services(service_kind, is_active);
create index gallery_published_order_idx on public.gallery_images(is_published, display_order);
create index gallery_artist_idx on public.gallery_images(artist_id);
create index clients_email_idx on public.clients(lower(email));
create index availability_lookup_idx on public.availability_slots(service_kind, starts_at, status);
create index appointments_client_idx on public.appointments(client_id, starts_at desc);
create index appointments_status_start_idx on public.appointments(status, starts_at);
create index quote_requests_client_idx on public.quote_requests(client_id, created_at desc);
create index quote_requests_status_idx on public.quote_requests(status, created_at desc);
create index quote_attachments_request_idx on public.quote_request_attachments(quote_request_id);
create index quotes_request_idx on public.quotes(quote_request_id, created_at desc);
create index quote_items_quote_idx on public.quote_items(quote_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'categories', 'services', 'profiles', 'gallery_images', 'clients',
    'availability_slots', 'appointments', 'quote_requests', 'quotes'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
      table_name || '_set_updated_at', table_name
    );
  end loop;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and is_active = true
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.categories enable row level security;
alter table public.services enable row level security;
alter table public.profiles enable row level security;
alter table public.gallery_images enable row level security;
alter table public.clients enable row level security;
alter table public.availability_slots enable row level security;
alter table public.appointments enable row level security;
alter table public.quote_requests enable row level security;
alter table public.quote_request_attachments enable row level security;
alter table public.quotes enable row level security;
alter table public.quote_items enable row level security;

create policy "Published categories are public"
  on public.categories for select using (is_active = true);
create policy "Admins manage categories"
  on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Active services are public"
  on public.services for select using (is_active = true);
create policy "Admins manage services"
  on public.services for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Users read their own profile"
  on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "Users update their own profile"
  on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "Admins manage profiles"
  on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Published gallery is public"
  on public.gallery_images for select using (is_published = true);
create policy "Admins manage gallery"
  on public.gallery_images for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their own record"
  on public.clients for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "Clients create their own record"
  on public.clients for insert to authenticated with check (user_id = auth.uid());
create policy "Clients update their own record"
  on public.clients for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Admins manage clients"
  on public.clients for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Authenticated users read availability"
  on public.availability_slots for select to authenticated using (true);
create policy "Admins manage availability"
  on public.availability_slots for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their appointments"
  on public.appointments for select to authenticated
  using (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()) or public.is_admin());
create policy "Clients create their appointments"
  on public.appointments for insert to authenticated
  with check (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()));
create policy "Clients cancel their appointments"
  on public.appointments for update to authenticated
  using (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()))
  with check (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()));
create policy "Admins manage appointments"
  on public.appointments for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their quote requests"
  on public.quote_requests for select to authenticated
  using (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()) or public.is_admin());
create policy "Clients create quote requests"
  on public.quote_requests for insert to authenticated
  with check (client_id is null or exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()));
create policy "Clients update draft quote requests"
  on public.quote_requests for update to authenticated
  using (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()) and status = 'draft')
  with check (exists (select 1 from public.clients c where c.id = client_id and c.user_id = auth.uid()));
create policy "Admins manage quote requests"
  on public.quote_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their quote attachments"
  on public.quote_request_attachments for select to authenticated
  using (exists (
    select 1 from public.quote_requests qr
    join public.clients c on c.id = qr.client_id
    where qr.id = quote_request_id and c.user_id = auth.uid()
  ) or public.is_admin());
create policy "Clients add their quote attachments"
  on public.quote_request_attachments for insert to authenticated
  with check (uploaded_by = auth.uid() and exists (
    select 1 from public.quote_requests qr
    join public.clients c on c.id = qr.client_id
    where qr.id = quote_request_id and c.user_id = auth.uid()
  ));
create policy "Admins manage quote attachments"
  on public.quote_request_attachments for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their quotes"
  on public.quotes for select to authenticated
  using (exists (
    select 1 from public.quote_requests qr
    join public.clients c on c.id = qr.client_id
    where qr.id = quote_request_id and c.user_id = auth.uid()
  ) or public.is_admin());
create policy "Admins manage quotes"
  on public.quotes for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Clients read their quote items"
  on public.quote_items for select to authenticated
  using (exists (
    select 1 from public.quotes q
    join public.quote_requests qr on qr.id = q.quote_request_id
    join public.clients c on c.id = qr.client_id
    where q.id = quote_id and c.user_id = auth.uid()
  ) or public.is_admin());
create policy "Admins manage quote items"
  on public.quote_items for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Private bucket for quote references and unpublished gallery assets.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'jiji-private',
  'jiji-private',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Authenticated users read permitted private files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'jiji-private'
    and (
      public.is_admin()
      or exists (
        select 1
        from public.quote_request_attachments a
        join public.quote_requests qr on qr.id = a.quote_request_id
        join public.clients c on c.id = qr.client_id
        where a.storage_path = name and c.user_id = auth.uid()
      )
    )
  );

create policy "Clients upload quote reference files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'jiji-private'
    and owner_id = (select auth.uid()::text)
    and (name like 'quote-requests/%')
  );

create policy "Admins manage private files"
  on storage.objects for all to authenticated
  using (bucket_id = 'jiji-private' and public.is_admin())
  with check (bucket_id = 'jiji-private' and public.is_admin());
