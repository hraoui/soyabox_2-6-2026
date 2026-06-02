import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../utils/quick_notes_constants.dart';
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
  String? _selectedQuickNote;
  String? _selectedCourseKey;
  int? _selectedGroupNumber;

  @override
  void initState() {
    super.initState();
    _customNoteController = TextEditingController();
    _selectedGroupNumber = widget.currentGroupNumber;
    // Détection automatique du cours (défaut: plat principal)
    _selectedCourseKey = serviceCourseMain.key;
  }

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  String? get _finalNote {
    if (_selectedQuickNote != null) return _selectedQuickNote;
    final custom = _customNoteController.text.trim();
    if (custom.isNotEmpty) return custom;
    return null;
  }

  void _submit() {
    Get.back(
      result: ItemOptionsResult(
        itemNote: _finalNote,
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

              // 📋 NOTES RAPIDES
              _buildSectionTitle('📝 Notes Rapides'),
              const SizedBox(height: 12),
              Column(
                children: quickNoteCategories.map((category) {
                  return _buildQuickNoteCategory(category);
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ✍️ NOTE PERSONNALISÉE
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
                onChanged: (_) {
                  if (_customNoteController.text.trim().isNotEmpty) {
                    setState(() => _selectedQuickNote = null);
                  }
                },
              ),
              const SizedBox(height: 24),

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

  Widget _buildQuickNoteCategory(QuickNoteCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: Text(
            category.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category.notes.map((note) {
            final selected = _selectedQuickNote == note.value;
            return _buildQuickNoteChip(note, selected);
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickNoteChip(QuickNote note, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFED7AA) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xFFF97316) : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedQuickNote = selected ? null : note.value;
            if (!selected) {
              _customNoteController.clear();
            }
          });
        },
        child: Text(
          note.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFFF97316) : Colors.grey[700],
          ),
        ),
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
