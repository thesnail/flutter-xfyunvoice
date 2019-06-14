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
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[

            FlatButton(
              child: Text('开始语音识别'),
              onPressed: (){
                XfyunVoice.startListening().then((val){
                  print('启动语音识别:$val');
                });
              },
            ),

            FlatButton(
              child: Text('文字转语音'),
              onPressed: () async{
                XfyunVoice.startSpeaking(msg:'文字转语音,文字转语音,文字转语音,文字转语音,文字转语音,文字转语音,文字转语音,文字转语音').then((val){
                  print('启动语音识别:$val');
                });

                bool isSpeaking =  await XfyunVoice.isSpeaking;

                print('=====>isSpeaking:${isSpeaking?'正在播放':'未播放'}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
