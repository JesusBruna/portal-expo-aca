# Portal EXPO ACA — Puesta en producción (Netlify + Supabase)

Guía para pasar el portal de prototipo a **web real**, con base de datos, login y control de administrador.

## Arquitectura

```
  Navegador
     │
     ▼
  Netlify  ──────────────►  Frontend (el portal, archivos estáticos)
     │
     ▼  (API + Auth por HTTPS)
  Supabase ──────────────►  Base de datos PostgreSQL + Login + Storage de fotos
```

- **Netlify**: aloja el sitio (gratis). No aloja bases de datos.
- **Supabase**: base de datos + autenticación + almacenamiento de imágenes (gratis hasta buen volumen).
- **Vos (dueño)**: usuario con rol `admin` → ves y editás TODO.

---

## Paso 1 — Crear la base de datos (Supabase)

1. Entrá a https://supabase.com → **New project** (elegí región, contraseña de DB).
2. En el panel: **SQL Editor → New query**.
3. Pegá y ejecutá `db/schema.sql` (crea tablas, roles y seguridad).
4. Pegá y ejecutá `db/seed.sql` (datos de ejemplo: expos, categorías, productos).
5. En **Project Settings → API** copiá:
   - `Project URL`
   - `anon public key`
   (Estos dos van en el frontend; son seguros para el navegador porque la seguridad real está en las políticas RLS de la base.)

## Paso 2 — Activar login

- En Supabase: **Authentication → Providers → Email** (activado por defecto).
- Registrás tu cuenta desde el portal una vez.
- Para convertirte en **dueño/admin**, en SQL Editor:
  ```sql
  update app_users set role = 'admin' where email = 'TU-EMAIL@ejemplo.com';
  ```
- Para dar de alta un concesionario:
  ```sql
  update app_users set role='dealer', dealer_id='11111111-1111-1111-1111-111111111111'
  where email='ventas@autopartspro.com.ar';
  ```

## Paso 3 — Publicar el frontend en Netlify

Opción simple (sin código):
1. Entrá a https://app.netlify.com → **Add new site → Deploy manually**.
2. Arrastrá la carpeta del sitio (los archivos del portal).
3. Netlify te da una URL pública (ej. `portal-expo-aca.netlify.app`).

Opción con Git (recomendada para actualizar):
1. Subí el proyecto a un repo de GitHub.
2. En Netlify: **Add new site → Import from Git** → elegí el repo.
3. Cada `git push` publica los cambios automáticamente.

Config incluida: ver `netlify.toml`.

## Paso 4 — Conectar frontend ↔ base de datos

En el frontend se cargan las claves de Supabase (Paso 1.5). Con eso el portal deja de usar
almacenamiento local y pasa a leer/escribir en la base real: productos, stock, pedidos, perfiles
y ofertas quedan compartidos entre todos los usuarios y dispositivos.

> Este paso (reemplazar el guardado local por llamadas a Supabase en cada pantalla) es el trabajo
> de desarrollo principal. Ver la sección "Qué falta para el 100%" abajo.

---

## Control del administrador (vos)

Con rol `admin` vas a poder:
- Ver y editar **todos** los expos, productos, pedidos y usuarios.
- Aprobar/dar de alta concesionarios y asignarles su expo.
- Activar/desactivar expos y publicaciones.
- Ver métricas globales (ventas, pedidos, altas).

Los concesionarios (`dealer`) solo ven y editan **su propio** contenido — garantizado por las
políticas de seguridad (RLS) de la base, no solo por la interfaz.

---

## Qué falta para el 100% (desarrollo)

El prototipo actual guarda todo en el navegador (localStorage). Para que funcione como web real hay que:
1. Añadir el cliente de Supabase al frontend y las claves.
2. Reemplazar cada lectura/escritura local por consultas a la base (productos, pedidos, perfiles, ofertas).
3. Conectar el login del portal con Supabase Auth (socios, concesionarios, admin).
4. Subida de fotos reales a Supabase Storage.
5. Panel de administrador global (dueño).

Es un trabajo de desarrollo acotado y estándar. Se puede hacer por partes.
