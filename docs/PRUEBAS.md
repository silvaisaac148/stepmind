# Casos de prueba manuales (en el teléfono)

*Ejecutar con la versión de release:*

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=config/supabase.json
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Para cada caso anota: ✅ funciona / ❌ falla (qué pasó, captura) / ⚠️ funciona pero mejorable.

| Versión probada | Fecha | Teléfono | Quién |
|---|---|---|---|
| | | Honor LNA-NX3 (Android 16) | |

---

## A. Módulo de adicciones: crear una meta

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| A1 | Adicciones → Empezar | Se abre "Nueva meta" | |
| A2 | Tocar un chip (p. ej. "Pornografía") | El nombre se rellena y el chip queda marcado | |
| A3 | Guardar sin nombre | Aviso "Escribe o elige qué quieres dejar" | |
| A4 | "¿Desde cuándo?" → elegir una fecha de hace 8 días | Muestra "Desde el …" con esa fecha | |
| A5 | Escribir el porqué y 2 planes si-entonces → Empezar | Vuelve al panel con la meta creada | |
| A6 | Al volver al panel | Celebración "¡7 días!" una sola vez (al reabrir la app no se repite) | |
| A7 | Panel | Racha "8 d X h", próximo hito 14, días limpios = 9, porqué y planes visibles | |
| A8 | ⋯ → Editar → cambiar el porqué → Guardar | El panel muestra el nuevo porqué | |
| A9 | ＋ (arriba) → crear una segunda meta | Aparecen chips para cambiar entre metas | |
| A10 | ⋯ → Archivar la segunda meta | Desaparece; queda la primera | |

## B. SOS ("Tengo una urgencia")

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| B1 | Tocar "Tengo una urgencia" | Pantalla petróleo "Momento de calma", paso 1 | |
| B2 | Mover la intensidad, elegir una emoción → Empezar | Pasa a la respiración | |
| B3 | Respiración | El círculo crece al inhalar (4 s) y se encoge al exhalar (6 s); cuenta atrás de 1:00 | |
| B4 | Tocar "Saltar" a mitad | Pasa a "Surfea la ola" sin errores | |
| B5 | Siguiente → "Recuerda tu porqué" | Muestra tu porqué y tus planes | |
| B6 | Elegir una acción → "La urgencia pasó" | Diálogo "¡Lo lograste!"; al cerrar vuelve al panel | |
| B7 | Panel | "Urgencias superadas" +1; aparece en "Últimos registros" con la intensidad | |
| B8 | SOS de nuevo → "Recaí (sin juzgarte)" | Se abre el registro de desliz con la emoción ya marcada | |
| B9 | Cerrar el SOS con ✕ a mitad | Vuelve al panel sin registrar nada | |

## C. Deslices y patrones

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| C1 | "Registrar un desliz" → emoción + situación + nota → Guardar | Mensaje de ánimo; la racha vuelve a 0 d | |
| C2 | Panel tras el desliz | **Días limpios NO bajan a 0** (solo resta el día del desliz); la mejor racha se conserva | |
| C3 | "Tus patrones" tras 2-3 registros | Emoción, situación y momento del día más frecuentes | |
| C4 | Borrar un registro (🗑) | Desaparece y las estadísticas se recalculan | |
| C5 | Dejar la app abierta más de 1 minuto | El contador de horas se actualiza solo | |

## D. Persistencia

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| D1 | Cerrar la app por completo y abrirla | Metas, registros y estadísticas siguen igual | |
| D2 | Instalar una versión nueva encima (`adb install -r`) | No se pierde nada | |
| D3 | Modo avión → crear registros | Funciona sin conexión | |

## E. Resto de la app (regresión)

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| E1 | Splash | Logo amarillo sobre degradado petróleo | |
| E2 | Inicio | Tira de 7 días con hoy en naranja; anillo "x/y"; frase del día | |
| E3 | Tocar un día de la tira | Abre el calendario con ese día seleccionado | |
| E4 | Calendario → tocar el mes | Selector emergente con el fondo oscurecido; ACEPTAR lleva a esa fecha | |
| E5 | Hábitos → crear, marcar, editar el nombre | **Editar no borra el historial** (bug arreglado en la fase 3) | |
| E6 | Recordatorio de un hábito 2 minutos después | Suena a la hora exacta (con el permiso concedido) | |
| E7 | Ajustes → "¿No te llegan los recordatorios?" | Muestra los pasos por marca de teléfono | |
| E8 | Progreso | Colores de la marca (naranja, amarillo, turquesa) | |

## F. Cuenta y nube

| # | Pasos | Resultado esperado | Estado |
|---|---|---|---|
| F1 | Iniciar sesión con Google | Vuelve a la app con la sesión iniciada | |
| F2 | Iniciar sesión con correo y contraseña | Entra; los errores muestran mensajes claros | |
| F3 | "¿Olvidaste tu contraseña?" → abrir el correo en el teléfono | La app pide la nueva contraseña | |
| F4 | Ajustes → Cuenta | "Sincronizado a las HH:MM" | |
| F5 | Crear un hábito → esperar unos segundos → ver la tabla `habits` en Supabase | La fila aparece | |
| F6 | "Sincronizar datos de adicciones" **sin** haber ejecutado el SQL del módulo | Aviso de error de sincronización (no se cierra la app) | |
| F7 | Ejecutar el SQL → activar la opción | Las metas y los registros aparecen en `recovery_goals` / `recovery_events` | |
| F8 | Desactivar → "Borrar de la nube" | Las tablas de recuperación quedan vacías para tu usuario; el teléfono conserva todo | |
| F9 | Cerrar sesión → "Conservar" | Los datos siguen en el teléfono | |
| F10 | Por defecto (opción apagada) | **Nada** del módulo de adicciones aparece en Supabase | |

---

## Registro de fallos

| Fecha | Caso | Qué pasó | Captura | Estado del arreglo |
|---|---|---|---|---|
| | | | | |
