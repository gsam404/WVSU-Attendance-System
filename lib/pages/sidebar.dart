import 'package:flutter/material.dart';
import './attendancepage.dart';
import './analyticspage.dart';
import './addAdmin.dart';

class SideBar extends StatefulWidget {
  final int selectedIndex;
  const SideBar({super.key, required this.selectedIndex});
  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  late int selectedIndex;
  bool isExpanded = true;
  bool isFullyExpanded = true;
  String name = 'Elra Di M.Madalogdog';
  String occupation = 'University Librarian';
  final sideBarItems = [
    {
      'icon': 'assets/dashboard.png',
      'title': 'Dashboard',
      'page': DashboardPage(),
    },
    {
      'icon': 'assets/analytics.png',
      'title': 'Analytics',
      'page': AnalyticsPage(),
    },
    {
      'icon': 'assets/attendance.png',
      'title': 'Attendance',
      'page': AttendancePage(),
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  void _toggleSidebar() {
    if (isExpanded) {
      setState(() {
        isExpanded = false;
        isFullyExpanded = false;
      });
    } else {
      setState(() => isExpanded = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => isFullyExpanded = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 402 : 80,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Rectangle.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Image.asset(
                          'assets/imageTwo.png',
                          width: 75,
                          height: 75,
                        ),
                        if (isFullyExpanded)
                          Text(
                            'WVSU LIBRARY ATTENDANCE',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 20.0,
                                ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  // TOGGLE BUTTON
                  Align(
                    alignment: isExpanded ? Alignment.centerRight : Alignment.center,
                    child: FloatingActionButton.small(
                      onPressed: _toggleSidebar,
                      backgroundColor: const Color.fromARGB(255, 30, 100, 190),
                      child: Icon(
                        isExpanded ? Icons.chevron_left : Icons.chevron_right,
                        color: Colors.white,
                      ),
                      ),
                    /*alignment: isExpanded ? Alignment.centerRight : Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.chevron_left : Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: _toggleSidebar,
                    ), */
                  ),

                  const SizedBox(height: 30),

                  // SIDEBAR ITEMS
                  ...sideBarItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return SideBarItems(
                      assetPath: item['icon'] as String,
                      title: item['title'] as String,
                      destination: item['page'] as Widget,
                      isSelected: selectedIndex == index,
                      isExpanded: isFullyExpanded,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => item['page'] as Widget),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),

            // PROFILE SECTION
            Padding(
              padding: EdgeInsets.only(
                  left: isFullyExpanded ? 20 : 0, bottom: 30),
              child: isFullyExpanded // 👈 use isFullyExpanded here too
                  ? ProfilePopUp(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 37,
                              backgroundColor: Colors.grey,
                              backgroundImage:
                                  const AssetImage('assets/profile.png'),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(name),
                                Text(
                                  occupation,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey,
                      backgroundImage: const AssetImage('assets/profile.png'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// basic Dashboard page placeholder for sidebar
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard content goes here')),
    );
  }
}

// SIDEBAR ITEMS
class SideBarItems extends StatelessWidget {
  final String assetPath;
  final String title;
  final Widget destination;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const SideBarItems({
    super.key,
    required this.assetPath,
    required this.title,
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 25.0 : 8.0,
        vertical: 8.0,
      ),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0x52FAF2F2),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        child: isExpanded
            ? ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12.0),
                leading: SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
                title: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 24.0),
                ),
                onTap: onTap,
              )
            : IconButton(
                icon: Image.asset(assetPath, width: 28, height: 28),
                iconSize: 32,
                onPressed: onTap,
                tooltip: title,
              ),
      ),
    );
  }
}