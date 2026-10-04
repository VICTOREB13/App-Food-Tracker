$files = @(
  'android/app/src/main/res/layout/food_tracker_widget_wide.xml',
  'lib/assets/android_widgets/food_tracker_widget_wide.xml',
  'lib/models/pantry_item.dart',
  'lib/screens/dashboard_screen.dart',
  'lib/screens/metrics_screen.dart',
  'lib/screens/pantry_screen.dart',
  'lib/services/backup_normalizer.dart',
  'lib/services/backup_service.dart',
  'lib/services/daos/database_connection_factory.dart',
  'lib/services/daos/database_schema.dart',
  'lib/widgets/dashboard/dashboard_fab_menu.dart',
  'lib/widgets/dashboard/fasting_window_bento_card.dart',
  'lib/widgets/meal_detail/food_item_editor_dialog.dart',
  'lib/widgets/metrics/weekly_digest_card.dart',
  'lib/widgets/pantry/pantry_consumption_dialog.dart',
  'lib/widgets/pantry/pantry_item_editor_dialog.dart',
  'lib/widgets/recommendations/recommendation_diagnostic_card.dart',
  'lib/widgets/recommendations/what_to_eat_sheet.dart',
  'lib/widgets/settings/json_file_picker_dialog.dart',
  'pubspec.yaml',
  'test/models/pantry_item_portion_scaling_test.dart',
  'test/services/backup_normalizer_test.dart',
  'test/widgets/dashboard_fab_menu_test.dart',
  'test/widgets/fasting_window_bento_card_test.dart',
  'test/widgets/json_file_picker_dialog_test.dart',
  'test/widgets/pantry_consumption_dialog_test.dart',
  'test/widgets/pantry_item_editor_dialog_test.dart',
  'test/widgets/recommendations_widgets_test.dart',
  'test/widgets/weekly_digest_card_test.dart'
)

$results = foreach ($f in $files) {
  if (Test-Path $f) {
    $lines = (Get-Content $f).Length
    [PSCustomObject]@{ File = $f; Lines = $lines; Compliant = ($lines -lt 300) }
  } else {
    [PSCustomObject]@{ File = $f; Lines = 0; Compliant = $false }
  }
}

$results | Format-Table -AutoSize
$nonCompliant = $results | Where-Object { -not $_.Compliant }
Write-Host "Total non-compliant files: $($nonCompliant.Count)"
