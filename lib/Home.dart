import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:backtracker/exercise_db.dart';
import 'package:backtracker/guidebook_db.dart';
import 'package:backtracker/pain_assessment.dart';
import 'package:backtracker/personal_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:super_tooltip/super_tooltip.dart';
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
          // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              Container(
                // height: 200,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
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
                      style: TextStyle(color: mid, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Image.asset("assets/analysis.png", width: 50, height: 35,),
                            SizedBox(height: 10,),
                            Text("personalized analysis", style: TextStyle(color: mid, fontWeight: FontWeight.w600),)
                          ],
                        ),
                        Column(
                          children: [
                            Image.asset("assets/exercises.png", width: 50, height: 35,),
                            SizedBox(height: 10,),
                            Text("custom exercises", style: TextStyle(color: mid, fontWeight: FontWeight.w600),)
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 10,),
                    IconButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> PainAssessment()));
                        },
                        icon: Icon(FontAwesomeIcons.arrowRight, fontWeight: FontWeight.w900, color: dark,)
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),
              Divider(),
              SizedBox(height: 20,),
              Text("    All exercises", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dark),),
              SizedBox(height: 20,),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children:
                      allExercises.map<Widget>((value){
                        return exerciseCardHome(value);
                      }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              Divider(),
              SizedBox(height: 20,),
              Text("    Guidebook", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dark),),
              SizedBox(height: 20,),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children:
                    guideBook.map<Widget>((value){
                      return guideCard(value);
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 100,),
            ],
          ),
        ),
      ),
    );
  }

  Widget exerciseCardHome(data){
    return Column(
      children: [
        Container(
            width: 150,
            height: 155,
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(data["image"], height: 100,)
                ),
                SizedBox(height: 5,),
                Text(data["name"],
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
      ],
    );
  }

  Widget guideCard(data){
    return GestureDetector(
      onTap: () async {
        showMaterialModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              height: 200,
              margin: EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  Image.asset(data["image"],height: 120,),
                  SizedBox(height: 20,),
                  Text(data["text"], textAlign: TextAlign.center,),
                ],
              ),
            );
          }
        );
      },
      child: Container(
        width: 150,
        height: 150,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            borderRadius: BorderRadius.circular(20)
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(data["image"], fit: BoxFit.fitWidth,)
        ),
      ),
    );
  }
  
}