import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:backtracker/pain_assessment.dart';
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
      backgroundColor: light,
      appBar: AppBar(
        backgroundColor: light,
        title: Text("BackTrackers", style: TextStyle(fontWeight: FontWeight.w900, color: dark)),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Container(
                // height: 200,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("AI-Powered Pain Assessment", style: TextStyle(fontSize: 17, color: dark, fontWeight: FontWeight.w700),),
                    SizedBox(height: 10,),
                    Text("answer a few questions about your back pain to get:",
                      style: TextStyle(color: mid),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.search),
                            Text("personalized analysis")
                          ],
                        ),
                        Column(
                          children: [
                            Icon(FontAwesomeIcons.dumbbell),
                            Text("custom exercises")
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 20,),
                    IconButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> PainAssessment()));
                        },
                        icon: Icon(Icons.arrow_forward, fontWeight: FontWeight.w900, color: dark,)
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