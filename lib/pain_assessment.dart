import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:birth_picker/birth_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:validation_textformfield/validation_textformfield.dart';

import 'NavBar.dart';
import 'colours.dart';
import 'login.dart';

class PainAssessment extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return PainAssessmentState();
  }

}

class PainAssessmentState extends State<PainAssessment>{

  final List<Map<String, List<String>>> uniqueValuesByQuestion = [{
    "Where is your pain located?": [
      "Lower Back",
      "Upper Back",
      "Mid Back",
      "Neck",
    ],
  },
    {
    "Are you experiencing any of these symptoms?": [
      "Yes",
      "No",
    ],
  },
    {
      "What is the duration of pain?": [
        "Acute",
        "Chronic",
      ],
    },
    {
    "How would you describe your current pain": [
      "improved",
      "Worsening",
      "remained the same",
    ],
  },
    {
    "How would you describe pattern on your pain": [
      "Stay for long time",
      "Come and go in interval",
    ],
  }];

  int _currentQuestionIndex = 0;
  double _width = 0;
  double percent = 0.20;
  double progressbar_width = 300;

  void _nextQuestion() {
    if (_currentQuestionIndex < 5) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('You have completed all questions!')));
    }
  }

  Widget _buildQuestion() {
    switch (_currentQuestionIndex) {
      case 0:
        percent = 0.20;
        return _buildQuestionUI();
      case 1:
        percent = 0.40;
        return _buildQuestionUI();
      case 2:
        percent = 0.60;
        return _buildQuestionUI();
      case 3:
        percent = 0.80;
        return _buildQuestionUI();
      case 4:
        percent = 1;
        return _buildQuestionUI();
      default:
        return Container();
    }
  }

  Widget _buildQuestionUI(){
    return Container(

    );
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _width = percent * progressbar_width;
      });
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        title: Column(
          children: [
            Text("Pain Assessment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),),
            SizedBox(height: 10,),
            Stack(
              children: [
                Container(
                  width: 300,
                  height: 17,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFFCFE2F3)),
                ),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: _width,
                    height: 17,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: dark)
                ),
              ],
            ),
            SizedBox(height: 10,),
            Text("Question ${_currentQuestionIndex + 1} of 5", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: light,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 50),
              Expanded(child:
                Center(
                  child :
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _buildQuestion(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}