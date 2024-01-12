import 'package:cache_money_attendance_admin/auth.dart';
import 'package:cache_money_attendance_admin/user_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? email = '';
  String? name = '';

  DatabaseReference ref = FirebaseDatabase.instance.ref();
  var auth = Auth().firebaseAuth;

  List<UserCard> userCards = [];

  @override
  Widget build(BuildContext context) {
    // return const Text('Hello World');
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: auth.currentUser != null,
              replacement: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                        'Note: Sign-in works via pop-up, which is not supported '
                        'on all browsers. If you are having trouble signing in, '
                        'try enabling pop-ups or using a different browser.'),
                  ),
                  SignInButton(context: context),
                ],
              ),
              child: Column(children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SignOutButton(context: context)),
                Text('Email: $email'),
                Text('Name: $name'),
                ScrollConfiguration(
                  behavior:
                      ScrollConfiguration.of(context).copyWith(dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  }),
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userCards.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return userCards[index];
                    },
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    ref.get().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value as Map;
      List<dynamic> keys = values.keys.toList();
      for (final uid in keys) {
        userCards.add(UserCard(uid: uid));
      }
    });
    auth.authStateChanges().listen((User? newUser) {
      if (newUser != null) {
        configUser();
      }
    });
  }

  void configUser() {
    email = auth.currentUser?.uid;
    if (email != null && email != '') {
      reload();
    }
  }

  void newUser() {
    setUserVal('/totalTime', 0);
    setUserVal('/state', 'out');
    setUserVal('/counter', 0);
    setUserVal('/admin', false);
  }

  void reload() async {
    DataSnapshot snapshot = await ref.child(email!).get();
    if (snapshot.value == null) {
      newUser();
    } else {
      setState(() {
        email = auth.currentUser?.email;
        name = auth.currentUser?.displayName;
      });
    }
  }

  void setUserVal(String child, Object val) {
    ref
        .child('$email$child')
        .set(val)
        .then((result) => {reload()})
        .catchError((e) => {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e)),
              )
            });
  }
}
