# Progreso de StepMind

## Plan por fases

| Fase | Estado | Commit |
|---|---|---|
| 0. Saneamiento (git, dependencias, limpieza, test) | ✅ Hecha | `7036bc6` |
| 1. SQLite + Riverpod + estadísticas derivadas | ✅ Hecha | `c37e56c` |
| 2. Notificaciones correctas + foto persistente | ✅ Hecha | `31e1e0c` |
| 3. Supabase: auth real + sincronización | ⏳ Pendiente (necesita decisiones) | |
| 4. Diseño, tema, i18n, accesibilidad | ⏳ Pendiente (diseño en curso) | |
| 5. Publicación en Play Store | ⏳ Pendiente | |

`8430077` = código original antes de cualquier cambio.

## Prueba en dispositivo real (2026-10-12)

Honor LNA-NX3, Android 16, conectado por USB (la VPN bloquea la depuración por Wi-Fi).
Instalado APK release arm64. Resultado: **funciona**; sin errores en logcat durante la prueba
(login, hábitos, perfil, cierre y reapertura).

## Pendientes detectados

1. **Recordatorios con hasta 1 h de retraso.** Android 16 asigna a las alarmas inexactas
   una ventana de +1 h (`dumpsys alarm`). Propuesta: declarar `SCHEDULE_EXACT_ALARM`,
   pedirlo con `requestExactAlarmsPermission()` cuando el usuario active recordatorios y
   usar `exactAllowWhileIdle` si está concedido (si no, seguir con inexacto).
   `SCHEDULE_EXACT_ALARM` sí está permitido en Play; el restringido es `USE_EXACT_ALARM`.
2. En Honor/MagicOS hay que pedir al usuario que permita la ejecución en segundo plano
   (Batería → Inicio de aplicaciones). Conviene una pantalla de ayuda dentro de la app.
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
