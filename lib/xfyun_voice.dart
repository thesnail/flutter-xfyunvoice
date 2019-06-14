import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class XfyunVoice {
  static const MethodChannel _channel = const MethodChannel('xfyunvoice');

  
  /// @args args 启动参数，必须保证appid参数传入，示例：appid=123456
  /// usr: 科大讯飞开发者在云平台上注册的账号。
  /// pwd: 科大讯飞账号对应的密码，与账号同时存在。
  /// 或者appid=12345678,usr=iflytekcloud,pwd=123456
  /// @return 成功返回YES,失败返回NO
  static Future<bool> setAppId(String args) async{
    final b = await _channel.invokeMethod('setAppId',{'args':args});
    return b;
  }

  static Future<bool> startListening() async {
    final b = await _channel.invokeMethod('startListening');
    return b;
  }

  static Future<bool> startSpeaking({@required String msg}) async{
    final b = await _channel.invokeMethod('startSpeaking',msg);
    return b;
  }

}
