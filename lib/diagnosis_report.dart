import 'package:flutter/material.dart';

class DiagnosisReport extends StatefulWidget{
  final String diagnosis;
  final double confidence;

  const DiagnosisReport({
    Key? key,
    required this.diagnosis,
    required this.confidence,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DiagnosisReportState();
  }
}

class DiagnosisReportState extends State<DiagnosisReport>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.diagnosis, style: TextStyle(fontSize: 16),)
          ],
        ),
      )
    );
  }
  
}