import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'colours.dart';

class EditProfile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EditProfileState();
  }
}

class EditProfileState extends State<EditProfile> {
  TextEditingController nameController = TextEditingController();
  String _gender = "";
  DateTime? birthDate;
  bool isLoading = true;

  // Calculate age from birthdate
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    // Check if birthday hasn't occurred yet this year
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data["name"] ?? "";
          _gender = data["gender"] ?? "";
          if (data["birthdate"] != null) {
            birthDate = (data["birthdate"] as Timestamp).toDate();
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: light,
        body: Center(child: CircularProgressIndicator(color: dark)),
      );
    }

    return Scaffold(
      backgroundColor: light,
      appBar: AppBar(
        backgroundColor: light,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: dark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: dark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text("Name: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dark, width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        counterText: '',
                        hintStyle: TextStyle(color: Colors.black, fontSize: 18.0),
                      ),
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 30),
                    Text("BirthDate: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: birthDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            birthDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              birthDate != null
                                  ? DateFormat('dd/MM/yyyy').format(birthDate!)
                                  : "Select Date",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text("Gender: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Column(
                      children: [
                        ListTile(
                          title: Text('Male', style: TextStyle(fontWeight: FontWeight.w600)),
                          leading: Radio(
                            value: "Male",
                            groupValue: _gender,
                            activeColor: dark,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value!;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Female', style: TextStyle(fontWeight: FontWeight.w600)),
                          leading: Radio(
                            value: "Female",
                            groupValue: _gender,
                            activeColor: dark,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value!;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Rather Not Say', style: TextStyle(fontWeight: FontWeight.w600)),
                          leading: Radio(
                            value: "Rather Not Say",
                            groupValue: _gender,
                            activeColor: dark,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Save Button at bottom
          Container(
            padding: EdgeInsets.fromLTRB(30, 10, 30, 30),
            color: light,
            child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return Center(child: CircularProgressIndicator(color: dark));
                    },
                  );

                  try {
                    if (nameController.text.isEmpty || _gender.isEmpty) {
                      Navigator.pop(context);
                      const snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: AwesomeSnackbarContent(
                          title: 'Error!',
                          message: 'Please fill in all fields...',
                          contentType: ContentType.failure,
                        ),
                      );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                    } else {
                      User? user = FirebaseAuth.instance.currentUser;

                      Map<String, dynamic> data = {
                        "name": nameController.text,
                        "birthdate": birthDate,
                        "age": birthDate != null ? _calculateAge(birthDate!) : null,
                        "gender": _gender,
                      };

                      await FirebaseFirestore.instance
                          .collection("Users")
                          .doc(user!.uid)
                          .update(data);

                      Navigator.pop(context); // Close loading dialog

                      const snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: AwesomeSnackbarContent(
                          title: 'Success!',
                          message: 'Profile updated successfully!',
                          contentType: ContentType.success,
                        ),
                      );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);

                      Navigator.pop(context); // Go back to profile
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    const snackBar = SnackBar(
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.transparent,
                      content: AwesomeSnackbarContent(
                        title: 'Error!',
                        message: 'Something went wrong. Try again...',
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
                  shadowColor: dark,
                  elevation: 5,
                ),
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

