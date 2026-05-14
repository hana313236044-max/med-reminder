// import 'package:flutter/material.dart';
// import 'Login_screen.dart'; // adjust path if needed

// class ProfilePage extends StatefulWidget {
//   final String username;
//   final String email;

//   const ProfilePage({
//     Key? key,
//     required this.username,
//     required this.email,
//   }) : super(key: key);

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   late TextEditingController _usernameController;
//   late TextEditingController _emailController;

//   bool isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _usernameController =
//         TextEditingController(text: widget.username);
//     _emailController =
//         TextEditingController(text: widget.email);
//   }

//   void _logout() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Profile"),
//         actions: [
//           IconButton(
//             icon: Icon(isEditing ? Icons.save : Icons.edit),
//             onPressed: () {
//               setState(() {
//                 isEditing = !isEditing;
//               });

//               if (!isEditing) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Profile updated (demo)")),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const CircleAvatar(
//               radius: 50,
//               child: Icon(Icons.person, size: 50),
//             ),
//             const SizedBox(height: 20),

//             TextField(
//               controller: _usernameController,
//               enabled: isEditing,
//               decoration: const InputDecoration(
//                 labelText: "Username",
//               ),
//             ),
//             const SizedBox(height: 10),

//             TextField(
//               controller: _emailController,
//               enabled: isEditing,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//               ),
//             ),

//             const SizedBox(height: 30),

//             ElevatedButton.icon(
//               onPressed: _logout,
//               icon: const Icon(Icons.logout),
//               label: const Text("Logout"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }