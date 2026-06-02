import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

/// Dialog to show after successful user/delivery creation
/// Displays all details including the backend-generated PIN
class CreationSuccessDialog extends StatelessWidget {
  final String name;
  final String role;
  final String? phone;
  final String? email;
  final String pin;
  final bool isLivreur;

  const CreationSuccessDialog({
    super.key,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    required this.pin,
    this.isLivreur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, AppColors.deepTeal.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              '✅ Création réussie',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Name and role
            Text(
              '$name ($role)',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.grisModerne,
              ),
            ),
            const SizedBox(height: 24),

            // PIN Code - Most important!
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.burntOrange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.burntOrange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.burntOrange),
                      const SizedBox(width: 8),
                      Text(
                        'PIN généré',
                        style: TextStyle(
                          color: AppColors.burntOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pin,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppColors.charbon,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copy PIN button
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pin));
                Get.snackbar(
                  '✅ Copié',
                  'PIN copié dans le presse-papier',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier le PIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Other details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grisLeger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Détails',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (phone != null && phone!.isNotEmpty) ...[
                    _detailRow(Icons.phone, 'Téléphone', phone!),
                    const SizedBox(height: 8),
                  ],
                  if (email != null && email!.isNotEmpty) ...[
                    _detailRow(Icons.email, 'Email', email!),
                    const SizedBox(height: 8),
                  ],
                  _detailRow(
                    isLivreur ? Icons.local_shipping : Icons.badge,
                    'Rôle',
                    role,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notez ce PIN précieusement. Il sera nécessaire pour la connexion.',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Done button
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('J\'ai noté'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grisModerne),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.grisModerne,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
