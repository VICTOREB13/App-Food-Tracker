import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/settings_controller.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/common/ve_card.dart';
import '../widgets/common/ve_logo.dart';
import '../widgets/settings/api_key_input_card.dart';
import '../widgets/settings/backup_card.dart';
import '../widgets/settings/daily_goals_card.dart';
import '../widgets/settings/database_maintenance_card.dart';
import '../widgets/settings/gemini_model_selector_card.dart';
import '../widgets/settings/usda_api_key_card.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = SettingsController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _showThemeSelector() {
    final manager = ThemeManager.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TEMA VISUAL',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Oscuro (Obsidian Zinc)'),
                leading: const Icon(Icons.dark_mode_outlined),
                trailing: manager.themeMode == ThemeMode.dark ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  manager.setThemeMode(ThemeMode.dark);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                title: const Text('Claro (Crisp Zinc)'),
                leading: const Icon(Icons.light_mode_outlined),
                trailing: manager.themeMode == ThemeMode.light ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  manager.setThemeMode(ThemeMode.light);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                title: const Text('Automático del Sistema'),
                leading: const Icon(Icons.brightness_auto_outlined),
                trailing: manager.themeMode == ThemeMode.system ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  manager.setThemeMode(ThemeMode.system);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.instance;

    return Scaffold(
      appBar: VeAppBar(
        title: 'Ajustes',
        subtitle: 'Configuración y Respaldo Local',
        actions: [
          IconButton(
            icon: Icon(
              themeManager.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () => themeManager.toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          ApiKeyInputCard(
            currentApiKey: _controller.geminiApiKey,
            onSaveApiKey: (key) async {
              await _controller.saveApiKey(key);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(key.isEmpty ? 'API Key eliminada' : 'API Key guardada de forma segura'),
                  backgroundColor: AppColors.protein,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          GeminiModelSelectorCard(
            apiKey: _controller.geminiApiKey,
            selectedModel: _controller.selectedGeminiModel,
            models: _controller.availableGeminiModels,
            isLoading: _controller.isLoadingModels,
            isOnline: _controller.isOnlineModels,
            onSelectModel: (model) async {
              await _controller.saveSelectedGeminiModel(model);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Modelo "$model" seleccionado para visión'),
                  backgroundColor: AppColors.protein,
                ),
              );
            },
            onRefresh: () => _controller.loadAvailableGeminiModels(forceRefresh: true),
          ),
          const SizedBox(height: 16),
          UsdaApiKeyCard(
            currentApiKey: _controller.usdaApiKey,
            onSaveApiKey: (key) async {
              await _controller.saveUsdaApiKey(key);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(key.isEmpty ? 'USDA API Key eliminada' : 'USDA API Key guardada de forma segura'),
                  backgroundColor: AppColors.protein,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          VeCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: Text(
                'Perfil Nutricional y Metas (Mifflin-St Jeor)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Parámetros biológicos, TDEE y Master Prompt',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DailyGoalsCard(
            initialGoals: _controller.dailyGoals,
            onSaveGoals: (goals) async {
              await _controller.saveDailyGoals(goals);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Metas nutricionales actualizadas con éxito'),
                  backgroundColor: AppColors.protein,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DatabaseMaintenanceCard(
            stats: _controller.dbStats,
            isLoading: _controller.isLoading,
            onOptimize: () async {
              await _controller.optimizeDatabase();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Base de datos SQLite optimizada (VACUUM ejecutado)'),
                  backgroundColor: AppColors.protein,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          BackupCard(
            onExport: () => _controller.exportBackup(),
            onImport: (json) => _controller.importBackup(json),
          ),
          const SizedBox(height: 16),
          VeCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
              title: Text(
                'Apariencia y Sistema de Diseño',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                themeManager.isDarkMode ? 'Modo Obsidian Zinc' : 'Modo Crisp Zinc',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _showThemeSelector,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const VeLogo(size: 36, borderRadius: 10),
                const SizedBox(height: 10),
                Text(
                  'Victor Engineer - Food Tracker v1.0.0\nArquitectura 100% Local-First & BYOK',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
