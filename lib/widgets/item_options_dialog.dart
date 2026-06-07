import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../utils/order_item_grouping.dart';

/// Options d'article avec notes et cours
class ItemOptionsResult {
  ItemOptionsResult({
    this.itemNote,
    this.serviceCourseKey,
    this.serviceCourseLabel,
    this.groupNumber,
    this.groupLabel,
  });

  final String? itemNote;
  final String? serviceCourseKey;
  final String? serviceCourseLabel;
  final int? groupNumber;
  final String? groupLabel;
}

/// Dialogue pour ajouter des notes rapides ou personnalisées
Future<ItemOptionsResult?> showItemOptionsDialog({
  required BuildContext context,
  required Product product,
  int? currentGroupNumber,
  String? currentGroupLabel,
  List<({int number, String label})>? availableGroups,
}) {
  return showDialog<ItemOptionsResult?>(
    context: context,
    builder: (context) => _ItemOptionsDialog(
      product: product,
      currentGroupNumber: currentGroupNumber,
      currentGroupLabel: currentGroupLabel,
      availableGroups: availableGroups,
    ),
  );
}

class _ItemOptionsDialog extends StatefulWidget {
  const _ItemOptionsDialog({
    required this.product,
    this.currentGroupNumber,
    this.currentGroupLabel,
    this.availableGroups,
  });

  final Product product;
  final int? currentGroupNumber;
  final String? currentGroupLabel;
  final List<({int number, String label})>? availableGroups;

  @override
  State<_ItemOptionsDialog> createState() => _ItemOptionsDialogState();
}

class _ItemOptionsDialogState extends State<_ItemOptionsDialog> {
  late final TextEditingController _customNoteController;
  String? _selectedCourseKey;
  int? _selectedGroupNumber;
  // Pinned notes (global)
  bool _pinNote = false;
  List<String> _pinnedNotes = [];

  @override
  void initState() {
    super.initState();
    _customNoteController = TextEditingController();
    _selectedGroupNumber = widget.currentGroupNumber;
    // Ne pas présélectionner le type de plat — le serveur choisira
    _selectedCourseKey = null;
    _pinNote = false;
    _loadPinnedNotes();
  }

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  String? get _finalNote {
    final custom = _customNoteController.text.trim();
    if (custom.isNotEmpty) return custom;
    return null;
  }

  Future<void> _submit() async {
    // Save pinned note if requested
    final note = _finalNote;
    if (_pinNote && note != null) {
      await _savePinnedNoteForScope(note);
    }

    Get.back(
      result: ItemOptionsResult(
        itemNote: note,
        serviceCourseKey: _selectedCourseKey,
        groupNumber: _selectedGroupNumber,
        groupLabel: _selectedGroupNumber != null
            ? widget.availableGroups
                ?.firstWhere(
                  (g) => g.number == _selectedGroupNumber,
                  orElse: () => (number: _selectedGroupNumber!, label: 'Ensemble $_selectedGroupNumber'),
                )
                .label
            : null,
      ),
    );
  }

  // ----- Pinned notes storage (SharedPreferences) -----
  String _prefsKeyForScope() => 'pinned_notes_global';

  Future<void> _loadPinnedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyForScope();
    final list = prefs.getStringList(key) ?? <String>[];
    setState(() => _pinnedNotes = list);
  }

  Future<void> _savePinnedNoteForScope(String note) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyForScope();
    final list = prefs.getStringList(key) ?? <String>[];
    if (!list.contains(note)) {
      list.insert(0, note);
      if (list.length > 50) list.removeRange(50, list.length);
      await prefs.setStringList(key, list);
    }
    await _loadPinnedNotes();
  }

  Future<void> _removePinnedNoteForScope(String note) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyForScope();
    final list = prefs.getStringList(key) ?? <String>[];
    list.remove(note);
    await prefs.setStringList(key, list);
    await _loadPinnedNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔝 TITRE
              Text(
                '${widget.product.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personnalisez votre commande',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // ✍️ NOTE PERSONNALISÉE (champ libre — plus de suggestions)
              _buildSectionTitle('✏️ Note Personnalisée'),
              const SizedBox(height: 8),
              TextField(
                controller: _customNoteController,
                decoration: InputDecoration(
                  hintText: 'Allergies, préférences, modifications...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFF97316),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Option d'épinglage (global)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _pinNote,
                    onChanged: (v) => setState(() => _pinNote = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  const Text('Épingler'),
                ],
              ),
              const SizedBox(height: 12),

              // Afficher les notes épinglées pour l'utilisateur sélectionné
              if (_pinnedNotes.isNotEmpty) ...[
                _buildSectionTitle('📌 Notes épinglées'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pinnedNotes.map((note) {
                      return InputChip(
                        label: Text(note, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _customNoteController.text = note;
                          setState(() {});
                        },
                        onDeleted: () => _removePinnedNoteForScope(note),
                      );
                    }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // 🍽️ TYPE DE PLAT / COURS
              _buildSectionTitle('🍽️ Type de Plat'),
              const SizedBox(height: 12),
              _buildServiceCourseButtons(),
              const SizedBox(height: 24),

              // 👥 GROUPE/ENSEMBLE (si sur place)
              if (widget.availableGroups != null && widget.availableGroups!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('👥 Groupe/Ensemble'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildGroupChip(
                          label: 'Sans groupe',
                          selected: _selectedGroupNumber == null,
                          onSelected: (isSelected) {
                            setState(() {
                              _selectedGroupNumber = isSelected ? null : _selectedGroupNumber;
                            });
                          },
                          color: Colors.grey,
                        ),
                        ...widget.availableGroups!.map((group) {
                          final selected = _selectedGroupNumber == group.number;
                          return _buildGroupChip(
                            label: group.label,
                            selected: selected,
                            onSelected: (isSelected) {
                              setState(() {
                                _selectedGroupNumber = isSelected ? group.number : null;
                              });
                            },
                            color: _groupChipColor(group.number),
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // 🔘 BOUTONS D'ACTION
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ajouter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildServiceCourseButtons() {
    final courses = [
      serviceCourseStarter,
      serviceCourseMain,
      serviceCourseCheese,
      serviceCourseDessert,
      serviceCourseDrink,
      serviceCourseOther,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: courses.map((course) {
        final selected = _selectedCourseKey == course.key;
        return _buildCourseButton(course, selected);
      }).toList(),
    );
  }

  Widget _buildCourseButton(ServiceCourseDescriptor course, bool selected) {
    final colorMap = {
      'starter': const Color(0xFF10B981),
      'main': const Color(0xFF3B82F6),
      'cheese': const Color(0xFFF59E0B),
      'dessert': const Color(0xFFEC4899),
      'drink': const Color(0xFF8B5CF6),
      'other': const Color(0xFF6B7280),
    };

    final bgColor = colorMap[course.key] ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCourseKey = selected ? null : course.key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? bgColor : bgColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: bgColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: bgColor.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          course.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : bgColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(200) : color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : color.withAlpha(60),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Color _groupChipColor(int groupNumber) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
    ];
    return colors[groupNumber % colors.length];
  }
}
