import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './adminSession.dart';

const String _apiUrl = "http://192.168.1.3/libgate_api/manage_admins.php";

class ProfilePopUp extends StatelessWidget {
  final Widget child;

  const ProfilePopUp({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(35, -270),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      constraints: const BoxConstraints(minHeight: 252),
      onSelected: (value) {
        if (value == 'add_admin') {
          if (AdminSession.role == 'main_admin') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManagementScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Access denied. Only the Main Admin can manage administrators."),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (value == 'logOut') {
          AdminSession.clear();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1B36C2),
                  backgroundImage: AdminSession.profilePicUrl.isNotEmpty
                      ? NetworkImage(AdminSession.profilePicUrl)
                      : null,
                  child: AdminSession.profilePicUrl.isEmpty
                      ? Text(
                          AdminSession.name.isNotEmpty
                              ? AdminSession.name[0].toUpperCase()
                              : "A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AdminSession.name.isNotEmpty ? AdminSession.name : 'Admin',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    AdminSession.email,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                          fontSize: 11.0,
                        ),
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
        if (AdminSession.role == 'main_admin')
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
      child: child,
    );
  }
}

// ─── ADMIN MANAGEMENT SCREEN ─────────────────────────────────────────────────
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
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  // --- API: FETCH ALL ---
  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'action': 'get_all',
          'requester_role': AdminSession.role,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List list = data['data'];
          setState(() {
            _admins.clear();
            for (int i = 0; i < list.length; i++) {
              final item = list[i];
              _admins.add({
                'id': item['id'].toString(),
                'name': item['full_name'] ?? '',
                'email': item['email'] ?? '',
                'campus': item['campus'] ?? '',
                'colorIndex': (i % _avatarColors.length).toString(),
              });
            }
          });
        }
      }
    } catch (e) {
      _showSnack("Network error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- API: ADD ADMIN ---
  Future<void> _addAdmin() async {
    setState(() {
      _emailError = null;
      _campusError = null;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (firstName.isEmpty || email.isEmpty) {
      _showSnack("First name and email are required.", isError: true);
      return;
    }

    if (!email.endsWith('@wvsu.edu.ph')) {
      setState(() => _emailError = "Acceptable WVSU Email: @wvsu.edu.ph");
      return;
    }

    if (_selectedCampus == null) {
      setState(() => _campusError = "Please select a campus.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullName = 'Dr. $firstName $lastName'.trim();
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'action': 'add',
          'requester_role': AdminSession.role,
          'full_name': fullName,
          'email': email,
          'campus': _selectedCampus!,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _fetchAdmins(); // Refresh to get server-side ID
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        setState(() => _selectedCampus = null);
        _showSnack("Administrator added successfully!");
      } else {
        _showSnack(data['message'] ?? 'Failed to add admin.', isError: true);
      }
    } catch (e) {
      _showSnack("Network error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- API: DELETE ADMIN ---
  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to remove $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final response = await http.post(
                  Uri.parse(_apiUrl),
                  body: {
                    'action': 'delete',
                    'requester_role': AdminSession.role,
                    'id': id,
                  },
                );

                final data = json.decode(response.body);
                if (data['status'] == 'success') {
                  setState(() => _admins.removeWhere((a) => a['id'] == id));
                  _showSnack("Administrator removed.");
                } else {
                  _showSnack(data['message'] ?? 'Delete failed.', isError: true);
                }
              } catch (e) {
                _showSnack("Network error: $e", isError: true);
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- UI DIALOG: EDIT ---
  void _showEditDialog(int filteredIndex) {
    final admin = _filteredAdmins[filteredIndex];
    final actualIndex = _admins.indexWhere((a) => a['id'] == admin['id']);
    if (actualIndex == -1) return;

    final nameCtrl = TextEditingController(text: _admins[actualIndex]['name']);
    final emailCtrl = TextEditingController(text: _admins[actualIndex]['email']);
    String? editSelectedCampus = _admins[actualIndex]['campus'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            bool dialogLoading = false;
            String? dEmailErr;
            String? dCampErr;

            return AlertDialog(
              title: const Text("Edit Administrator"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: "Full Name")),
                    const SizedBox(height: 15),
                    TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                            labelText: "Email", errorText: dEmailErr)),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: editSelectedCampus,
                      items: _campuses
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setInnerState(() => editSelectedCampus = val),
                      decoration: InputDecoration(
                          labelText: "Campus", errorText: dCampErr),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? () {}
                      : () async {
                          setInnerState(() => dialogLoading = true);
                          try {
                            final response = await http.post(
                              Uri.parse(_apiUrl),
                              body: {
                                'action': 'update',
                                'requester_role': AdminSession.role,
                                'id': admin['id']!,
                                'full_name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'campus': editSelectedCampus!,
                              },
                            );
                            final data = json.decode(response.body);
                            if (data['status'] == 'success') {
                              setState(() {
                                _admins[actualIndex]['name'] = nameCtrl.text.trim();
                                _admins[actualIndex]['email'] = emailCtrl.text.trim();
                                _admins[actualIndex]['campus'] = editSelectedCampus!;
                              });
                              Navigator.pop(context);
                              _showSnack("Updated successfully!");
                            } else {
                              _showSnack(data['message'], isError: true);
                            }
                          } catch (e) {
                            _showSnack("Error: $e", isError: true);
                          } finally {
                            setInnerState(() => dialogLoading = false);
                          }
                        },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, String>> get _filteredAdmins => _admins
      .where((admin) => admin['name']!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _filteredAdmins;

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
            // TOP BAR
            Container(
              width: double.infinity,
              color: const Color(0xFFD6D6D6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context)),
                  const Text("Administrator Management",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333))),
                  const Spacer(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "Add new admins, manage existing roles, transfer system ownership.",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 25),
                    
                    // CARD: ADD ADMIN
                    _buildCard(
                      title: "Add New University Librarian",
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildTextField("First name", "e.g. Juan",
                                  _firstNameController),
                              const SizedBox(width: 20),
                              _buildTextField("Last name", "e.g. Dela Cruz",
                                  _lastNameController),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField("Email Address", "name@wvsu.edu.ph",
                                  _emailController,
                                  errorText: _emailError),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Role Assignment in",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCampus,
                                      decoration: _inputDecoration(
                                          "e.g. Calinog Campus",
                                          errorText: _campusError),
                                      items: _campuses
                                          .map((c) => DropdownMenuItem(
                                              value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) => setState(
                                          () => _selectedCampus = val),
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
                              onPressed: _isLoading ? null : _addAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B36C2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 18),
                              ),
                              child: const Text("Add Administrator",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // CARD: ADMIN LIST
                    _buildCard(
                      title: "University Librarians List",
                      subtitle: "View, edit, or remove administrative access.",
                      headerWidget: Container(
                        width: 220,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFCDE4F7),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                    hintText: "Search by name",
                                    border: InputBorder.none,
                                    isCollapsed: true),
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
                              Expanded(flex: 4, child: Text("User Profile", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text("Campus Assigned", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text("Actions", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const Divider(height: 25),
                          if (filteredAdmins.isEmpty && !_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Text("No administrators found.", style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredAdmins.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final admin = filteredAdmins[index];
                                final colorIdx = int.parse(admin['colorIndex'] ?? "0");
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: _avatarColors[colorIdx % _avatarColors.length],
                                              child: Text(admin['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                                      Expanded(flex: 3, child: Text(admin['campus']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _showEditDialog(index)),
                                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(admin['id']!, admin['name']!)),
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

  // --- UI HELPERS ---
  Widget _buildCard({required String title, required Widget child, String? subtitle, Widget? headerWidget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              if (headerWidget != null) headerWidget,
            ],
          ),
          const SizedBox(height: 20),
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
          TextField(
            controller: controller,
            decoration: _inputDecoration(hint, errorText: errorText),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}