/// Firebase Storage Spark planında kullanılamadığı için
/// bu servis şimdilik devre dışıdır.
/// Blaze planına geçildiğinde firebase_storage paketi
/// tekrar eklenip bu dosya güncellenebilir.
class StorageService {
  /// Profil fotoğrafı yükleme — şimdilik devre dışı.
  Future<String?> uploadProfilePicture({
    required String userEmail,
    required dynamic imageFile,
  }) async {
    return null; // Storage aktif değil
  }

  /// Sohbet resmi yükleme — şimdilik devre dışı.
  Future<String?> uploadChatImage({
    required String chatRoomId,
    required dynamic imageFile,
  }) async {
    return null; // Storage aktif değil
  }
}
