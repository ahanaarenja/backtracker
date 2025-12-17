import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:birth_picker/birth_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:validation_textformfield/validation_textformfield.dart';
import 'package:http/http.dart' as http;
import 'NavBar.dart';
import 'colours.dart';
import 'diagnosis_report.dart';
import 'login.dart';

class PainAssessment extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return PainAssessmentState();
  }
}

class PainAssessmentState extends State<PainAssessment>{

  User? user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> uniqueValuesByQuestion = [
    {
      "question": "Where is your pain located?",
      "options": [
        "Lower Back",
        "Upper Back",
        "Mid Back",
        "Neck",
      ],
    },
    {
      "question": "Are you experiencing one of more of these symptoms?\n🔹Dizziness\n🔹Nausea\n🔹Headaches\n🔹Weight loss",
      "options": [
        "Yes",
        "No",
      ],
    },
    {
      "question": "What is the duration of pain?",
      "options": [
        "Acute",
        "Chronic",
      ],
    },
    {
      "question": "How would you describe your current pain?",
      "options": [
        "improved",
        "Worsening",
        "remained the same",
      ],
    },
    {
      "question": "How would you describe pattern on your pain?",
      "options": [
        "Stay for long time",
        "Come and go in interval",
      ],
    },
  ];

  bool loading = false;

  final List<dynamic> assessmentAnswers = ["","","","",""];

  int _currentQuestionIndex = 0;
  double _width = 0;
  double percent = 0.20;
  double progressbar_width = 300;
  List<bool> answered = [];

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < 4) {
      setState(() {
        _currentQuestionIndex++;
        answered = List.filled(
            uniqueValuesByQuestion[_currentQuestionIndex]["options"].length,
            false
        );
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _width = percent * progressbar_width;
        });
      });
    } else {
      setState(() {
        loading = true;
      });
      await _checkDiagnosis();
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(SnackBar(content: Text('You have completed all questions!')));
    }
  }

  Widget _buildQuestion() {
    if (_currentQuestionIndex < uniqueValuesByQuestion.length) {
      percent = (_currentQuestionIndex + 1) * 0.20;
      return _buildQuestionUI();
    } else {
      return Container();
    }
  }

  Widget _buildQuestionUI(){
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uniqueValuesByQuestion[_currentQuestionIndex]["question"],
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 10,),
                Column(
                  children:
                    uniqueValuesByQuestion[_currentQuestionIndex]["options"].asMap().entries.map<Widget>((entry) {
                      int index = entry.key;
                      String i = entry.value;
                      print(index);
                     return Padding(
                       padding:(index%2==0) ? EdgeInsets.only(right: 40, bottom: 20) : EdgeInsets.only(left:40, bottom: 20),
                       child: ElevatedButton(
                         onPressed: (){
                           setState(() {
                             if(!answered.contains(true) || answered[index]) {
                               answered[index] = !answered[index];
                               assessmentAnswers[_currentQuestionIndex] = i;
                             }
                           });
                         },
                         child: Text(i, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: (answered[index]) ? dark : mid,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(25),
                           ),

                           minimumSize: const Size(double.infinity, 40),
                           // textStyle: TextStyle(fontSize: 14),
                         ),
                       ),
                     );
                   }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 150),
            child: ElevatedButton(
              onPressed: (){
                if(answered.contains(true)) {
                  _nextQuestion();
                }
                else{
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Please select an optionq')));
                }
              },
              child: Text("Next", style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(double.infinity, 50),
                // textStyle: TextStyle(fontSize: 14),
                shadowColor: dark,
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDiagnosis() async {
      try {

          final response = await http.post(
            Uri.parse('http://192.168.0.205:8080/check_diagnosis'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Pain location': assessmentAnswers[0],
              'Are you experiencing any of these symptoms': assessmentAnswers[1],
              'Duration of pain': assessmentAnswers[2],
              'How would you describe your current pain': assessmentAnswers[3],
              'How would you describe pattern on your pain': assessmentAnswers[4]
            }),
          );

          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          if (response.statusCode == 200) {
            dynamic result = json.decode(response.body);
            print("Parsed result: $result");
            if (result["status"] == "successful") {
              await FirebaseFirestore.instance.collection("Users").doc(user?.uid).update({"diagnosis":{"diagnosis": result["diagnosis"], "confidence": result["confidence"]}});

              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => DiagnosisReport(confidence: result["confidence"], diagnosis: result["diagnosis"],)));
            }
            else {
              setState(() {
                loading = false;
              });
              print("error ");
              const snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Error!',
                  message:
                  'Something went wrong. Try again later',
                  contentType: ContentType.failure,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            }
          }
          else {
            setState(() {
              loading = false;
            });
            const snackBar = SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Error!',
                message:
                'Something went wrong. Try again later',
                contentType: ContentType.failure,
              ),
            );

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(snackBar);
        }
      } catch (e) {
        setState(() {
          loading = false;
        });


        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error',
            message: "Something went wrong. Try again later",
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
  }

  @override
  void initState() {
    super.initState();
    answered = List.filled(
        uniqueValuesByQuestion[0]["options"].length,
        false
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _width = percent * progressbar_width;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (loading)? AppBar() : AppBar(
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
      body: (loading)?
        Center(
          child: Center(
            child: Image.asset(
              "assets/sending_mails.gif",
              width: 300,
            ),
          ),
        ):
      SingleChildScrollView(
        child: Container(
          color: light,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height-100,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
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