/// Defines how meal images and exports are stored on the device.
enum StorageMode {
  /// Images are saved to public media directory (/Pictures/FoodTracker),
  /// visible in system gallery and file managers.
  public,

  /// Images are isolated in the app's private documents directory,
  /// hidden from public media galleries.
  private;

  static StorageMode fromString(String? value) {
    if (value == 'private') return StorageMode.private;
    return StorageMode.public;
  }
}
