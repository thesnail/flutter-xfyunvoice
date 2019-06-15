import 'package:flutter/material.dart';
import 'package:xfyunvoice/xfyun_voice.dart';

void main() async {
  await XfyunVoice.setAppId('appid=5d03b089');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() { 
    super.initState();
    XfyunVoice.onValueCallback((method,args){
      if(method == 'onBeginOfSpeech'){
        print('Flutter ====> onBeginOfSpeech');
      }else if(method == 'onVolumeChanged') {
        //print('Flutter ====> onVolumeChanged   $args');
      }else if(method == 'onResults') {
        print('Flutter ====> onResults   $args');
      }else if(method == 'onEndOfSpeech') {
        print('Flutter ====> onEndOfSpeech   $args');
      }else if(method == 'onCancel') {
        print('Flutter ====> onCancel');
      }else if(method == 'onCompleted') {
        print('Flutter ====> onCompleted   $args');
      }
    });
  }

  @override
  void dispose() { 
    super.dispose();
    XfyunVoice.cancel();
    XfyunVoice.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('语音识别与转换'),
        ),
        body: Stack(
          children: <Widget>[

            

            Container(
              margin: EdgeInsets.only(bottom: 20),
              alignment: Alignment.bottomCenter,
              child: Text('语音识别结果',style: TextStyle(color: Colors.blue),)
            )
          ],
        ),
      ),
    );
  }
}
