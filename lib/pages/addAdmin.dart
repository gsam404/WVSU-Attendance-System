import 'package:flutter/material.dart';

// --- PROFILE POPUP WIDGET ---
class ProfilePopUp extends StatelessWidget {
  final Widget child;
  const ProfilePopUp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PopupMenuButton<String>(
        offset: const Offset(35, -270),
        color: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        constraints: const BoxConstraints(minHeight: 252),
        onSelected: (value) {
          if (value == 'add_admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
            );
          } else if (value == 'logOut') {
            // Log out logic here
          }
        },
        child: child,
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Elra Di M. Madalogdog',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.black,
                                fontSize: 14.0,
                              ),
                        ),
                        Text(
                          'University Librarian',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontSize: 11.0,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            enabled: false,
            height: 1,
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Divider(color: Colors.grey),
          ),
          PopupMenuItem<String>(
            value: 'add_admin',
            child: Row(
              children: [
                Image.asset('assets/userAdd.png', width: 24, height: 24),
                const SizedBox(width: 12),
                Text(
                  'Add Admin',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                        fontSize: 20.0,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'logOut',
            child: Row(
              children: [
                Image.asset('assets/logOut.png', width: 24, height: 24),
                const SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Colors.red,
                        fontSize: 20.0,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ADMIN MANAGEMENT SCREEN ---
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final List<Map<String, String>> _admins = [];
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _emailError;
  String? _campusError;
  String? _selectedCampus;
  String _searchQuery = "";

  final List<Color> _avatarColors = [
    const Color(0xFF3B82F6),
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
  ];

  final List<String> _campuses = [
    'Main - Campus',
    'Calinog - Campus',
    'Lambunao - Campus',
    'Janiuay - Campus',
    'Pototan - Campus',
    'Himamaylan - Campus'
  ];

  void _addAdmin() {
    setState(() {
      _emailError = null;
      _campusError = null;
    });

    final email = _emailController.text.trim();

    if (email.isNotEmpty && !email.endsWith('@wvsu.edu.ph')) {
      setState(() => _emailError = "Acceptable WVSU Email: @wvsu.edu.ph");
      return;
    }

    if (_selectedCampus == null) {
      setState(() => _campusError = "Please select a campus.");
      return;
    }

    bool alreadyHasLibrarian = _admins.any((admin) => admin['role'] == _selectedCampus);
    if (alreadyHasLibrarian) {
      setState(() => _campusError = "This campus already has an assigned librarian.");
      return;
    }

    if (_firstNameController.text.isNotEmpty && email.isNotEmpty) {
      setState(() {
        int colorIdx = DateTime.now().millisecondsSinceEpoch % _avatarColors.length;
        _admins.add({
          'name': 'Dr. ${_firstNameController.text} ${_lastNameController.text}',
          'email': email,
          'role': _selectedCampus!,
          'colorIndex': colorIdx.toString(),
        });
        
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _selectedCampus = null;
      });
    }
  }

  void _showEditDialog(int index) {
    final nameCtrl = TextEditingController(text: _admins[index]['name']);
    final emailCtrl = TextEditingController(text: _admins[index]['email']);
    String? editSelectedCampus = _admins[index]['role'];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Necessary to show error messages inside the dialog
          builder: (context, setDialogState) {
            String? dialogEmailError;
            String? dialogCampusError;

            return AlertDialog(
              title: const Text("Edit Administrator"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl, 
                      decoration: const InputDecoration(labelText: "Full Name")
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailCtrl, 
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        errorText: dialogEmailError,
                      )
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: editSelectedCampus,
                      items: _campuses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setDialogState(() => editSelectedCampus = val),
                      decoration: InputDecoration(
                        labelText: "Assign Campus",
                        errorText: dialogCampusError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancel")
                ),
                ElevatedButton(
                  onPressed: () {
                    // Check if new campus is already taken by someone ELSE
                    bool isTaken = _admins.asMap().entries.any((entry) => 
                      entry.key != index && entry.value['role'] == editSelectedCampus);
                    
                    if (!emailCtrl.text.endsWith('@wvsu.edu.ph')) {
                      setDialogState(() => dialogEmailError = "Must be @wvsu.edu.ph");
                    } else if (isTaken) {
                      setDialogState(() => dialogCampusError = "Campus already assigned.");
                    } else {
                      setState(() {
                        _admins[index]['name'] = nameCtrl.text;
                        _admins[index]['email'] = emailCtrl.text;
                        _admins[index]['role'] = editSelectedCampus!;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile updated successfully!"), 
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to remove ${_admins[index]['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _admins.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _admins.where((admin) =>
        admin['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/blue_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFD6D6D6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                  const Text("Administrator Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add new admins, manage existing roles, transfer system ownership.", style: TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 25),
                    _buildCard(
                      title: "Add New University Librarian",
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildTextField("First name", "e.g. Juan", _firstNameController),
                              const SizedBox(width: 20),
                              _buildTextField("Last name", "e.g. Dela Cruz", _lastNameController),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField("Email Address", "name@wvsu.edu.ph", _emailController, errorText: _emailError),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Role Assignment in", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCampus,
                                      decoration: _inputDecoration("e.g. Calinog Campus", errorText: _campusError),
                                      items: _campuses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) => setState(() => _selectedCampus = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _addAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B36C2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              ),
                              child: const Text("Add Administrator", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildCard(
                      title: "University Librarians List",
                      subtitle: "View, edit, or remove administrative access for each university library.",
                      headerWidget: Container(
                        width: 220,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFFCDE4F7), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(hintText: "Search by name", border: InputBorder.none, isCollapsed: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          const Row(
                            children: [
                              Expanded(flex: 4, child: Text("User Profile", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 3, child: Text("Role Assigned in", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text("Actions", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                          const Divider(height: 25),
                          filteredAdmins.isEmpty
                              ? const Padding(padding: EdgeInsets.all(40), child: Text("No administrators found.", style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredAdmins.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final admin = filteredAdmins[index];
                                    final firstLetter = admin['email']!.isNotEmpty ? admin['email']![0].toUpperCase() : "?";
                                    final colorIdx = int.parse(admin['colorIndex'] ?? "0");

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: _avatarColors[colorIdx % _avatarColors.length],
                                                  child: Text(firstLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(admin['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                      Text(admin['email']!, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, decoration: TextDecoration.underline)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(flex: 3, child: Text(admin['role']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _showEditDialog(index)),
                                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(index)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, String? subtitle, required Widget child, Widget? headerWidget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), if (headerWidget != null) headerWidget]),
          if (subtitle != null) ...[const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))],
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {String? errorText}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: controller, decoration: _inputDecoration(hint, errorText: errorText)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}