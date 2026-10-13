# Progreso de StepMind

> Tareas pendientes (usuario y Claude): `docs/TAREAS.md` · Casos de prueba: `docs/PRUEBAS.md` ·
> Estudio: `docs/ESTUDIO.md` · Plantilla de competencia: `docs/PLANTILLA_COMPETENCIA.md`

## Plan por fases

| Fase | Estado | Commit |
|---|---|---|
| 0. Saneamiento (git, dependencias, limpieza, test) | ✅ Hecha | `7036bc6` |
| 1. SQLite + Riverpod + estadísticas derivadas | ✅ Hecha | `c37e56c` |
| 2. Notificaciones correctas + foto persistente | ✅ Hecha | `31e1e0c` |
| 2b. Alarmas exactas + ayuda de batería | ✅ Hecha y probada en el teléfono | `fbeca72` |
| 3. Supabase: auth real + sincronización | ✅ Hecha y probada en el teléfono | `abfee00` |
| 4. Diseño (Figma recuperado + mejoras) | ✅ Tema, splash, login, inicio, calendario, paleta | `ee0ce7b` |
| 4b. Módulo de adicciones (SOS, porqué, planes, patrones, hitos) | 🟡 Hecho; falta probarlo en el teléfono | ver git log |
| 5. Publicación en Play Store | ⏳ Pendiente | |

`8430077` = código original antes de cualquier cambio.

## Fase 3: cuentas y nube (2026-10-13)

Decisiones: cuenta **opcional**; login con **Google** y **correo + contraseña**;
proyecto Supabase `tvyppqlsogyoyaoijhkv`.

- El teléfono (SQLite) sigue siendo la fuente de verdad; sin cuenta funciona igual.
- Con sesión se sincronizan hábitos, marcas, eventos y perfil (la foto se queda local).
  Gana el cambio más reciente (`updated_at`); los borrados viajan como `deleted`.
- Al iniciar sesión lo que ya había en el teléfono se sube a la cuenta.
- Cerrar sesión: conservar datos en el teléfono o borrarlos (solo si se subió todo).
- Google usa OAuth en el navegador (no hace falta SHA-1). Vuelta: `io.stepmind.app://login-callback`.
- Arreglado bug de la fase 1: editar un hábito borraba todas sus marcas
  (`INSERT OR REPLACE` + `ON DELETE CASCADE`).
- **Adicciones:** hoy la pantalla es solo informativa, la app no guarda datos de
  adicciones. Cuando exista un registro de adicciones: local por defecto y subida a la
  nube solo si el usuario la activa (decisión tomada).

### Configuración local

Las claves van en `config/supabase.json` (ignorado por git; plantilla en
`config/supabase.example.json`). Compilar/ejecutar siempre con:

```bash
flutter run --dart-define-from-file=config/supabase.json
flutter build apk --release --split-per-abi --dart-define-from-file=config/supabase.json
```

Sin ese parámetro la app compila sin cuentas (solo "Continuar sin cuenta").

### Pasos en el panel (hechos el 2026-10-13)

1. SQL Editor → ejecutar `supabase/migrations/20261013000000_init.sql`.
2. Authentication → URL Configuration → Redirect URLs → añadir `io.stepmind.app://login-callback`.
3. Google: en Google Cloud Console crear cliente OAuth tipo **Aplicación web** con URI de
   redirección `https://tvyppqlsogyoyaoijhkv.supabase.co/auth/v1/callback`; pegar Client ID
   y Secret en Authentication → Sign In / Providers → Google y activarlo.

## Módulo de adicciones (2026-10-13)

Basado en `docs/ESTUDIO.md`. Pestaña "Adicciones":
- Metas (pornografía, redes, alcohol…) con fecha de inicio, "mi porqué" y planes si-entonces.
- Racha actual en vivo + **días limpios totales** (un desliz no los borra) + mejor racha.
- **SOS**: intensidad/emoción → respiración 4-6 guiada → surfear la ola → porqué y planes →
  acción alternativa → "pasó" (se registra como urgencia superada) o "recaí" (registro sin culpa).
- Patrones: emoción, situación y franja horaria más frecuentes. Hitos 1-3-7-14-30-66-90-180-365 con celebración.
- Privacidad: local por defecto. Ajustes → Cuenta → "Sincronizar datos de adicciones" (opcional).
  **Requiere ejecutar `supabase/migrations/20261013010000_recovery.sql` antes de activarlo.**
- Pendiente: PIN/huella para abrir el módulo; notificaciones de promesa matutina / repaso nocturno.

## Prueba en dispositivo real (2026-10-13)

Login con Google y con correo, sincronización y migración de la base v1→v2 (instalación
encima de la versión anterior) funcionan. Recordatorio a la hora exacta confirmado con
`dumpsys alarm`: `window=0 exactAllowReason=permission`. Sin errores en logcat.

## Prueba en dispositivo real (2026-10-12)

Honor LNA-NX3, Android 16, conectado por USB (la VPN bloquea la depuración por Wi-Fi).
Instalado APK release arm64. Resultado: **funciona**; sin errores en logcat durante la prueba
(login, hábitos, perfil, cierre y reapertura).

## Pendientes detectados

1. ~~Recordatorios con hasta 1 h de retraso~~ → **resuelto (2026-10-13)**: se declara
   `SCHEDULE_EXACT_ALARM`; se ofrece una sola vez al crear un hábito y siempre desde
   Ajustes → "Recordatorios a la hora exacta". Con permiso se usa `exactAllowWhileIdle`,
   sin él `inexactAllowWhileIdle`. Se reprograma al volver a la app.
   **Probar en el Honor:** conceder el permiso y comprobar con
   `adb shell dumpsys alarm | grep -A3 stepmind` que la ventana ya no es de +1 h.
2. ~~Ayuda de batería~~ → **resuelto**: Ajustes → "¿No te llegan los recordatorios?"
   con pasos para Honor/Huawei, Xiaomi, Samsung y Oppo/Realme/OnePlus.
3. ~~Decisiones de la fase 3~~ → tomadas (ver "Fase 3" arriba).
4. Antes de publicar (fase 5): cambiar `applicationId` `com.example.stepmind` (Play lo rechaza).

## Cómo probar en el teléfono

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=config/supabase.json
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
