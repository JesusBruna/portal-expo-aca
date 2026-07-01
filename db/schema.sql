-- ============================================================
--  PORTAL EXPO ACA — Esquema de base de datos (PostgreSQL / Supabase)
--  Ejecutar en Supabase → SQL Editor → New query → pegar y Run.
-- ============================================================

-- Extensiones
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- ROLES DE USUARIO
--   admin     -> el dueño / ACA: control total
--   dealer    -> concesionario / ExpoACA: gestiona SU contenido
--   customer  -> socio / cliente
-- ------------------------------------------------------------
create type user_role as enum ('admin', 'dealer', 'customer');
create type order_status as enum ('pagado', 'a_preparar', 'enviado', 'entregado', 'cancelado');

-- ------------------------------------------------------------
-- PERFIL DE USUARIO (extiende auth.users de Supabase)
-- ------------------------------------------------------------
create table app_users (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  email        text,
  role         user_role not null default 'customer',
  is_socio     boolean not null default false,   -- socio ACA (precio preferencial)
  dealer_id    uuid,                              -- si role='dealer', a qué expo pertenece
  created_at   timestamptz not null default now()
);

-- ------------------------------------------------------------
-- EXPOS / CONCESIONARIOS
-- ------------------------------------------------------------
create table dealers (
  id           uuid primary key default uuid_generate_v4(),
  razon        text not null,               -- nombre comercial (se ve en todo el portal)
  sede         text,                         -- "ExpoACA Palermo"
  rubro        text,
  cuit         text,
  tel          text,                         -- teléfono / WhatsApp de compras
  email        text,
  dir          text,                         -- dirección (posiciona el mapa)
  horario      text,
  map_link     text,                         -- pin de Google Maps
  descripcion  text,
  tone         text default '#C8102E',
  initial      text,
  rating       numeric(2,1) default 4.7,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);
alter table app_users add constraint app_users_dealer_fk
  foreign key (dealer_id) references dealers(id) on delete set null;

-- ------------------------------------------------------------
-- CATEGORÍAS
-- ------------------------------------------------------------
create table categories (
  id     uuid primary key default uuid_generate_v4(),
  name   text not null unique,
  slug   text not null unique,
  tone   text default '#C8102E'
);
-- Categorías: lectura pública (datos de referencia), escritura solo admin
alter table categories enable row level security;
create policy categories_read  on categories for select using (true);
create policy categories_admin on categories for all using (
  exists (select 1 from app_users where id = auth.uid() and role = 'admin')
) with check (
  exists (select 1 from app_users where id = auth.uid() and role = 'admin')
);

-- ------------------------------------------------------------
-- PRODUCTOS
-- ------------------------------------------------------------
create table products (
  id           uuid primary key default uuid_generate_v4(),
  dealer_id    uuid not null references dealers(id) on delete cascade,
  name         text not null,
  brand        text,
  category_id  uuid references categories(id),
  description  text,
  price_list   integer not null default 0,   -- precio público (ARS)
  price_socio  integer not null default 0,   -- precio socio ACA (ARS)
  stock        integer not null default 0,
  paused       boolean not null default false, -- oculto del marketplace
  is_deal      boolean not null default false, -- oferta del día
  created_at   timestamptz not null default now()
);
create index on products (dealer_id);
create index on products (category_id);

-- Fotos del producto
create table product_photos (
  id          uuid primary key default uuid_generate_v4(),
  product_id  uuid not null references products(id) on delete cascade,
  url         text not null,
  position    integer not null default 0
);

-- ------------------------------------------------------------
-- PEDIDOS  (la compra final se coordina por WhatsApp, pero se registra acá)
-- ------------------------------------------------------------
create table orders (
  id            uuid primary key default uuid_generate_v4(),
  dealer_id     uuid not null references dealers(id) on delete cascade,
  customer_id   uuid references app_users(id) on delete set null,
  customer_name text,
  is_socio      boolean default false,
  status        order_status not null default 'pagado',
  total         integer not null default 0,
  created_at    timestamptz not null default now()
);
create index on orders (dealer_id);

create table order_items (
  id          uuid primary key default uuid_generate_v4(),
  order_id    uuid not null references orders(id) on delete cascade,
  product_id  uuid references products(id) on delete set null,
  qty         integer not null default 1,
  unit_price  integer not null default 0
);

-- ============================================================
--  SEGURIDAD (Row Level Security)
--  admin = control total | dealer = solo lo suyo | público = lectura
-- ============================================================
alter table dealers        enable row level security;
alter table products       enable row level security;
alter table product_photos enable row level security;
alter table orders         enable row level security;
alter table order_items    enable row level security;
alter table app_users      enable row level security;

-- Helper: ¿el usuario actual es admin?  (security definer = evita recursión de RLS)
create or replace function is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where id = auth.uid() and role = 'admin');
$$;
-- Helper: dealer_id del usuario actual
create or replace function my_dealer() returns uuid
  language sql stable security definer set search_path = public as $$
  select dealer_id from app_users where id = auth.uid();
$$;

-- DEALERS: todos leen los activos; admin todo; dealer edita el suyo
create policy dealers_read   on dealers for select using (active or is_admin() or id = my_dealer());
create policy dealers_admin  on dealers for all    using (is_admin()) with check (is_admin());
create policy dealers_self   on dealers for update using (id = my_dealer()) with check (id = my_dealer());

-- PRODUCTOS: público ve los publicados; dealer gestiona los suyos; admin todo
create policy products_read  on products for select using (
  (not paused and stock >= 0) or is_admin() or dealer_id = my_dealer()
);
create policy products_admin on products for all using (is_admin()) with check (is_admin());
create policy products_dealer on products for all
  using (dealer_id = my_dealer()) with check (dealer_id = my_dealer());

-- FOTOS: siguen al producto
create policy photos_read  on product_photos for select using (true);
create policy photos_write on product_photos for all using (
  is_admin() or exists (select 1 from products p where p.id = product_id and p.dealer_id = my_dealer())
) with check (
  is_admin() or exists (select 1 from products p where p.id = product_id and p.dealer_id = my_dealer())
);

-- PEDIDOS: el dealer ve/gestiona los suyos; el cliente los propios; admin todo
create policy orders_read on orders for select using (
  is_admin() or dealer_id = my_dealer() or customer_id = auth.uid()
);
create policy orders_insert on orders for insert with check (true);
create policy orders_update on orders for update using (is_admin() or dealer_id = my_dealer());

create policy items_read on order_items for select using (
  is_admin() or exists (select 1 from orders o where o.id = order_id and (o.dealer_id = my_dealer() or o.customer_id = auth.uid()))
);
create policy items_insert on order_items for insert with check (true);

-- APP_USERS: cada uno ve/edita lo suyo; admin todo
create policy users_self  on app_users for select using (id = auth.uid() or is_admin());
create policy users_selfw on app_users for update using (id = auth.uid()) with check (id = auth.uid());
create policy users_admin on app_users for all using (is_admin()) with check (is_admin());

-- Al registrarse un usuario, crear su fila en app_users automáticamente
-- (security definer + search_path fijo = requisito de Supabase para que no falle con 500)
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.app_users (id, full_name, email)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email)
  on conflict (id) do nothing;
  return new;
exception when others then
  return new;  -- nunca bloquear el registro del usuario
end;
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();
