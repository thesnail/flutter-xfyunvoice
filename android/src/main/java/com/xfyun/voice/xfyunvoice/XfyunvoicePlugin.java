package com.xfyun.voice.xfyunvoice;

import android.Manifest;
import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechSynthesizer;
import com.iflytek.cloud.SpeechUtility;
import com.iflytek.cloud.SynthesizerListener;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** XfyunvoicePlugin */
public class XfyunvoicePlugin implements MethodCallHandler,RecognizerListener,SynthesizerListener {

  public final static String TAG = XfyunvoicePlugin.class.getName();

  private static Activity activity;

  private String _result = "";

  private static SpeechSynthesizer synthesizer;
  private static SpeechRecognizer recognizer;
  private static MethodChannel channel;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    activity = registrar.activity();
    channel = new MethodChannel(registrar.messenger(), "xfyunvoice");
    channel.setMethodCallHandler(new XfyunvoicePlugin());
  }


  private void initRecognizer(){
    if(recognizer == null){
      recognizer = SpeechRecognizer.createRecognizer(activity,initListener);
    }
    recognizer.setParameter(SpeechConstant.CLOUD_GRAMMAR, null );
    recognizer.setParameter(SpeechConstant.SUBJECT, null );

    recognizer.setParameter(SpeechConstant.KEY_SPEECH_TIMEOUT,"30000");
    recognizer.setParameter(SpeechConstant.VAD_BOS,"3000");
    recognizer.setParameter(SpeechConstant.VAD_EOS,"2000");
    recognizer.setParameter(SpeechConstant.NET_TIMEOUT,"10000");
    recognizer.setParameter(SpeechConstant.SAMPLE_RATE,"16000");
    recognizer.setParameter(SpeechConstant.LANGUAGE,"zh_cn");
    recognizer.setParameter(SpeechConstant.ACCENT,"mandarin");
    recognizer.setParameter(SpeechConstant.ASR_PTT,"0");
  }

  InitListener initListener = new InitListener() {
    @Override
    public void onInit(int i) {

    }
  };

  private void initSynthesizer(){
    if(synthesizer == null){
      synthesizer = SpeechSynthesizer.createSynthesizer(activity,initListener);
    }
    SpeechUtility.getUtility().setParameter(SpeechConstant.TTS_PLAY_STATE,"tts");
    synthesizer.setParameter(SpeechConstant.SPEED,"50");
    synthesizer.setParameter(SpeechConstant.VOLUME,"50");
    synthesizer.setParameter(SpeechConstant.PITCH,"50");
    synthesizer.setParameter(SpeechConstant.SAMPLE_RATE,"16000");
    synthesizer.setParameter(SpeechConstant.VOICE_NAME,"xiaoyan");
    synthesizer.setParameter(SpeechConstant.TEXT_ENCODING,"unicode");
    synthesizer.setParameter(SpeechConstant.ENGINE_TYPE,"cloud");
  }




  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if("setAppId".equals(call.method)){
      String data = call.argument("args");
      SpeechUtility.createUtility(activity,data);
      result.success(true);
    }else if("startListening".equals(call.method)){
      if(synthesizer != null){
        synthesizer.stopSpeaking();
      }
      if(recognizer == null){
        initRecognizer();
      }
      recognizer.cancel();

      recognizer.setParameter("audio_source","1");
      recognizer.setParameter(SpeechConstant.RESULT_TYPE,"json");
      recognizer.setParameter(SpeechConstant.ASR_AUDIO_PATH,"asr.pcm");

      recognizer.startListening(this);
    }else if("stopListening".equals(call.method)){
      if(recognizer != null){
        recognizer.stopListening();
      }
    }else if("cancel".equals(call.method)){
      if(recognizer != null){
        recognizer.cancel();
      }
    }else if("startSpeaking".equals(call.method)){
      String msg = call.arguments();
      if(synthesizer == null){
        initSynthesizer();
      }
      synthesizer.startSpeaking(msg,this);
    }else if("isSpeaking".equals(call.method)){
      if(synthesizer != null){
        result.success(synthesizer.isSpeaking());
      }else{
        result.success(false);
      }
    }else if("pauseSpeaking".equals(call.method)){
      if(synthesizer != null){
        synthesizer.pauseSpeaking();
      }
    }else if("resumeSpeaking".equals(call.method)){
      if(synthesizer != null){
        synthesizer.resumeSpeaking();
      }
    }else if("destroy".equals(call.method)){
      if(recognizer != null){
        recognizer.destroy();
      }
    }else {
      result.notImplemented();
    }
  }

  @Override
  public void onVolumeChanged(int i, byte[] bytes) {
    if(channel != null){
      Map<String,Integer> data = new HashMap<>();
      data.put("volume",i);
      channel.invokeMethod("onVolumeChanged",data);
    }
  }

  @Override
  public void onBeginOfSpeech() {
    if(channel != null){
      Map<String,Integer> data = new HashMap<>();
      channel.invokeMethod("onBeginOfSpeech",data);
    }
  }

  @Override
  public void onEndOfSpeech() {
    if(channel != null){
      Map<String,String> data = new HashMap<>();
      data.put("result",_result);
      channel.invokeMethod("onEndOfSpeech",data);
    }
  }

  @Override
  public void onResult(RecognizerResult recognizerResult, boolean b) {
    if(channel != null){
      Map<String,Object> data = new HashMap<>();
      data.put("result",_result);
      data.put("isLast",b);
      channel.invokeMethod("onResults",data);
    }
  }

  @Override
  public void onError(SpeechError speechError) {
    if(channel != null){
      Map<String,Object> data = new HashMap<>();
      data.put("code",speechError.getErrorCode());
      data.put("desc",speechError.getErrorDescription());
      data.put("type",0);
      channel.invokeMethod("onError",data);
    }
  }

  @Override
  public void onSpeakBegin() {
    _result = "";
    if(channel != null){
      Map<String,Object> data = new HashMap<>();
      channel.invokeMethod("onBeginOfSpeech",data);
    }
  }

  @Override
  public void onBufferProgress(int i, int i1, int i2, String s) {

  }

  @Override
  public void onSpeakPaused() {

  }

  @Override
  public void onSpeakResumed() {

  }

  @Override
  public void onSpeakProgress(int i, int i1, int i2) {

  }

  @Override
  public void onCompleted(SpeechError speechError) {
    if(channel != null){
      Map<String,Object> data = new HashMap();
      data.put("code",speechError.getErrorCode());
      data.put("desc",speechError.getErrorDescription());
      data.put("type",0);
      channel.invokeMethod("onCompleted",data);
    }
  }

  @Override
  public void onEvent(int i, int i1, int i2, Bundle bundle) {

  }
}
