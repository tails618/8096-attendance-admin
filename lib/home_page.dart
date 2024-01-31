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
  String? uid = '';
  String? name = '';
  bool paused = false;
  int pauseCounter = 0;

  DatabaseReference ref = FirebaseDatabase.instance.ref();
  var auth = Auth().firebaseAuth;

  List<UserCard> userCards = [];

  @override
  Widget build(BuildContext context) {
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: togglePauseButton(context),
                ),
                Text('Paused: $paused'),
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

    createUserCards();

    auth.authStateChanges().listen((User? newUser) {
      if (newUser != null) {
        configUser();
      }
    });

    ref.child('pause').onValue.listen((event) {
      reloadPause();
    });
  }

  Future<void> createUserCards() async {
    DataSnapshot snapshot = await ref.get();
    Map<dynamic, dynamic> names = {};
    Map<dynamic, dynamic> values = snapshot.value as Map;
    for (final uid in values.keys) {
      if (uid == 'pause') {
        continue;
      }
      String name = snapshot.child(uid).child('name').value as String;
      names[uid] = name;
    }

    List<MapEntry<dynamic, dynamic>> namesList = names.entries.toList();
    namesList.sort((a, b) => a.value.compareTo(b.value));

    Map<dynamic, dynamic> sortedNames = Map.fromEntries(namesList);

    List<dynamic> sortedKeys = sortedNames.keys.toList();

    for (final uid in sortedKeys) {
      userCards.add(UserCard(uid: uid));
    }
  }

  void configUser() {
    uid = auth.currentUser?.uid;
    if (uid != null && uid != '') {
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
    DataSnapshot snapshot = await ref.child(uid!).get();
    if (snapshot.value == null) {
      newUser();
    } else {
      setState(() {
        email = auth.currentUser?.email;
        name = auth.currentUser?.displayName;
      });
    }
  }

  void reloadPause() async {
    DataSnapshot snapshot = await ref.child('pause').get();
    if (snapshot.value == null) {
      configPause();
    } else {
      setState(() {
        paused = snapshot.child('paused').value as bool;
        pauseCounter = snapshot.child('counter').value as int;
      });
    }
  }

  void configPause() {
    ref.child('pause/counter').set(0);
    ref.child('pause/pauses').set(null);
    ref.child('pause/paused').set(false);
  }

  void startPause() {
    ref
        .child('pause/pauses/$pauseCounter/pauseStart')
        .set(DateTime.now().millisecondsSinceEpoch);
    ref.child('pause/paused').set(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paused'),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  void endPause() {
    ref
        .child('pause/pauses/$pauseCounter/pauseEnd')
        .set(DateTime.now().millisecondsSinceEpoch);
    ref.child('pause/counter').set(pauseCounter + 1);
    ref.child('pause/paused').set(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unpaused'),
        duration: Duration(milliseconds: 1000),
      ),
    );
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

  ElevatedButton togglePauseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (paused) {
          endPause();
        } else {
          startPause();
        }
      },
      child: Text(paused ? 'End pause' : 'Start pause'),
    );
  }
}
