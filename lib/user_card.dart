import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UserCard extends StatefulWidget {
  final String uid;
  UserCard({super.key, required this.uid});

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  String? name;
  String? email;
  late String uid;
  String? userState;
  int? totalSessions;
  int? totalTimeMilliseconds;
  String? totalTime;
  DateTime? lastEventTime;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    reload();
    listenForChange();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (userState != null && userState == 'in')
          ? Colors.green[600]
          : Colors.red[300],
      child: Padding(
        // padding: const EdgeInsets.only(top: 36.0, left: 6.0, right: 6.0, bottom: 6.0),
        padding:
            const EdgeInsets.only(top: 6.0, left: 6.0, right: 6.0, bottom: 6.0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: DefaultTextStyle(
            style: TextStyle(
                color: (userState != null && userState == 'in')
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurface),
            child: ExpansionTile(
              title: Text(generateTitle(),
                  style: TextStyle(
                      color: (userState != null && userState == 'in')
                          ? Colors.black
                          : Theme.of(context).colorScheme.onSurface)),
              children: <Widget>[
                Text('Email: $email'),
                Text('Sessions: $totalSessions'),
                Text('State: $userState'),
                Text('Total Time: $totalTime'),
                Visibility(
                    visible: userState == 'in',
                    child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFunctions.instance
                              .httpsCallable('uidSignOut')
                              .call({"uid": uid});
                        },
                        child: const Text('Stop time')))
              ],
            ),
          ),
        ),
      ),
    );
  }

  String generateTitle() {
    if (name == null) return 'Loading...';
    String wrappedFormattedDate = '';
    if (userState == 'in') {
      String formattedDate =
          DateFormat('h:mm a, d MMMM yyyy').format(lastEventTime!);
      wrappedFormattedDate = '(Checked in: $formattedDate)';
    } else {
      String formattedDate =
          DateFormat('h:mm a, d MMMM yyyy').format(lastEventTime!);
      wrappedFormattedDate = '(Checked out: $formattedDate)';
    }
    return '$name $wrappedFormattedDate';
  }

  void listenForChange() {
    FirebaseDatabase.instance
        .ref('$uid/state')
        .onValue
        .listen((DatabaseEvent event) {
      reload();
    });
  }

  void reload() async {
    DataSnapshot snapshot = await ref.child(uid).get();
    setState(() {
      name = snapshot.child('name').value.toString();
      email = snapshot.child('email').value.toString();
      totalTimeMilliseconds = snapshot.child('totalTime').value as int;
      Duration totalTimeDuration =
          Duration(milliseconds: totalTimeMilliseconds ?? 0);
      totalTime =
          '${totalTimeDuration.inHours}:${totalTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${totalTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
      totalSessions = snapshot.child('totalSessions').value as int;
      userState = snapshot.child('state').value.toString();
      int counter = snapshot.child('counter').value as int;
      if (counter == 0) {
        lastEventTime = DateTime.fromMillisecondsSinceEpoch(0);
      } else {
        if (userState == 'in') {
          int lastIn = snapshot.child('sessions/$counter/timeIn').value as int;
          lastEventTime = DateTime.fromMillisecondsSinceEpoch(lastIn);
        } else {
          int lastOut =
              snapshot.child('sessions/${counter - 1}/timeOut').value as int;
          lastEventTime = DateTime.fromMillisecondsSinceEpoch(lastOut);
        }
      }
    });
  }
}
