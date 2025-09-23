import 'notifications_client.dart';
import 'notifications_client_mobile.dart';

NotificationsClient createNotificationsClient() {
  return NotificationsClientMobile();
}