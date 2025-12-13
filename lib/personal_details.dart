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

class PersonalDetails extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return PersonalDetailsState();
  }

}

class PersonalDetailsState extends State<PersonalDetails>{

  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  String _value = "";
  late DateTime birthDate;

  @override
  Widget build(BuildContext context) {
      return SafeArea(
        child: Scaffold(
            backgroundColor: light,
            body: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30,),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30,),
                            Text("Name: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),),
                            SizedBox(height: 10,),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person, color: Colors.black,),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  counterText: '',
                                  hintStyle: TextStyle(color: Colors.black, fontSize: 18.0)
                              ),
                              keyboardType: TextInputType.name,
                            ),
                            SizedBox(height: 30,),
                            Text("BirthDate: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),),
                            SizedBox(height: 10,),
                            BirthPicker(
                              decorationBuilder: (bool isFocused) {
                                return BoxDecoration(
                                  border: Border.all(
                                    color: isFocused ? Colors.blue : Colors.black,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                );
                              },
                              onChanged: (dateTime) {
                                if (dateTime != null) {
                                  setState(() {
                                    birthDate = dateTime;
                                  });
                                  print('Selected Date: ${dateTime.toIso8601String()}');
                                } else {
                                  print('Invalid Date');
                                }
                              },
                            ),
                            SizedBox(height: 30,),
                            Text("Gender: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),),
                            Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    'Male', style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  leading: Radio(
                                    value: "Male",
                                    groupValue: _value,
                                    activeColor: Color(0xFF6200EE),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _value = value!;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    'Female', style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  leading: Radio(
                                    value: "Female",
                                    groupValue: _value,
                                    activeColor: Color(0xFF6200EE),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _value = value!;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    'Rather Not Say', style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  leading: Radio(
                                    value: "Rather Not Say",
                                    groupValue: _value,
                                    activeColor: Color(0xFF6200EE),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _value = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: ElevatedButton(
                          onPressed: () async{
                            showDialog(context: context, builder: (context) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            });

                            try {

                              if(nameController.text.isEmpty || _value.isEmpty){
                                Navigator.pop(context);
                                const snackBar = SnackBar(
                                  elevation: 0,
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.transparent,
                                  content: AwesomeSnackbarContent(
                                    title: 'Error!',
                                    message:
                                    'Please enter valid credentials...',
                                    contentType: ContentType.failure,
                                  ),
                                );

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(snackBar);
                              }
                              else {
                                User? user = FirebaseAuth.instance.currentUser;

                                Map<String, dynamic> data = {
                                  "name": nameController.text,
                                  "age": birthDate ?? null,
                                  "gender": _value ?? "Rather Not Say",
                                };

                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(user!.uid)
                                    .update(data);

                                Navigator.pop(context);

                                await Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => NavBar(),
                                  ),
                                );
                              }

                            } on FirebaseAuthException catch (e) {
                              Navigator.pop(context);

                              print("error ${e.code}");
                              const snackBar = SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: 'Error!',
                                  message:
                                  'Something went wrong. Try again...',
                                  contentType: ContentType.failure,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);
                            }
                          },
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
                          child: const Text("CONTINUE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: "Cooper",
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ]
                    ),
                ),
            ),
        ),
      );
  }
  
}