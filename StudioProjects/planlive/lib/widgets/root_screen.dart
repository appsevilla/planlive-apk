import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // <- IMPORTAR RIVERPOD

import 'package:planlive/screens/login_screen.dart';
import 'package:planlive/screens/explore_screen.dart';
import 'package:planlive/screens/comunidad_screen.dart';
import 'package:planlive/screens/global_chat_screen.dart';
import 'package:planlive/screens/create_plan_screen.dart';
import 'package:planlive/widgets/menu_screen.dart';
import 'package:planlive/screens/user_plans_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class RootScreen extends ConsumerStatefulWidget { // <- Cambiado a ConsumerStatefulWidget
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> { // <- ConsumerState
  int _selectedIndex = 1;

  final List<Widget> _screens = [
    const UserPlansScreen(),
    const ExploreScreen(),
    const ComunidadScreen(),
    const GlobalChatScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      // Pasamos ref aquí al menú para que acceda a Riverpod
      MenuScreen.show(context, ref);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 1) {
      setState(() {
        _selectedIndex = 1;
      });
      return false; // No salgas, solo cambia tab
    }
    return true; // Salir normalmente
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      return const LoginScreen();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _screens[_selectedIndex],

        floatingActionButton: _selectedIndex != 3
            ? Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePlanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Crear plan',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.9),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.deepPurpleAccent.shade700),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        )
            : null,

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Mis planes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Comunidad',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menú',
            ),
          ],
        ),
      ),
    );
  }
}
