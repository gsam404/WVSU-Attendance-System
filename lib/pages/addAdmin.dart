import 'package:flutter/widgets.dart';
import './sidebar.dart';
import 'package:flutter/material.dart';

class ProfilePopUp extends StatelessWidget {
  final Widget child;
  const ProfilePopUp({super.key,  required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PopupMenuButton<String>(
        offset: const Offset(35, -270),
        color: Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        constraints: const BoxConstraints(
          minHeight: 252,
        ),
        onSelected: (value) {
          if(value == 'add_admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlaceHolderClass()), //put add admin method here
            );
          } else if(value == 'logOut') {
            //Put log Out methods here

          }
        },

        child: child,

        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //Pop up header
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [Text(
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
                    ]
                  ),
                ]
              ),
            ]
          ),
        ),

        //Divider
        PopupMenuItem(
          enabled: false,
          height: 1,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Divider(
            color: Colors.grey,
          )
        ),

        PopupMenuItem<String>(
          value: 'add_admin',
          child: Row(
            spacing: 12,
            children: [
              Image.asset(
                'assets/userAdd.png',
                width:  24,
                height: 24,
              ),
              Text(
                'Add Admin',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w300,
                              color: Colors.black,
                              fontSize: 20.0,
                          ), 
              ),
            ]
          ),
        ),
        PopupMenuItem<String>(
          value: 'logOut',
          child: Row(
            spacing: 12,
            children: [
              Image.asset(
                'assets/logOut.png',
                width:  24,
                height: 24,
              ),
              Text(
                'Log Out',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w300,
                              color: Colors.red,
                              fontSize: 20.0,
                          ), 
              ),
            ]
          ),
        ),
      ],
      ),
    );

  }
}

//Sample destination class sang add admin
class PlaceHolderClass extends StatelessWidget {
  const PlaceHolderClass({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Add Admin")),);
  }
}