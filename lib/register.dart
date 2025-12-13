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

class RegisterScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return RegisterScreenState();
  }

}

class RegisterScreenState extends State<RegisterScreen>{
  TextEditingController? emailController, passwordController, confirmPasswordController;
  double screenHeight = 0;
  double screenWidth = 0;
  bool isObscure = true;
  bool isObscureCP = true;
  bool showvalue = false;

  final FirebaseFirestore firestore= FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: dark,
        body: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              SizedBox(height: 110,),
            Image.asset("assets/logo2.png",height: 150,fit: BoxFit.cover,),
            SizedBox(height:100),
            Container(
              height: MediaQuery.of(context).size.height-360,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              width:double.infinity,
              decoration: BoxDecoration(
                  color:light,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30),topRight: Radius.circular(30))

              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    EmailValidationTextField(
                      whenTextFieldEmpty: "Please enter  email",
                      validatorMassage: "Please enter valid email",
                      decoration: InputDecoration(
                          labelText: ' Email ',
                          labelStyle: TextStyle(
                            color: Colors.black, fontSize: 22, fontWeight: FontWeight.w500,
                            fontFamily: "Cooper",
                            fontStyle: FontStyle.normal,
                          ),
                          prefixIcon: Icon(Icons.email_rounded, color: Colors.black,),
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
                      textEditingController: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height : 20),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PassWordValidationTextFiled(
                          lineIndicator:false,
                          passwordMinError: "Must be more than 6 characters",
                          hasPasswordEmpty: "Password is Empty",
                          passwordMaxError: "Password too Long",
                          passWordUpperCaseError: "At least one Uppercase(Capital) letter",
                          passWordDigitsCaseError: "At least one digit",
                          passwordLowercaseError: "At least one lowercase character",
                          passWordSpecialCharacters: "At least one Special Characters",
                          obscureText: isObscure,
                          scrollPadding: const EdgeInsets.only(left: 60),
                          // onChanged: (value) {
                          //   // print(value);
                          // },
                          passTextEditingController: passwordController,
                          passwordMaxLength: 12,
                          passwordMinLength: 6,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                              labelText: ' Password ',
                              labelStyle: const TextStyle(
                                color: Colors.black, fontSize: 22, fontWeight: FontWeight.w500,
                                fontFamily: "Cooper",
                                fontStyle: FontStyle.normal,
                              ),
                              prefixIcon: const Icon(Icons.password_outlined, color: Colors.black,),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              counterText: '',
                              hintStyle: const TextStyle(color: Colors.black, fontSize: 18.0)
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              // color: Colors.white,
                              alignment: AlignmentDirectional.centerEnd,
                              child: IconButton(
                                  onPressed: (){
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: isObscure ? Icon(FontAwesomeIcons.eye, size: 18, fontWeight: FontWeight.w700,) : Icon(FontAwesomeIcons.eyeSlash, size: 18, fontWeight: FontWeight.w700,)
                              )
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height : 20),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ConfirmPassWordValidationTextFromField(
                          obscureText: isObscureCP,
                          // obscureText: _isObscure,
                          scrollPadding: EdgeInsets.only(left: 60),
                          // onChanged: (value) {
                          // // print(value);
                          // },
                          whenTextFieldEmpty: "Cannot be Empty",
                          validatorMassage: "Password do not Match",
                          confirmtextEditingController: confirmPasswordController,
                          decoration: InputDecoration(
                              labelText: ' Confirm Password ',
                              labelStyle: const TextStyle(
                                color: Colors.black, fontSize: 22, fontWeight: FontWeight.w500,
                                fontFamily: "Cooper",
                                fontStyle: FontStyle.normal,
                              ),
                              prefixIcon: const Icon(Icons.password_rounded, color: Colors.black,),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 2),
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              counterText: '',
                              hintStyle: const TextStyle(color: Colors.black, fontSize: 18.0)
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              // color: Colors.white,
                              alignment: AlignmentDirectional.centerEnd,
                              child: IconButton(
                                  onPressed: (){
                                    setState(() {
                                      isObscureCP = !isObscureCP;
                                    });
                                  },
                                  icon: isObscureCP ? Icon(FontAwesomeIcons.eye, size: 22,) : Icon(FontAwesomeIcons.eyeSlash, size: 22,)
                              )
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30,),
                    ElevatedButton(
                      onPressed: () async{
                
                        print(emailController!.text);
                        print(passwordController!.text);
                
                        showDialog(context: context, builder: (context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        });
                
                        try {
                
                          if(emailController!.text.isEmpty || passwordController!.text.isEmpty || confirmPasswordController!.text.isEmpty){
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
                
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: emailController!.text,
                            password: passwordController!.text,
                          );
                
                          User? user = FirebaseAuth.instance.currentUser;
                
                          Map<String, dynamic> data = {
                            "email": emailController?.text,
                            "name": "",
                            "age": "",
                            "gender": "",
                          };
                
                          await FirebaseFirestore.instance
                              .collection("Users")
                              .doc(user!.uid)
                              .set(data);
                
                          Navigator.pop(context);
                
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => PersonalDetails(),
                            ),
                          );
                
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
                      child: const Text("REGISTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: "Cooper",
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30,),
                    GestureDetector(
                      onTap: () async{
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child:
                      EasyRichText(
                        "Already have an account? Login...",
                        defaultStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: "Cooper",
                          fontStyle: FontStyle.normal,
                        ),
                        patternList: [
                          EasyRichTextPattern(
                              targetString: 'Login...',
                              style: TextStyle(fontWeight: FontWeight.w900, color: dark)
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30,),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}