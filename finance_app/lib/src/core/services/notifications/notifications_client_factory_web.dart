import 'notifications_client.dart';
import 'notifications_client_web.dart';

NotificationsClient createNotificationsClient() {
  return NotificationsClientWeb();
}