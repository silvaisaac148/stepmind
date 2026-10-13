# Tareas de StepMind

*Creado el 2026-10-13. Marca con `[x]` lo terminado. Las tareas de Claude solo empiezan
cuando el usuario lo indique.*

Contexto: el público principal es **cristiano**. La app combina hábitos, superación de
adicciones (basada en evidencia: ACT, prevención de recaídas, planes si-entonces; ver
`docs/ESTUDIO.md`) y **contenido bíblico** opcional.

---

## Decisiones pendientes (usuario)

- [ ] **D1. Contenido cristiano:** ¿se puede activar o desactivar al empezar (recomendado) o va siempre activo?
- [ ] **D2. Versión bíblica:** Reina-Valera 1909 (dominio público, uso libre) o averiguar permisos de la
      RVR1960 / NVI (tienen derechos de autor). *No incluir textos con derechos sin permiso.*
- [ ] **D3. Nombre del paquete:** propuesto `com.stepmind.app` (no se puede cambiar una vez publicada).
- [ ] **D4. Cómo se financia:** gratis / donaciones / premium (afecta a la ficha de Play y al diseño).
- [ ] **D5. Notificaciones:** cuáles ofrecer y a qué hora por defecto (promesa matutina, repaso nocturno,
      versículo del día).

---

## Tareas del usuario (producto, contenido y pruebas)

### Pruebas
- [ ] **U1.** Probar el módulo de adicciones con `docs/PRUEBAS.md` (secciones A a E) y anotar fallos.
- [ ] **U2.** Ejecutar en Supabase `supabase/migrations/20261013010000_recovery.sql` y probar la
      sincronización de adicciones (sección F de `docs/PRUEBAS.md`).
- [ ] **U3.** Repetir la lista completa de pruebas antes de cada versión beta.

### Estudio de la competencia
Usar la plantilla `docs/PLANTILLA_COMPETENCIA.md`, una copia por app, en `docs/competencia/`.
- [ ] **U4.** Apps de adicciones: QUITTR, Fortify, I Am Sober.
- [ ] **U5.** Apps cristianas: Covenant Eyes, Ever Accountable, YouVersion (Biblia), Glorify.
- [ ] **U6.** Apps de hábitos: Finch, Habitica.
- [ ] **U7.** Resumen final: las 5 ideas que más valen la pena y las 3 cosas que debemos evitar.

### Contenido bíblico
- [ ] **U8.** Decidir la versión bíblica (D2) y confirmar sus derechos de uso.
- [ ] **U9.** Lista de versículos por situación (mínimo 5 por cada una), con referencia y texto:
      tentación, soledad, ansiedad/estrés, tristeza, enojo, cansancio, culpa tras un desliz (gracia y
      perdón), identidad en Cristo, perseverancia, gratitud, celebración de hitos.
- [ ] **U10.** Pedir a un pastor o líder que revise la lista (enfoque de gracia, no de condena).
- [ ] **U11.** (Más adelante) Ideas de devocionales o planes de 7 / 30 días.

### Diseño
- [ ] **U12.** (Opcional) Diseñar en Figma: bienvenida, tarjeta de versículo y pantalla de PIN.
- [ ] **U13.** Ícono de la app: confirmar que el logo actual sirve como ícono o hacer una versión
      simplificada (se ve muy pequeño en el teléfono).

### Publicación y comunidad
- [ ] **U14.** Decidir D3 y D4.
- [ ] **U15.** Crear la cuenta de Google Play Console (pago único de 25 USD, a confirmar).
- [ ] **U16.** Buscar entre 10 y 20 probadores (por ejemplo, en tu iglesia) para la beta cerrada.
- [ ] **U17.** Textos de la ficha de Play: descripción corta, descripción larga y capturas.

---

## Tareas de Claude (desarrollo) — *en espera de luz verde*

### Bloquean la publicación
- [ ] **C1.** Borrar la cuenta y los datos de la nube desde la app (obligatorio en Play).
- [ ] **C2.** Redactar la política de privacidad (borrador para revisar y publicar en una URL).
- [ ] **C3.** Cambiar el identificador de la app según D3 (Android e iOS).
- [ ] **C4.** Ícono de la app y pantalla de arranque nativa con el logo.
- [ ] **C5.** Registro de errores (por ejemplo, Sentry) sin datos personales ni sensibles.

### Experiencia
- [ ] **C6.** Bienvenida en el primer uso: nombre, interruptor de contenido cristiano (D1) y
      explicación de las notificaciones antes de pedir el permiso.
- [ ] **C7.** PIN o huella opcional para abrir el módulo de adicciones.
- [ ] **C8.** Notificaciones opcionales (D5) con textos discretos (nunca nombrar la adicción en
      la pantalla bloqueada).
- [ ] **C9.** Hábitos por días de la semana, íconos o categorías, y varios recordatorios.
- [ ] **C10.** Revisar textos de relleno en Ajustes ("Privacidad y Seguridad", "Información").

### Contenido cristiano
- [ ] **C11.** Estructura de versículos por situación (archivo local, sin conexión) y una semilla de
      unos 30 versículos de la RV1909 hasta tener la lista revisada (U9 y U10).
- [ ] **C12.** Versículo del día en Inicio.
- [ ] **C13.** SOS: paso de oración y versículo según la emoción elegida.
- [ ] **C14.** Tras un desliz: mensaje de gracia con versículo (1 Jn 1:9, Sal 51…).
- [ ] **C15.** Celebración de hitos con versículo.
- [ ] **C16.** (Más adelante) Compañero de rendición de cuentas.

### Calidad
- [ ] **C17.** Mantener `docs/PRUEBAS.md` al día con cada función nueva.
- [ ] **C18.** Tests automáticos de cada función nueva (dominio, sincronización y pantallas).

---

## Orden sugerido

1. **Usuario:** U1, U2 (probar lo que ya existe) y decisiones D1 a D3.
2. **Claude:** C3 → C1 → C2 → C4 (desbloquear la publicación).
3. **Claude:** C11 → C12 → C13 → C14 (contenido cristiano), en paralelo con **usuario:** U8 → U9 → U10.
4. **Claude:** C6 → C8 → C7. **Usuario:** U4 a U7 (estudio de la competencia).
5. Beta cerrada: U15 a U17 y C5.
