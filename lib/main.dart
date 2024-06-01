import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:food_pick_app/model/food_store.dart';
import 'package:food_pick_app/screen/detail_screen.dart';
import 'package:food_pick_app/screen/edit_screen.dart';
import 'package:food_pick_app/screen/login_screen.dart';
import 'package:food_pick_app/screen/main_screen.dart';
import 'package:food_pick_app/screen/register_screen.dart';
import 'package:food_pick_app/screen/search_address_screen.dart';
import 'package:food_pick_app/screen/search_result_screen.dart';
import 'package:food_pick_app/screen/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ankigaqnmxcombtzloxr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFua2lnYXFubXhjb21idHpsb3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTAyMTU5ODgsImV4cCI6MjAyNTc5MTk4OH0.0ImNrEfxaSfjd_gyvGn8O1HKLJlbeWrtQDmdBB9Ya38',
  );
  // init naver map
  await NaverMapSdk.instance.initialize(
    clientId: 'orm2tvx9b3',
    onAuthFailed: (ex) => print('네이버 맵 인증오류 : $ex'),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => MainScreen(),
        '/edit': (context) => EditScreen(),
        '/search_address': (context) => SearchAddressScreen(),
        // '/detail': (context) => DetailScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          FoodStoreModel foodStoreModel = settings.arguments as FoodStoreModel;
          return MaterialPageRoute(
            builder: (context) {
              return DetailScreen(foodStoreModel: foodStoreModel);
            },
          );
        } else if (settings.name == '/search_result') {
          // 검색 결과
          List<FoodStoreModel> lstFoodStore =
              settings.arguments as List<FoodStoreModel>;
          return MaterialPageRoute(
            builder: (context) {
              return SearchResultScreen(
                lstFoodStore: lstFoodStore,
              );
            },
          );
        }
      },
    );
  }
}
