# Estudio: mercado, evidencia y dirección de StepMind

*2026-10-13. Fuentes al final. Es una guía de producto, no consejo médico.*

## 1. Mercado

| App | Enfoque | Lo que hace bien | Debilidad / oportunidad |
|---|---|---|---|
| **QUITTR** | Dejar el porno, de pago | Comunidad fuerte, mensajes "con base en neurociencia" | Caro; el marketing exagera la ciencia |
| **Fortify** | Dejar el porno | Evaluación inicial, retos y videos personalizados, coaches, grupos, terapia ($9.99/mes) | La mayor parte del valor está detrás del pago |
| **Brainbuddy** | Dejar el porno, gamificado | Retos diarios, rachas, quizzes (~$12.99/mes) | Las reseñas no coinciden sobre si bloquea contenido o si ayuda en el momento de la urgencia |
| **RebootMate** | Dejar el porno, privado | Sin cuenta, sin conexión | Sin sincronización ni acompañamiento |
| **I Am Sober** | Cualquier adicción | Promesa diaria (mañana) + repaso (noche), hitos (1 día, 1 semana, 1 mes…), análisis de desencadenantes, diario | Visual genérico; centrado en el contador |
| **Finch** | Autocuidado | Mascota que crece con tus hábitos, colores suaves, muy querida | Onboarding largo; no está pensada para adicciones |
| Apps de rachas (Streaks, etc.) | Hábitos | La racha engancha (aversión a perder) | **Romper la racha desmotiva mucho** → las apps nuevas añaden "congelar" o "perdonar" días |

**Conclusiones:**
- Ninguna junta **hábitos positivos + dejar una adicción + privacidad (todo en el teléfono) + español**. Ese es el hueco de StepMind.
- Lo que más se paga es la **ayuda en el momento de la urgencia** y la **personalización**.
- El error común: un contador de días que vuelve a 0 y hace sentir fracaso.

## 2. Qué dice la evidencia

1. **ACT (Terapia de Aceptación y Compromiso)** es la intervención con mejor evidencia
   específica para el porno problemático. Ensayo aleatorizado (Crosby y Twohig, 2016;
   28 hombres, 12 sesiones): **−93 % de consumo** frente a −21 % en lista de espera;
   54 % lo dejó del todo al terminar y 35 % a los 3 meses. Es una muestra pequeña, pero la
   dirección es clara. La idea central de ACT: **no luchar contra la urgencia, observarla
   y actuar según tus valores**.
2. **Mindfulness para prevenir recaídas (Bowen, 2014, JAMA Psychiatry):** a los 12 meses
   recayó menos el grupo de mindfulness (~9 %) que el de 12 pasos (14 %) y el de prevención
   de recaídas tradicional (17 %).
3. **Surfear la urgencia** (*urge surfing*): no siempre baja el deseo, pero sí el consumo
   (Bowen y Marlatt, 2009). Dato honesto: no está demostrado que todas las urgencias
   desaparezcan en X minutos.
4. **Planes "si… entonces…"** (*implementation intentions*). Meta-análisis de 94 estudios
   (Gollwitzer y Sheeran, 2006): efecto **d = 0.65** en lograr metas. Ejemplo: "Si estoy solo
   en la cama con el móvil después de las 23:00, entonces lo dejo cargando fuera del cuarto".
5. **Formar un hábito lleva una media de 66 días** (entre 18 y 254). **Fallar un día no
   arruina el proceso**; lo que perjudica es fallar varios seguidos (Lally, 2010).
6. **Efecto de violación de la abstinencia** (Marlatt): tras un desliz, el "ya lo arruiné
   todo" lleva a la recaída completa. Antídoto: **autocompasión + analizar el desliz**,
   no reiniciar con culpa.
7. **Clínica:** la OMS (CIE-11) lo clasifica como *trastorno de conducta sexual compulsiva*.
   El tratamiento de primera línea es la psicoterapia (TCC/ACT). Hay debate sobre el
   sobrediagnóstico. **La app acompaña; no sustituye a un profesional.**

## 3. Cómo lo aplicamos en StepMind

### Módulo "Superar una adicción" (local por defecto, nube solo si el usuario la activa)

| Función | Base | Prioridad |
|---|---|---|
| **Botón de urgencia (SOS)**: respiración guiada de 90 s → "surfear la ola" → recordar tu *por qué* → una acción alternativa (ducha fría, salir a caminar, llamar a alguien, flexiones) | ACT, urge surfing | ⭐ 1 |
| **Mi porqué**: valores y razones escritos por el usuario (texto o foto), que aparecen en el SOS | ACT (valores) | ⭐ 1 |
| **Planes si-entonces** para los desencadenantes personales | Gollwitzer | ⭐ 1 |
| **Días limpios sin castigo**: se muestra el *total de días limpios* y la *racha actual*. Un desliz no borra el progreso; pide registrar qué pasó (hora, lugar, emoción: HALT = hambre, enfado, soledad, cansancio) | Marlatt, Lally | ⭐ 1 |
| **Mapa de desencadenantes**: patrones por hora, día y emoción a partir de los registros | Prevención de recaídas | 2 |
| **Promesa matutina + repaso nocturno** (notificaciones) | I Am Sober | 2 |
| **Hitos con significado** (1, 3, 7, 14, 30, 66, 90 días…) con mensajes basados en la evidencia, no en mitos | Lally | 2 |
| **Hábitos de reemplazo** conectados con los hábitos existentes (ejercicio, lectura, sueño) | ACT (acción comprometida) | 2 |
| **Ayuda profesional**: enlaces a recursos y líneas de ayuda por país | Clínica | 2 |
| Bloqueo de contenido | La mayoría de las apps | 3 (complejo en Android; mejor guiar hacia DNS o filtros del sistema) |
| Compañero de responsabilidad (compartir progreso) | Comunidad | 3 (requiere moderación) |

**Privacidad:** PIN o huella opcional para abrir el módulo; nombre discreto en las
notificaciones ("StepMind: tu momento de calma").

### Tono

Compasivo y directo; nunca vergüenza. "Un desliz es información, no un fracaso."
Celebrar el total de días limpios, no solo la racha.

## 4. Dirección visual (Fase 4)

Hoy: marrón oscuro `#282524` con grises → sobrio pero plano y sin identidad.

Propuesta: **"Noche serena con energía"**
- Fondo: azul noche profundo (`#0F1220` → `#171B2E`), superficies con algo de elevación.
- Primario: **ámbar/dorado** (continúa el amarillo del splash) para el progreso y los logros.
- Secundario: **turquesa/menta** para la calma (SOS, respiración).
- Acento de alerta suave: coral (deslices o "necesito ayuda"), nunca rojo agresivo.
- Gradientes sutiles en las tarjetas principales, anillos de progreso, ilustraciones simples.
- Material 3 con `ColorScheme`, tipografía con más jerarquía, modo claro opcional.
- Accesibilidad: contraste AA, tamaños de toque ≥ 48 dp, `Semantics` en los anillos y contadores.
- i18n: ES base, EN después (con `flutter_localizations` + ARB).

## Fuentes

- Mercado: [Canopy – Best NoFap apps 2026](https://canopy.us/blog/best-nofap-apps/) · [Birches Health – Porn addiction apps](https://bircheshealth.com/resources/porn-addiction-apps) · [RebootMate review 2026](https://vucense.com/tech-guides/digital-wellness/rebootmate-review-private-porn-addiction-recovery-app-2026/) · [I Am Sober (App Store)](https://apps.apple.com/app/id672904239) · [Finch – crítica de diseño](https://ixd.prattsi.org/2025/09/design-critique-finch-ios-app-2/)
- Rachas: [Newswise – why streaks make resolutions stick](https://www.newswise.com/articles/research-explains-why-streaks-make-resolutions-stick) · [PRSA – streaks](https://prsa.org/article/how-streaks-help-us-build-good-habits-and-achieve-goals-ST-March25)
- ACT: [Crosby y Twohig 2016 (PubMed)](https://pubmed.ncbi.nlm.nih.gov/27157029/) · [Twohig 2010](https://digitalcommons.usu.edu/psych_facpub/1700)
- Mindfulness: [Bowen 2014 JAMA Psychiatry (PDF)](https://www.psychiatry.wisc.edu/wp-content/uploads/2025/05/Article-1_Bowen-et-al-JAMA-2014.pdf) · [Recovery Answers](https://www.recoveryanswers.org/?p=260) · [Urge surfing – Mindful.org](https://www.mindful.org/mindfulness-and-cravings/)
- Planes si-entonces: [Gollwitzer y Sheeran 2006 (Konstanz)](https://kops.uni-konstanz.de/entities/publication/2e749bfb-8533-437c-8203-7e788c910c5f)
- Formación de hábitos: [Lally – resumen (PsyBlog)](https://www.spring.org.uk/2023/01/form-a-habit.php)
- Clínica: [Revisión 2025 sobre conducta sexual compulsiva (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12268503/) · [Frontiers in Psychiatry 2025](https://www.frontiersin.org/articles/10.3389/fpsyt.2025.1621136/full)
