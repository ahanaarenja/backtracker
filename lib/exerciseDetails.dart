import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'colours.dart';
import 'form_check_screen.dart';

class ExerciseDetails extends StatefulWidget{
  final Map<String, dynamic> data;

  const ExerciseDetails({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ExerciseDetailsState();
  }
}

class ExerciseDetailsState extends State<ExerciseDetails> {
  bool isSwitched = false;
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    // Extract video ID from the YouTube URL
    final videoId = YoutubePlayer.convertUrlToId(widget.data["link"]) ?? '';
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        enableCaption: true,
      ),
    );

    // Show strap dialog if strapNeeded is true
    if (widget.data["strapNeeded"] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStrapDialog();
      });
    }
  }

  void _showStrapDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "BackTracker Strap",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          content: const Text(
            "Wearing the BackTracker strap would help track your spine alignment during this exercise for better posture feedback.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Exercise Details", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),),
      ),
      body: Stack(
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Use Posture Strap", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
                          Text("Connect your strap for enhanced tracking")
                        ],
                      ),
                      Switch(
                        value: isSwitched, // The current value of the switch
                        onChanged: (value) { // Callback when the switch is toggled
                          setState(() {
                            isSwitched = value; // Update the state with the new value
                          });
                        },
                        activeThumbColor: dark, // Color when the switch is ON
                        inactiveThumbColor: Colors.grey, // Color of the thumb when the switch is OFF
                      )
                    ],
                  ),
                ),
                Divider(),
                SizedBox(height: 5,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(widget.data["name"], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),),
                ),
                SizedBox(height: 10,),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                          color: light,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20))
                      ),
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                      child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: YoutubePlayer(
                                controller: _youtubeController,
                                showVideoProgressIndicator: true,
                                progressIndicatorColor: dark,
                                progressColors: ProgressBarColors(
                                  playedColor: dark,
                                  handleColor: mid,
                                ),
                              ),
                            ),
                            SizedBox(height: 30,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "About This Exercise \n${widget.data["whatItHelps"]}",
                                style: TextStyle(
                                    fontSize: 15
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 30,),
                            Container(
                              padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                              decoration: BoxDecoration(
                                border: Border.all(),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "    How to Perform",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  SizedBox(height: 10,),
                                  Column(
                                    children: widget.data["steps"].asMap().entries.map<Widget>(
                                            (entry){
                                          final index = entry.key;
                                          final value = entry.value;
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding : EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                  decoration: BoxDecoration(
                                                      color: mid,
                                                      borderRadius: BorderRadius.circular(50)
                                                  ),
                                                  child: Text("$index", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),),
                                                ),
                                                SizedBox(width: 10,),
                                                Expanded(
                                                    child: Text("$value",
                                                      style: TextStyle(fontSize: 15),
                                                    )
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                    ).toList(),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 100,),
                          ]
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(30, 10, 30, 30),

                width: double.infinity,
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormCheckScreen(
                          exerciseData: widget.data,
                          useStrap: isSwitched,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("► Start Exercise", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),),
                ),
              )
          ),
        ],
      ),
    );
  }
}