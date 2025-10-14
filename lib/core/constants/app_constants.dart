/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'DocSync Doctor';
  static const String appVersion = '1.0.0';

  // API & Database
  static const String supabaseUrl = ''; // Load from .env
  static const String supabaseAnonKey = ''; // Load from .env

  // Storage Buckets
  static const String profilePicturesBucket = 'profile_pictures';
  static const String prescriptionsBucket = 'prescriptions';
  static const String healthRecordsBucket = 'health_records';

  // Consultation Types
  static const String consultationTypeVideo = 'video';
  static const String consultationTypeAudio = 'audio';
  static const String consultationTypeChat = 'chat';

  // Consultation Status
  static const String consultationStatusScheduled = 'scheduled';
  static const String consultationStatusCompleted = 'completed';
  static const String consultationStatusCanceled = 'canceled';

  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';

  // Payment Methods
  static const String paymentBkash = 'bKash';
  static const String paymentNagad = 'Nagad';
  static const String paymentCreditCard = 'credit_card';
  static const String paymentDebitCard = 'debit_card';

  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';

  // Notification Types
  static const String notificationAppointment = 'appointment';
  static const String notificationReminder = 'reminder';
  static const String notificationFeedback = 'feedback';
  static const String notificationGeneral = 'general';

  // Date & Time Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int minPhoneLength = 10;
  static const int maxNameLength = 255;
  static const int maxBioLength = 1000;

  // Rating
  static const int minRating = 1;
  static const int maxRating = 5;

  // Consultation Duration
  static const int defaultConsultationDurationMinutes = 30;
  static const int maxConsultationDurationMinutes = 120;
}
