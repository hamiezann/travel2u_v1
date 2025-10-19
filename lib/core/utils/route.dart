import 'package:flutter/widgets.dart';
import 'package:travel2u_v1/presentation/auth/login.dart';
import 'package:travel2u_v1/presentation/auth/register.dart';
import 'package:travel2u_v1/presentation/customer/cdashboard.dart';
import 'package:travel2u_v1/presentation/staff/createOrEdit_travel_package.dart';
import 'package:travel2u_v1/presentation/staff/crud_taxonomy.dart';
import 'package:travel2u_v1/presentation/staff/manage_travel_page.dart';
import 'package:travel2u_v1/presentation/staff/sdashboard.dart';

class AppRoute {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String staffDashboard = '/staff/dashboard';
  static const String manageTravel = '/staff/manage-travel';
  static const String customerDashboard = '/customer/dashboard';
  static const String addTravelPackage = '/add-travel-package';
  static const String editTravelPackage = '/update-travel-package';
  static const String crudTaxonomy = '/crud-taxonomy';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    manageTravel: (context) => const ManageTravelPage(),
    customerDashboard: (context) => CDashboardPage(),
    staffDashboard: (context) => const SDashboardPage(),
    addTravelPackage: (context) => const CreateOrEditTravelPackagePage(),
    editTravelPackage: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      // print('Navigating to /update-travel-package with arguments: $args');
      final String? packageId = args['id'] as String?;
      // print('Extracted packageId: $packageId');
      return CreateOrEditTravelPackagePage(packageId: packageId);
    },
    crudTaxonomy: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final taxonomyType = args['taxonomyType'] as String;
      return CrudTaxonomyPage(taxonomyType: taxonomyType);
    },
  };
}
