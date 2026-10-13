# Progreso de StepMind

## Plan por fases

| Fase | Estado | Commit |
|---|---|---|
| 0. Saneamiento (git, dependencias, limpieza, test) | ✅ Hecha | `7036bc6` |
| 1. SQLite + Riverpod + estadísticas derivadas | ✅ Hecha | `c37e56c` |
| 2. Notificaciones correctas + foto persistente | ✅ Hecha | `31e1e0c` |
| 2b. Alarmas exactas + ayuda de batería | ✅ Hecha (falta probar en el teléfono) | ver git log |
| 3. Supabase: auth real + sincronización | ⏳ Pendiente (necesita decisiones) | |
| 4. Diseño, tema, i18n, accesibilidad | ⏳ Pendiente (diseño en curso) | |
| 5. Publicación en Play Store | ⏳ Pendiente | |

`8430077` = código original antes de cualquier cambio.

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
3. Fase 3, decisiones pendientes:
   - ¿Proyecto Supabase nuevo? (URL + anon key)
   - Métodos de login: email/contraseña, Google, ¿Apple?
   - ¿Cuenta obligatoria u opcional? (recomendado: opcional, la app funciona sin cuenta)
   - ¿Los datos de adicciones se suben a la nube o se quedan en el teléfono?

## Cómo probar en el teléfono

```bash
flutter build apk --release --split-per-abi
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
