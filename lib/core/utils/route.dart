import 'package:flutter/widgets.dart';
import 'package:travel2u_v1/presentation/auth/login.dart';
import 'package:travel2u_v1/presentation/auth/register.dart';
import 'package:travel2u_v1/presentation/customer/booking_detail_page.dart';
import 'package:travel2u_v1/presentation/customer/booking_index_page.dart';
import 'package:travel2u_v1/presentation/customer/cdashboard.dart';
import 'package:travel2u_v1/presentation/customer/chat_page.dart';
import 'package:travel2u_v1/presentation/staff/createOrEdit_travel_package.dart';
import 'package:travel2u_v1/presentation/staff/crud_taxonomy.dart';
import 'package:travel2u_v1/presentation/staff/manage_activity_page.dart';
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
  static const String bookingPage = '/booking-page';
  static const String customerChatPage = '/chat-customer';
  static const String staffManageBookingPage = '/staff/manage-booking';
  static const String customerBookingDetailPage = '/customer/booking-detail';
  static const String customerBookingStatusPage = '/customer/booking-status';

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
      final String? packageId = args['id'] as String?;
      return CreateOrEditTravelPackagePage(packageId: packageId);
    },
    crudTaxonomy: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final taxonomyType = args['taxonomyType'] as String;
      return CrudTaxonomyPage(taxonomyType: taxonomyType);
    },
    bookingPage: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final String packageId = args['packageId'] as String;
      return BookingPage(packageId: packageId);
    },
    customerBookingDetailPage: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final Map<String, dynamic> packageData =
          args['packageData'] as Map<String, dynamic>;
      final Map<String, dynamic> bookingData =
          args['bookingData'] as Map<String, dynamic>;
      return BookingDetailPage(
        packageData: packageData,
        bookingData: bookingData,
      );
    },
    customerBookingStatusPage: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final Map<String, dynamic> packageData =
          args['packageData'] as Map<String, dynamic>;
      final Map<String, dynamic> bookingData =
          args['bookingData'] as Map<String, dynamic>;
      return BookingDetailPage(
        packageData: packageData,
        bookingData: bookingData,
      );
    },
    customerChatPage: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final String packageId = args['packageId'] as String;
      final String bookingId = args['bookingId'] as String;
      final String userId = args['userId'] as String;
      final String supportId = args['supportId'] as String;
      return ChatPage(
        bookingId: bookingId,
        userId: userId,
        packageId: packageId,
        supportId: supportId,
      );
    },
    staffManageBookingPage: (context) => const ManageActivityPage(),
  };
}
