import 'package:flutter/material.dart';

import '../models/app_update_info.dart';
import '../theme/sushi_design.dart';
import 'sushi_cta_button.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.updateInfo,
    required this.isBusy,
    required this.onDownload,
  });

  final String currentVersion;
  final AppUpdateInfo updateInfo;
  final bool isBusy;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(SushiSpace.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SushiRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(SushiSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: SushiColors.redSurface,
                      borderRadius: BorderRadius.circular(SushiRadius.md),
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: SushiColors.red,
                    ),
                  ),
                  const SizedBox(width: SushiSpace.md),
                  Expanded(
                    child: Text(
                      'Nouvelle version disponible',
                      style: SushiTypo.h2.copyWith(fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SushiSpace.lg),
              _VersionRow(label: 'Version actuelle', value: currentVersion),
              const SizedBox(height: SushiSpace.sm),
              _VersionRow(
                label: 'Version disponible',
                value: updateInfo.displayVersion,
              ),
              if ((updateInfo.installerName ?? '').isNotEmpty) ...[
                const SizedBox(height: SushiSpace.sm),
                _VersionRow(
                  label: 'Installateur',
                  value: updateInfo.installerName!,
                ),
              ],
              const SizedBox(height: SushiSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SushiSpace.md),
                decoration: BoxDecoration(
                  color: SushiColors.surface,
                  borderRadius: BorderRadius.circular(SushiRadius.md),
                  border: Border.all(color: SushiColors.divider),
                ),
                child: Text(
                  updateInfo.message,
                  style: SushiTypo.bodyMd.copyWith(color: SushiColors.ink),
                ),
              ),
              const SizedBox(height: SushiSpace.md),
              Text(
                'Le telechargement s ouvrira dans le navigateur. Ensuite, fermez l application puis lancez l installateur Windows.',
                style: SushiTypo.caption.copyWith(color: SushiColors.inkMid),
              ),
              const SizedBox(height: SushiSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Plus tard'),
                  ),
                  const SizedBox(width: SushiSpace.sm),
                  SushiCTAButton(
                    fullWidth: false,
                    icon: Icons.download_rounded,
                    onPressed: isBusy
                        ? () {}
                        : () async {
                            await onDownload();
                          },
                    child: Text(isBusy ? 'Ouverture...' : 'Mettre a jour'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: SushiTypo.bodyMd.copyWith(color: SushiColors.inkMid),
          ),
        ),
        const SizedBox(width: SushiSpace.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: SushiTypo.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
