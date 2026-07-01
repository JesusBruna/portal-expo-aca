-- ============================================================
--  PORTAL EXPO ACA — Datos de ejemplo (seed)
--  Ejecutar DESPUÉS de schema.sql.
-- ============================================================

-- Categorías
insert into categories (name, slug, tone) values
  ('Accesorios para auto', 'accesorios', '#C8102E'),
  ('Repuestos y mantenimiento', 'repuestos', '#2A2629'),
  ('Neumáticos', 'neumaticos', '#C8102E'),
  ('Lubricantes y aceites', 'lubricantes', '#0E8F6E'),
  ('Motos', 'motos', '#B0631A'),
  ('Audio y tecnología', 'audio', '#8E0C20'),
  ('Vida al aire libre', 'aire-libre', '#0E8F6E'),
  ('Indumentaria y seguridad', 'indumentaria', '#C8102E');

-- Expos / concesionarios
insert into dealers (id, razon, sede, rubro, cuit, tel, email, dir, horario, map_link, tone, initial, rating) values
  ('11111111-1111-1111-1111-111111111111','AutoParts Pro S.A.','ExpoACA Palermo','Repuestos y accesorios','30-71234567-8','+54 9 11 5555-1001','ventas@autopartspro.com.ar','Av. del Libertador 1850, CABA','Lun a Sáb 8–20h','https://www.google.com/maps?q=-34.5711,-58.4229&z=16','#C8102E','AP',4.8),
  ('22222222-2222-2222-2222-222222222222','NeumaTech SRL','ExpoACA Liniers','Neumáticos y baterías','30-70888111-2','+54 9 11 5555-1002','contacto@neumatech.com.ar','Av. Rivadavia 11500, CABA','Lun a Sáb 8–20h','https://www.google.com/maps?q=-34.6437,-58.5261&z=16','#2A2629','NT',4.7),
  ('33333333-3333-3333-3333-333333333333','Patagonia Outdoor SA','ExpoACA Bariloche','Camping y aire libre','30-71555999-0','+54 9 294 555-1003','hola@patagoniaoutdoor.com.ar','Av. Bustillo 4500, Bariloche','Lun a Sáb 9–19h','https://www.google.com/maps?q=-41.1335,-71.3103&z=16','#0E8F6E','PO',4.9);

-- Productos (dealer_id + category_id por slug)
insert into products (dealer_id, name, brand, category_id, price_list, price_socio, stock, is_deal)
select '11111111-1111-1111-1111-111111111111','Aceite Motul 5W30 sintético 4L','Motul', c.id, 38500, 30800, 120, true
from categories c where c.slug='lubricantes';

insert into products (dealer_id, name, brand, category_id, price_list, price_socio, stock, is_deal)
select '11111111-1111-1111-1111-111111111111','Kit de luces LED H4','Osram', c.id, 24000, 19200, 210, true
from categories c where c.slug='accesorios';

insert into products (dealer_id, name, brand, category_id, price_list, price_socio, stock)
select '22222222-2222-2222-2222-222222222222','Cubierta Pirelli Scorpion 215/65 R16','Pirelli', c.id, 142000, 118800, 34
from categories c where c.slug='neumaticos';

insert into products (dealer_id, name, brand, category_id, price_list, price_socio, stock)
select '33333333-3333-3333-3333-333333333333','Carpa 4 personas Doite Tornado','Doite', c.id, 96000, 76800, 8
from categories c where c.slug='aire-libre';

-- NOTA: para convertir tu usuario en ADMIN (dueño), después de registrarte una vez, ejecutá:
--   update app_users set role = 'admin' where email = 'TU-EMAIL-ACA@ejemplo.com';
-- Para vincular un usuario como concesionario:
--   update app_users set role='dealer', dealer_id='11111111-1111-1111-1111-111111111111' where email='ventas@autopartspro.com.ar';
