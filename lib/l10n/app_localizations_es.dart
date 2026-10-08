import 'app_localizations.dart';

/// Spanish localizations for NutriTracker.
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([super.locale = 'es']);

  @override
  String get appTitle => 'Victor Engineer - Food Tracker';
  @override
  String get dashboard => 'Panel Principal';
  @override
  String get metrics => 'Métricas';
  @override
  String get settings => 'Ajustes';
  @override
  String get profile => 'Perfil';
  @override
  String get calories => 'Calorías';
  @override
  String get protein => 'Proteína';
  @override
  String get carbs => 'Carbohidratos';
  @override
  String get fat => 'Grasa';
  @override
  String get breakfast => 'Desayuno';
  @override
  String get lunch => 'Almuerzo';
  @override
  String get dinner => 'Cena';
  @override
  String get snack => 'Snack';
  @override
  String get other => 'Otro';
  @override
  String get save => 'Guardar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Eliminar';
  @override
  String get edit => 'Editar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get saveAndStart => 'Guardar y Comenzar';
  @override
  String get back => 'Atrás';
  @override
  String get continueButton => 'Continuar';
  @override
  String get quickMeal => 'Comida rápida';
  @override
  String get quickMealTitle => 'Registro Rápido de Comida';
  @override
  String get streak => 'Racha';
  @override
  String get days => 'días';
  @override
  String get weight => 'Peso';
  @override
  String get targetCalories => 'Calorías Objetivo';
  @override
  String get targetProtein => 'Proteína Objetivo';
  @override
  String get targetCarbs => 'Carbohidratos Objetivo';
  @override
  String get targetFat => 'Grasa Objetivo';
  @override
  String get dailySummary => 'Resumen del Día';
  @override
  String get consumed => 'Consumido';
  @override
  String get remaining => 'Restante';
  @override
  String get addMeal => 'Agregar Comida';
  @override
  String get recordWeight => 'Registrar Peso';
  @override
  String get scanBarcode => 'Escanear Código de Barras';
  @override
  String get takePhoto => 'Tomar Foto';
  @override
  String get chooseGallery => 'Elegir de Galería';
  @override
  String get apiKeyConfig => 'Configuración de API Key';
  @override
  String get apiKeyPrompt => 'Ingresa tu API Key de Google Gemini';
  @override
  String get databaseMaintenance => 'Mantenimiento de Base de Datos';
  @override
  String get optimizeDatabase => 'Optimizar Base de Datos';
  @override
  String get backupAndRestore => 'Copia de Seguridad y Restauración';
  @override
  String get exportBackup => 'Exportar Copia';
  @override
  String get importBackup => 'Importar Copia';
  @override
  String get themeMode => 'Tema Visual';
  @override
  String get themeSystem => 'Sistema';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';
  @override
  String get photoRetention => 'Retención de Fotos';
  @override
  String get noMealsToday => 'No hay comidas registradas para este día';
  @override
  String get noWeightLogs => 'No hay registros de peso aún';
  @override
  String get onboardingTitle => 'Bienvenido a NutriTracker';
  @override
  String get onboardingSubtitle =>
      'Tu asistente inteligente de nutrición y composición corporal';
  @override
  String get calculateNeeds => 'Calcular Requerimientos';
  @override
  String get age => 'Edad';
  @override
  String get gender => 'Género';
  @override
  String get genderMale => 'Masculino';
  @override
  String get genderFemale => 'Femenino';
  @override
  String get height => 'Altura';
  @override
  String get activityLevel => 'Nivel de Actividad';
  @override
  String get bodyGoal => 'Objetivo Corporal';
  @override
  String get bmr => 'Tasa Metabólica Basal';
  @override
  String get tdee => 'Gasto Energético Total Diario';
  @override
  String get fiber => 'Fibra';
  @override
  String get sodium => 'Sodio';
  @override
  String get sugar => 'Azúcar';
  @override
  String get fasting => 'Ayuno Intermitente';
  @override
  String get fastingWindow => 'Ventana de Ayuno';
  @override
  String get startFast => 'Comenzar Ayuno';
  @override
  String get endFast => 'Finalizar Ayuno';
  @override
  String get weeklyDigest => 'Resumen Semanal';
  @override
  String get clinicalReport => 'Reporte Clínico';
  @override
  String get calibratedDishware => 'Calibración de Vajilla';
  @override
  String get myPantry => 'Mi Despensa';
  @override
  String get voiceDictation => 'Dictado por Voz';
  @override
  String get language => 'Idioma';
  @override
  String get spanish => 'Español';
  @override
  String get english => 'Inglés';
  @override
  String remainingCalories(String count) => '$count restantes';
  @override
  String overCalories(String count) => '+$count exceso';
  @override
  String get today => 'Hoy';
  @override
  String get yesterday => 'Ayer';
  @override
  String get tomorrow => 'Mañana';
  @override
  String get previousDayTooltip => 'Día anterior';
  @override
  String get nextDayTooltip => 'Día siguiente';
  @override
  String get goToTodayTooltip => 'Ir a hoy';
  @override
  String get noMealsForSection => 'Sin registros en esta comida.';
  @override
  String addToMealSection(String mealType) => 'Añadir a $mealType';
  @override
  String get mealDetails => 'Detalle de Comida';
  @override
  String get newMeal => 'Nueva Comida';
  @override
  String get deleteMealTooltip => 'Eliminar comida';
  @override
  String get dishNameLabel => 'Nombre del plato *';
  @override
  String get dishNameHint => 'Ej. Pechuga a la plancha con arroz';
  @override
  String get mealTypeLabel => 'Tipo de Comida';
  @override
  String get notesLabel => 'Notas / Observaciones';
  @override
  String get notesHint => 'Ej. Se usó poco aceite en sofrito, porción mediana';
  @override
  String get inspectMeal => 'Inspeccionar comida';
  @override
  String get changePhoto => 'Cambiar foto';
  @override
  String get takePhotoAction => 'Tomar foto';
  @override
  String get noMealImage => 'Sin imagen del plato';
  @override
  String get saving => 'Guardando...';
  @override
  String get updateMeal => 'Actualizar Comida';
  @override
  String get registerMeal => 'Registrar Comida';
  @override
  String get addManualIngredient => 'Añadir ingrediente manual';
  @override
  String get editIngredient => 'Editar ingrediente';
  @override
  String get deleteIngredient => 'Eliminar ingrediente';
  @override
  String get gramsLabel => 'Gramos';
  @override
  String get estimationLabel => 'Estimación';
  @override
  String get reanalyzeWithAi => 'Re-analizar con correcciones';
  @override
  String get reanalyzingAi => 'Re-analizando con IA...';
  @override
  String get analysisStageOptimizing => 'Optimizando foto y calibración de vajilla...';
  @override
  String get analysisStageConnecting => 'Conectando de forma segura con Gemini Vision...';
  @override
  String get analysisStageVolumetric => 'Estimando geometría 3D y cubicaje volumétrico...';
  @override
  String get analysisStageDensities => 'Deduciendo densidades y grasas/aceites ocultos...';
  @override
  String get analysisStageMacros => 'Desglose nutricional y cruce con macronutrientes...';
  @override
  String get analysisStageComplete => '¡Desglose nutricional completado!';
  @override
  String updateAvailable(String version) => 'Nueva versión disponible: $version';
  @override
  String get viewUpdateAction => 'Ver actualización';
  @override
  String get mealAnalysisSuccessTitle => '¡Ya se terminó de analizar tu comida!';
  @override
  String mealAnalysisSuccessBody(String dishName, String calories) => 'Plato: $dishName (~$calories kcal). ¡Toca para ver el desglose!';
  @override
  String get mealAnalysisErrorTitle => 'Falló el análisis del alimento';
  @override
  String get fastingCompletedTitle => '¡Ya terminó tu ayuno intermitente!';
  @override
  String fastingCompletedBody(String hours) => 'Cumpliste tu meta de $hours horas de ayuno. ¡Ya puedes comer!';
  @override
  String get storageModeTitle => 'Almacenamiento de Fotos';
  @override
  String get storageModePublic => 'Público (Galería)';
  @override
  String get storageModePrivate => 'Privado (Aislado)';
  @override
  String exportSavedInFolder(String folder) => 'Se guardó en $folder';
  @override
  String get exportFormatLabel => 'Formato del reporte';
  @override
  String get exportFormatCsv => 'CSV (Excel)';
  @override
  String get exportFormatPdf => 'PDF Clínico';
  @override
  String get clinicalReportTitle => 'Reporte Clínico';
  @override
  String get clinicalExportDesc => 'Exporta tu historial nutricional tabulado con macros, fibra, sodio y azúcar para tu consulta clínica o nutricionista.';
  @override
  String get timeRangeLabel => 'Rango temporal:';
  @override
  String get exportSuccessTitle => 'Reporte generado con éxito';
  @override
  String get exportCsvButton => 'Exportar CSV';
  @override
  String get exportPdfButton => 'Exportar PDF';
  @override
  String get closeButton => 'Cerrar';
  @override
  String get storageModeSubtitle => 'Define la privacidad de las fotos capturadas';
  @override
  String get storageModePublicDesc => 'Visible en Galería y fotos del sistema (/Pictures)';
  @override
  String get storageModePrivateDesc => 'Almacenamiento interno de la app (protegido)';
  @override
  String get storageModePublicSnackBar => 'Modo Público activado: fotos visibles en Galería';
  @override
  String get storageModePrivateSnackBar => 'Modo Privado activado: fotos aisladas dentro de la app';
  @override
  String get mealAnalysisErrorFallback => 'No se pudo conectar con el servicio de visión. Toca para reintentar.';
}
