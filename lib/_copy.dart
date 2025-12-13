import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:backtracker/personal_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:validation_textformfield/validation_textformfield.dart';

import 'colours.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }

}

class HomeScreenState extends State<HomeScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BackTrackers", style: TextStyle(fontWeight: FontWeight.w700,)),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                color: dark,
                child: Row(
                  children: [
                    Icon(Icons.star, size: 30,),
                    SizedBox(width: 10,),
                    Column(
                      children: [
                        Text("AI-Generated Plan"),
                        SizedBox(height: 10,),
                        Text("Based on your pain assessment, we've created a personalized exercises to help reduce your back pain and improve mobility."),
                        SizedBox(height: 20,),
                        Row(
                          children: [
                            Column(
                              children: [
                                Text("🕗 Time"),
                                SizedBox(height: 10,),
                                Text("15 min")
                              ],
                            ),
                            Column(
                              children: [
                                Text("🕗 Exercises"),
                                SizedBox(height: 10,),
                                Text("15 min")
                              ],
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
}