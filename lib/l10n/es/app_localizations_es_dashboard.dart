import 'app_localizations_es_core.dart';

abstract class AppLocalizationsEsDashboard extends AppLocalizationsEsCore {
  AppLocalizationsEsDashboard([super.locale = 'es']);

  @override String get dashboard => 'Panel Principal';
  @override String get breakfast => 'Desayuno';
  @override String get quickMeal => 'Comida rápida';
  @override String get quickMealTitle => 'Registro Rápido de Comida';
  @override String get fasting => 'Ayuno Intermitente';
  @override String get fastingWindow => 'Ventana de Ayuno';
  @override String get startFast => 'Comenzar Ayuno';
  @override String get endFast => 'Finalizar Ayuno';
  @override String get voiceDictation => 'Dictado por Voz';
  @override String get fastingCompletedTitle => '¡Ya terminó tu ayuno intermitente!';
  @override String fastingCompletedBody(String hours) => 'Cumpliste tu meta de $hours horas de ayuno. ¡Ya puedes comer!';
  @override String get analyzingMealBackground => '✨ Analizando comida en segundo plano. Puedes seguir usando la app.';
  @override String get quickHydrationNote => 'Hidratación rápida (+250 ml)';
  @override String get waterLoggedSuccess => '💧 +250 ml de agua registrados con éxito.';
  @override String waterLogError(String error) => 'Error al registrar agua: $error';
  @override String quickMealLogError(String error) => 'Error al registrar comida rápida: $error';
  @override String quickMealLoggedSuccess(String name, String calories) => '⚡ $name registrado ($calories kcal).';
  @override String get fabCameraTitle => 'Foto con IA';
  @override String get fabCameraSubtitle => 'Cámara Gemini 2.5';
  @override String get fabGalleryTitle => 'Galería';
  @override String get fabGallerySubtitle => 'Elegir del carrete';
  @override String get fabBarcodeTitle => 'Código Barras';
  @override String get fabBarcodeSubtitle => 'Open Food Facts';
  @override String get fabManualTitle => 'Manual';
  @override String get fabManualSubtitle => 'Despensa y macros';
  @override String get fabWaterTitle => '+250ml Agua';
  @override String get fabWaterSubtitle => 'Hidratación rápida';
  @override String get fabQuickTitle => 'Rápida';
  @override String get fabQuickSubtitle => 'Calorías directas';
  @override String get fabSectionHeader => 'REGISTRAR COMIDA O ACTIVIDAD';
  @override String get whatToEatTitle => '¿Qué debería comer hoy?';
  @override String get whatToEatSubtitle => 'Sugerencias inteligentes según tus macros';
  @override String get unclassifiedMeal => 'Comida sin clasificar';
  @override String get startFastingTitle => 'Iniciar Ayuno Intermitente';
  @override String get selectFastingProtocol => 'Selecciona tu protocolo de ayuno:';
  @override String get endFastingDialogTitle => '¿Terminar Ayuno?';
  @override String endFastingDialogBody(String duration) => 'Llevas $duration de ayuno. Se registrará la sesión en tu historial.';
  @override String get noActiveFast => '• Sin ayuno activo';
  @override String get noActiveFastTitle => 'Sin ayuno activo';
  @override String get quickMealNotesDefault => 'Registro rápido de comida';
  @override String get quickMealDescriptionLabel => 'Descripción / Alimento';
  @override String voiceMealAddedSuccess(String name) => 'Comida "$name" agregada por voz.';
  @override String get voiceDictationTitle => 'Dictado por Voz';
  @override String get voiceDictationInstruction => 'Describe tu plato con lenguaje natural. Gemini Vision extraerá ingredientes, porciones y macronutrientes.';
  @override String get whatToEatCombinations => 'Combinaciones para bajar grasas y alcanzar tus metas';
  @override String get flashFastTag => 'Flash (Rápidos)';
  @override String get fabVoiceTitle => 'Voz / Audio';
  @override String get fabVoiceSubtitle => 'Dictado natural';
  @override String get fabVideoTitle => 'Video Pan';
  @override String get fabVideoSubtitle => 'Muestreo 3D';
  @override String remainingFastDuration(String remaining, String total) => 'Restan $remaining de ${total}h';
  @override String get fastingStartTrackingPrompt => 'Inicia para dar seguimiento a tu ventana de comida';

  @override String dishRegisteredSuccess(String name) => '✨ "$name" registrada con éxito en tu día';
  @override String errorRegisteringMeal(String error) => 'Error al registrar comida: $error';
  @override String suggestionsForNextMeal(String mealType) => 'Sugerencias para tu próxima comida: $mealType';
  @override String get quickWaterMealName => 'Agua (+250 ml)';
}

