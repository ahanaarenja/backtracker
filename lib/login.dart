import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:backtracker/register.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
 import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:validation_textformfield/validation_textformfield.dart';

import 'colours.dart';

class LoginScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>{
  TextEditingController emailController=TextEditingController();
  TextEditingController passwordController=TextEditingController();
  bool isObscure=false;

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: 150,),
              Image.asset("assets/logo2.png",height: 150,fit: BoxFit.cover,),
          SizedBox(height:120),
              Container(
                height: MediaQuery.of(context).size.height-420,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                width:double.infinity,
                decoration: BoxDecoration(
                color:light,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30),topRight: Radius.circular(30))

              ),
              child: Column(
                children: [
                  SizedBox(height: 30,),
                  EmailValidationTextField(
                    whenTextFieldEmpty: "Please enter  email",
                    validatorMassage: "Please enter valid email",
                    decoration: InputDecoration(
                        labelText: ' Email ',
                        labelStyle: TextStyle(
                          color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700,
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
                  const SizedBox(height : 40),
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
                         onChanged: (value) {
                            print(value);
                         },
                        passTextEditingController: passwordController,
                        passwordMaxLength: 12,
                        passwordMinLength: 6,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: const InputDecoration(
                            labelText: ' Password ',
                            labelStyle: TextStyle(
                              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700,
                              fontFamily: "Cooper",
                              fontStyle: FontStyle.normal,
                            ),
                            prefixIcon: Icon(Icons.password_outlined, color: Colors.black,),
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
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            alignment: AlignmentDirectional.centerEnd,
                            child: IconButton(
                                onPressed: (){
                                  setState(() {
                                    isObscure = !isObscure;
                                  });
                                },
                                icon: isObscure ? Icon(FontAwesomeIcons.eye, size: 18, color: Colors.black, fontWeight: FontWeight.w700,) : Icon(FontAwesomeIcons.eyeSlash, size: 18, color: Colors.black, fontWeight: FontWeight.w700,)
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordSheet,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () async{
                      print(emailController.text);
                      print(passwordController.text);

                      if(emailController.text.isEmpty || passwordController.text.isEmpty){
                        const snackBar = SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'Error!',
                            message:
                            'Please enter valid details...',
                            contentType: ContentType.failure,
                          ),
                        );

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                      }
                      else {
                        showDialog(context: context, builder: (context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        });

                        try {
                           await FirebaseAuth.instance
                               .signInWithEmailAndPassword(
                             email: emailController.text,
                             password: passwordController.text,
                           );

                          Navigator.pop(context);

                           // await Navigator.of(context).pushReplacement(
                           //   MaterialPageRoute(
                           //     builder: (context) => MainNavigation(),
                           //   ),
                           // );
                        } on FirebaseAuthException catch (e) {
                          Navigator.pop(context);

                           print(e.code);

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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(double.infinity, 50),
                       textStyle: TextStyle(fontSize: 14),
                      shadowColor: mid,
                      elevation: 5,
                    ),
                    child: const Text("LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: "Cooper",
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (context)=>RegisterScreen()));
                      },
                      child: EasyRichText(
                        "Don't have an account? Register",
                        defaultStyle : TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                        patternList: [
                          EasyRichTextPattern(
                            targetString: 'Register',
                            style: TextStyle(color: dark),
                          ),
                        ],
                      ),
                  ),
                ],
              ),
              )
            ],)
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final initialEmail = (emailController?.text ?? '').trim();
    final TextEditingController _email = TextEditingController(text: initialEmail);
    bool _sending = false;
    String? _error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          const Expanded(
                            child: Text(
                              'Reset password',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Enter your email to get a password reset link.",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
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
                              borderSide: BorderSide(color: dark),
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: dark),
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: dark),
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            counterText: '',
                            hintStyle: TextStyle(color: Colors.black, fontSize: 18.0)
                        ),
                         textEditingController: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_error != null) setModalState(() => _error = null);
                        },
                      ),
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
                            decoration: const InputDecoration(
                                labelText: ' Password ',
                                labelStyle: TextStyle(
                                  color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700,
                                  fontFamily: "Cooper",
                                  fontStyle: FontStyle.normal,
                                ),
                                prefixIcon: Icon(Icons.password_outlined, color: Colors.black,),
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
                                    icon: isObscure ? Icon(FontAwesomeIcons.eye, size: 22, color: Colors.black,) : Icon(FontAwesomeIcons.eyeSlash, size: 22, color: Colors.black,)
                                )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                          ),
                          onPressed: _sending
                              ? null
                              : () async {
                            final email = _email.text.trim();
                            setModalState(() => _sending = true);
                            try {
                               await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              if (!mounted) return;
                              Navigator.pop(ctx);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Password reset email sent to $email')),
                               );
                              final snackBar = SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: 'Reset Password!',
                                  message:
                                  'Password reset email sent to $email',
                                  contentType: ContentType.success,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);
                            } on FirebaseAuthException catch (e) {
                              setModalState(() {
                                _sending = false;
                                 _error = e.code == 'user-not-found'
                                     ? 'No account found with this email'
                                     : (e.message ?? 'Failed to send reset email');
                              });
                              var snackBar = SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: 'Error!',
                                  message:
                                   e.code == 'user-not-found'
                                       ? 'No account found with this email'
                                       : (e.message ?? 'Failed to send reset email'),
                                  contentType: ContentType.failure,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);
                            } catch (_) {
                              setModalState(() {
                                _sending = false;
                                _error = 'Something went wrong. Please try again.';
                              });
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
                          child: _sending
                              ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Send reset link',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Tip: check your spam/junk folder if you don’t see the email.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
}