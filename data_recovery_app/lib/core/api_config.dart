class ApiConfig {
  // Production server behind api.datarecovery-sa.com (nginx + Let's Encrypt).
  // Overwritten by start_ngrok.sh when a public tunnel is running.
  static const String publicUrl = 'https://api.datarecovery-sa.com';
  static const String apiBaseUrl = 'https://api.datarecovery-sa.com/api/';
}
