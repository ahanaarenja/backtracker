import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:backtracker/exerciseDetails.dart';
import 'package:backtracker/pain_assessment.dart';
import 'package:backtracker/personal_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:validation_textformfield/validation_textformfield.dart';

import 'colours.dart';
import 'exercise_db.dart';
import 'login.dart';

class Exercises extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return ExercisesState();
  }

}

class ExercisesState extends State<Exercises>{
  final user = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }

        final data = snapshot.data?.data();

        if (data == null || data["diagnosis"] == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/assessment.png", width: 100, height: 100, color: mid,),
                  SizedBox(height: 20,),
                  Text("Complete your pain assessment first", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context)=>PainAssessment()));
                    },
                    child: Text("Take Assessment", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),

                      minimumSize: const Size(200, 40),
                      // textStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final diagnosis = data["diagnosis"]["diagnosis"];

        if(diagnosis == "Further investigation required"){
          return Scaffold(
            backgroundColor: light,
            appBar: AppBar(
              toolbarHeight: 10,
              backgroundColor: light,
            ),
            body: Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                      children: allExercises.asMap().entries.map<Widget>(
                              (entry){
                            return exerciseCard(entry.key + 1, entry.value);
                          }
                      ).toList()
                  ),
                ),
              ),
            ),
          );
        }


        final diagnosis_exercises = diagnosisExercises[diagnosis];
        print(diagnosis);
        print(diagnosis_exercises);

        return Scaffold(
          backgroundColor: light,
          appBar: AppBar(
            toolbarHeight: 10,
            backgroundColor: light,
          ),
          body: Container(
            child: Column(
              children: [
                Container(
                  color: dark,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.star, size: 30, color: Colors.white,),
                      SizedBox(width: 10,),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("AI-Generated Plan", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),),
                            Text("Based on your pain assessment, we've created a personalized exercises to help reduce your back pain and improve mobility.",
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            SizedBox(height: 20,),
                            Text("Total Exercises : 5", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: diagnosis_exercises.asMap().entries.map<Widget>(
                            (entry){
                              return exerciseCard(entry.key + 1, entry.value);
                            }
                        ).toList()
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget exerciseCard(index, data){
    return GestureDetector(
      onTap: (){
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context)=>ExerciseDetails(data: data,)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all()
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding : EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: mid,
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child: Text("$index", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),),
                  ),
                  Expanded(
                      child: Text("${data["name"]}",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        textAlign: TextAlign.center,
                      )
                  ),
                ],
              ),
              SizedBox(height: 15,),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  // color: mid,
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(20),
                    child: Image.asset(data["image"])
                ),
              ),
              SizedBox(height: 15,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text("${data["whatItHelps"]}",
                  style: TextStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 15,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                            color: dark,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Column(
                          children: [
                            Text("reps",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text("${data["reps"]}",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 30,),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                            color: dark,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Column(
                          children: [
                            Text("sets",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text("${data["sets"]}",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          )
      ),
    );
  }
  
}