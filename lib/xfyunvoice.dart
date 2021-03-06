import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ValueCallback = void Function(String method,dynamic args);

class XfyunVoice {
  static const MethodChannel _channel = const MethodChannel('xfyunvoice');

  static void onValueCallback(ValueCallback callback){
    _channel.setMethodCallHandler((MethodCall call){
      callback(call.method,call.arguments);
    });
  }

  /// @args args 启动参数，必须保证appid参数传入，示例：appid=123456
  /// usr: 科大讯飞开发者在云平台上注册的账号。
  /// pwd: 科大讯飞账号对应的密码，与账号同时存在。
  /// 或者appid=12345678,usr=iflytekcloud,pwd=123456
  /// @return 成功返回true,失败返回false
  static Future<bool> setAppId(String args) async{
    final b = await _channel.invokeMethod('setAppId',{'args':args});
    return b;
  }

  /// 开始语音监听
  /// @return 成功返回true,失败返回false
  static Future<dynamic> startListening() async {
    return await _channel.invokeMethod('startListening');
  }

  static void requestPermission() async {
    await _channel.invokeMethod('requestPermission');
  }

  /// @msg 传入参数 文字转语音传入的参数
  /// @return 成功返回true,失败返回false
  static Future<bool> startSpeaking({@required String msg}) async{
    final b = await _channel.invokeMethod('startSpeaking',msg);
    return b;
  }

  /// @return 成功返回true,失败返回false ture表示文字转语音正在播放
  static Future<bool> get isSpeaking async{
    final b = await _channel.invokeMethod('isSpeaking');
    return b;
  }

  /// 取消本次会话
  static void cancel() async{
    await _channel.invokeMethod('cancel');
  }

  /// 销毁合成对象。
  /// @return 成功返回true,失败返回false
  static Future<bool> destroy() async{
    final b = await _channel.invokeMethod('destroy');
    return b;
  }

  /// 暂停播放
  /// 暂停播放之后，合成不会暂停，仍会继续，如果发生错误则会回调错误`onCompleted`
  static void pauseSpeaking() async{
    await _channel.invokeMethod('pauseSpeaking');
  }


  /// 恢复播放
  static void resumeSpeaking() async{
    await _channel.invokeMethod('resumeSpeaking');
  }

}
