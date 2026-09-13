import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/audit_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/master_data_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/public_data_provider.dart';
import 'presentation/providers/register_provider.dart';
import 'presentation/providers/sector_dashboard_provider.dart';
import 'presentation/providers/sos_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_management_provider.dart';
import 'presentation/screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local (high-visibility) notification layer always initializes.
  await NotificationService.instance.initialize();

  runApp(const MJCCApp());
}

class MJCCApp extends StatelessWidget {
  const MJCCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => MasterDataProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => AuditProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => PublicDataProvider()),
        ChangeNotifierProvider(create: (_) => SectorDashboardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'MJCC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
