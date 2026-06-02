/// Quick notes (notes rapides) prédéfinies pour les articles de commande
/// Permet aux serveurs d'ajouter rapidement des annotations sans taper du texte
class QuickNote {
  const QuickNote({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Catégories de notes rapides groupées par utilité
class QuickNoteCategory {
  const QuickNoteCategory({
    required this.name,
    required this.notes,
  });

  final String name;
  final List<QuickNote> notes;
}

/// Notes rapides pour régimes et allergies
final quickNotesDietary = <QuickNote>[
  const QuickNote(label: 'Sans sel', value: 'Sans sel'),
  const QuickNote(label: 'Sans sucre', value: 'Sans sucre'),
  const QuickNote(label: 'Sans gluten', value: 'Sans gluten'),
  const QuickNote(label: 'Sans lactose', value: 'Sans lactose'),
  const QuickNote(label: 'Végétarien', value: 'Végétarien'),
  const QuickNote(label: 'Végan', value: 'Végan'),
];

/// Notes rapides pour la cuisson et préparation
final quickNotesCooking = <QuickNote>[
  const QuickNote(label: 'Bien cuit', value: 'Bien cuit'),
  const QuickNote(label: 'À point', value: 'À point'),
  const QuickNote(label: 'Saignant', value: 'Saignant'),
  const QuickNote(label: 'Pas de sauce', value: 'Pas de sauce'),
  const QuickNote(label: 'Sauce à part', value: 'Sauce à part'),
  const QuickNote(label: 'Extra garniture', value: 'Extra garniture'),
];

/// Notes rapides pour modifications et préférences
final quickNotesModifications = <QuickNote>[
  const QuickNote(label: 'Extra fromage', value: 'Extra fromage'),
  const QuickNote(label: 'Extra oignon', value: 'Extra oignon'),
  const QuickNote(label: 'Extra ail', value: 'Extra ail'),
  const QuickNote(label: 'Sans oignon', value: 'Sans oignon'),
  const QuickNote(label: 'Sans ail', value: 'Sans ail'),
  const QuickNote(label: 'Sans piment', value: 'Sans piment'),
  const QuickNote(label: 'Épicé', value: 'Épicé'),
];

/// Notes rapides pour services spéciaux
final quickNotesSpecial = <QuickNote>[
  const QuickNote(label: 'Urgent', value: 'Urgent'),
  const QuickNote(label: 'À garder au chaud', value: 'À garder au chaud'),
  const QuickNote(label: 'Pour emporter', value: 'Pour emporter'),
  const QuickNote(label: 'Allergies présentes', value: 'Allergies présentes'),
];

/// Toutes les catégories de notes rapides
final quickNoteCategories = <QuickNoteCategory>[
  QuickNoteCategory(
    name: 'Régimes & Allergies',
    notes: quickNotesDietary,
  ),
  QuickNoteCategory(
    name: 'Cuisson & Préparation',
    notes: quickNotesCooking,
  ),
  QuickNoteCategory(
    name: 'Modifications',
    notes: quickNotesModifications,
  ),
  QuickNoteCategory(
    name: 'Spécial',
    notes: quickNotesSpecial,
  ),
];

/// Toutes les notes rapides flattened pour accès rapide
final allQuickNotes = <QuickNote>[
  ...quickNotesDietary,
  ...quickNotesCooking,
  ...quickNotesModifications,
  ...quickNotesSpecial,
];
