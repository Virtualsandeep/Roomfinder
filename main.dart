import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/app_services.dart';
import 'screens/auth.dart';
import 'screens/customer.dart';
import 'screens/landlord.dart';

Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform); runApp(const App());}
class App extends StatelessWidget {const App({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'KothaFinder Nepal',theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF3156D3),scaffoldBackgroundColor:const Color(0xFFF7F8FC)),home:StreamBuilder(stream:auth.authStateChanges(),builder:(c,s)=>s.data==null?const AuthScreen():RoleGate(userId:s.data!.uid));}}
class RoleGate extends StatelessWidget {final String userId; const RoleGate({super.key,required this.userId}); @override Widget build(BuildContext c)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:db.collection('users').doc(userId).snapshots(),builder:(c,s){final role=s.data?.data()?['role']; if(role=='landlord')return const LandlordHome(); return CustomerHome(needsRole:role==null);});}
