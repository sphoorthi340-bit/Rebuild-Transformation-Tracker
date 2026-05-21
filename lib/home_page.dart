
import 'package:flutter/material.dart';

// 1. IMPORT ALL YOUR TAB/PAGE FILES
import 'dashboard_tab.dart';
import 'workouts_tab.dart';
import 'nutrition_tab.dart';
import 'progress_tab.dart';
import 'journal_tab.dart';
import 'glowup_tab.dart';
import 'schedule_tab.dart';
import 'mobility_tab.dart';
import 'settings_tab.dart'; // <-- 1. IMPORT THE NEW SETTINGS PAGE

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Tracks the selected tab on the bottom bar

  // --- 2. THIS IS YOUR NEW LIST OF 5 CORE TABS ---
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardTab(), // Index 0
    const WorkoutsTab(),  // Index 1
    const NutritionTab(), // Index 2
    const ProgressTab(),  // Index 3
    const JournalTab(),   // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // --- 3. HELPER TO NAVIGATE TO A NEW PAGE (for the drawer) ---
  void _navigateToPage(Widget page) {
    // Close the drawer first
    Navigator.pop(context);
    
    // We use push to navigate to a new screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Rebuild'),
        // The AppBar automatically adds the hamburger menu icon (≡)
        // when a Drawer is present.
      ),
      
      // --- 4. THE NEW SIDE DRAWER (HAMBURGER MENU) ---
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E), // Match theme
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange, // Use your accent color
              ),
              child: Text(
                'More Features',
                style: TextStyle(
                  color: Colors.black, // Dark text on light background
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Glowup Notes'),
              onTap: () => _navigateToPage(const GlowupTab()),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedule'),
              onTap: () => _navigateToPage(const ScheduleTab()),
            ),
            ListTile(
              leading: const Icon(Icons.self_improvement),
              title: const Text('Mobility'),
              onTap: () => _navigateToPage(const MobilityTab()),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _navigateToPage(const SettingsTab()),
            ),
          ],
        ),
      ),
      
      // The body is just the selected tab from our 5-item list
      body: _widgetOptions.elementAt(_selectedIndex),

      // --- 5. THE NEW, CLEAN 5-ITEM BOTTOM BAR ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // All styling is now handled by the theme in main.dart
      ),
    );
  }
}