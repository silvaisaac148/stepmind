/// Textos del módulo de adicciones. Basados en docs/ESTUDIO.md (ACT,
/// prevención de recaídas, planes si-entonces). No sustituyen a un profesional.
library;

const recoveryPresets = [
  'Pornografía',
  'Redes sociales',
  'Videojuegos',
  'Alcohol',
  'Tabaco / vapeo',
  'Apuestas',
  'Comida compulsiva',
  'Compras compulsivas',
];

/// Emociones frecuentes antes de un impulso (incluye HALT: hambre, enfado,
/// soledad, cansancio).
const recoveryEmotions = [
  'Soledad',
  'Aburrimiento',
  'Estrés',
  'Ansiedad',
  'Tristeza',
  'Enfado',
  'Cansancio',
  'Hambre',
  'Excitación',
];

const recoverySituations = [
  'En la cama con el móvil',
  'Solo en casa',
  'De noche',
  'Redes sociales',
  'Después de un mal día',
  'Sin nada que hacer',
  'Después de discutir',
  'Al despertar',
];

/// Acciones alternativas para el SOS (cambiar de lugar y de estado físico
/// corta el automatismo).
const recoveryActions = [
  ('🚿', 'Date una ducha fría'),
  ('🚶', 'Sal a caminar 10 minutos'),
  ('💪', 'Haz 20 flexiones o sentadillas'),
  ('📞', 'Escribe o llama a alguien'),
  ('🚪', 'Sal de la habitación'),
  ('💧', 'Toma un vaso de agua'),
  ('📝', 'Escribe lo que sientes'),
  ('📖', 'Lee 5 páginas de un libro'),
];

/// Mensaje al alcanzar cada hito (en días).
const milestoneMessages = {
  1: 'Primer día. El paso más difícil ya lo diste.',
  3: 'Tres días. Las urgencias suelen ser más fuertes al principio: lo estás logrando.',
  7: 'Una semana entera. Tu cerebro empieza a aprender otra forma de responder.',
  14: 'Dos semanas. Ya sabes que las urgencias pasan aunque no las obedezcas.',
  30: 'Un mes. Esto ya no es suerte: es una decisión que repites cada día.',
  66: '66 días: la media para que un hábito se vuelva automático. Enorme.',
  90: 'Tres meses. Mira cuánto ha cambiado tu día a día.',
  180: 'Medio año. Eres prueba de que se puede.',
  365: 'Un año. Gracias por no rendirte contigo.',
};

const slipCompassionMessages = [
  'Un desliz es información, no un fracaso. Tus días limpios siguen contando.',
  'Lo que importa ahora es el siguiente paso, no el anterior.',
  'Recaer es parte de muchos procesos de cambio. Aprende qué pasó y sigue.',
];
