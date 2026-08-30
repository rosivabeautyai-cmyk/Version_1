import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/ai_config_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../provider/admin_config_provider.dart';

/// Admin switches for the ROSIVA AI assistant (`app_config/ai`).
///
/// Enforcement is the backend's job — it reads this same document and
/// refuses requests when the assistant is off or in maintenance. This
/// screen only writes the document.
class AdminAiControlsScreen extends StatelessWidget {
  const AdminAiControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => AdminConfigProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text(lang.adminAiControls)),
        body: const SafeArea(child: _Body()),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _msgEn = TextEditingController();
  final _msgAr = TextEditingController();
  final _globalLimit = TextEditingController();
  final _userLimit = TextEditingController();
  bool _seededControllers = false;
  bool _busy = false;

  @override
  void dispose() {
    _msgEn.dispose();
    _msgAr.dispose();
    _globalLimit.dispose();
    _userLimit.dispose();
    super.dispose();
  }

  void _seed(AiConfig cfg) {
    if (_seededControllers) return;
    _msgEn.text = cfg.maintenanceMessageEn;
    _msgAr.text = cfg.maintenanceMessageAr;
    _globalLimit.text = cfg.dailyGlobalLimit?.toString() ?? '';
    _userLimit.text = cfg.dailyUserLimit?.toString() ?? '';
    _seededControllers = true;
  }

  Future<void> _update(
    AdminConfigProvider provider, {
    bool? enabled,
    bool? maintenanceMode,
    bool saveMessages = false,
    bool saveLimits = false,
  }) async {
    final lang = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await provider.repository.updateAiConfig(
        enabled: enabled,
        maintenanceMode: maintenanceMode,
        maintenanceMessageEn: saveMessages ? _msgEn.text.trim() : null,
        maintenanceMessageAr: saveMessages ? _msgAr.text.trim() : null,
        dailyGlobalLimit: saveLimits
            ? _parseLimit(_globalLimit.text)
            : AdminRepository.unset,
        dailyUserLimit: saveLimits
            ? _parseLimit(_userLimit.text)
            : AdminRepository.unset,
      );
      if (mounted) SnackbarService.success(context, lang.adminSaved);
    } catch (_) {
      if (mounted) SnackbarService.error(context, lang.adminSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int? _parseLimit(String raw) {
    final n = int.tryParse(raw.trim());
    return (n != null && n > 0) ? n : null; // blank / 0 / invalid -> unlimited
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<AdminConfigProvider>();
    final cfg = provider.aiConfig;
    _seed(cfg);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(lang.adminAiControlsSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(lang.adminAiBackendAuthorityNote,
                    style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(lang.adminAiEnabled),
          subtitle: Text(lang.adminAiEnabledDesc),
          value: cfg.enabled,
          onChanged: _busy
              ? null
              : (v) => _update(provider, enabled: v),
        ),
        SwitchListTile(
          title: Text(lang.adminAiMaintenance),
          subtitle: Text(lang.adminAiMaintenanceDesc),
          value: cfg.maintenanceMode,
          onChanged: _busy
              ? null
              : (v) => _update(provider, maintenanceMode: v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _msgEn,
          maxLines: 2,
          decoration: InputDecoration(labelText: lang.adminAiMaintenanceMsgEn),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _msgAr,
          maxLines: 2,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(labelText: lang.adminAiMaintenanceMsgAr),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _update(provider, saveMessages: true),
          child: Text(lang.adminSave),
        ),
        const Divider(height: 40),
        Text(lang.adminAiLimitsBackendNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(
          controller: _globalLimit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: lang.adminAiDailyGlobalLimit,
            helperText: lang.adminAiDailyGlobalLimitDesc,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _userLimit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: lang.adminAiDailyUserLimit,
            helperText: lang.adminAiDailyUserLimitDesc,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: _busy ? null : () => _update(provider, saveLimits: true),
          child: Text(lang.adminSave),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
