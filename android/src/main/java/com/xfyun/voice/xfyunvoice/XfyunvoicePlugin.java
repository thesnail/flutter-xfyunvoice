package com.xfyun.voice.xfyunvoice;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechSynthesizer;
import com.iflytek.cloud.SpeechUtility;
import com.iflytek.cloud.SynthesizerListener;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/** XfyunvoicePlugin */
public class XfyunvoicePlugin implements MethodCallHandler {

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
      Log.e(TAG,"initListener ======>onInit  i:"+i);
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
  SynthesizerListener syListener = new SynthesizerListener() {
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
    public void onCompleted(SpeechError error) {
      if(channel != null){
        Map<String,Object> data = new HashMap();
        if(error != null){
          data.put("code",error.getErrorCode());
          data.put("desc",error.getErrorDescription());
        }
        data.put("type",0);
        channel.invokeMethod("onCompleted",data);
      }
    }

    @Override
    public void onEvent(int i, int i1, int i2, Bundle bundle) {

    }
  };

  RecognizerListener reListener = new RecognizerListener() {
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
      if(channel != null){ }
    }

    private HashMap<String, String> mIatResults = new LinkedHashMap<>();

    @Override
    public void onResult(RecognizerResult result, boolean b) {
      String text = JsonParser.parseIatResult(result.getResultString());
      String sn = null;
      try {
        JSONObject resultJson = new JSONObject(result.getResultString());
        sn = resultJson.optString("sn");
      } catch (Exception e) {
        e.printStackTrace();
      }
      mIatResults.put(sn, text);
      StringBuilder resBuffer = new StringBuilder();
      for (String key : mIatResults.keySet()) {
        resBuffer.append(mIatResults.get(key));
      }
      _result = resBuffer.toString();
      if(channel != null){
        Map<String,Object> data = new HashMap<>();
        data.put("result",_result);
        data.put("isLast",b);
        channel.invokeMethod("onResults",data);
        if(b){
          Map<String,String> map = new HashMap<>();
          map.put("result",_result);
          channel.invokeMethod("onEndOfSpeech",map);
        }
      }
    }

    @Override
    public void onError(SpeechError error) {
      if(channel != null){
        Map<String,Object> data = new HashMap<>();
        if(error != null){
          data.put("code",error.getErrorCode());
          data.put("desc",error.getErrorDescription());
        }
        data.put("type",0);
        channel.invokeMethod("onError",data);
      }
    }
    @Override
    public void onEvent(int i, int i1, int i2, Bundle bundle) {}
  };

  private void startListening(Result result){
    if(synthesizer != null){
      synthesizer.stopSpeaking();
    }
    if(recognizer == null){
      initRecognizer();
    }else{
      recognizer.cancel();
    }
    recognizer.setParameter("audio_source","1");
    recognizer.setParameter(SpeechConstant.RESULT_TYPE,"json");
    recognizer.setParameter(SpeechConstant.ASR_AUDIO_PATH,"asr.pcm");
    int ret = recognizer.startListening(reListener);
    Map<String,Object> data = new LinkedHashMap<>();
    data.put("ret",ret);
    data.put("msg","正在语音识别中");
    data.put("code",0);
    result.success(data);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if("setAppId".equals(call.method)){
      try {
        String data = call.argument("args");
        SpeechUtility.createUtility(activity,data);
        result.success(true);
      } catch (Exception e) {
        e.printStackTrace();
        result.success(false);
      }
    }else if("requestPermission".equals(call.method)){
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        int permission = activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO);
        if(permission != PackageManager.PERMISSION_GRANTED){
          ActivityCompat.requestPermissions(activity,new String[]{Manifest.permission.RECORD_AUDIO},101);
        }
      }
    }else if("startListening".equals(call.method)){
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        if(activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED){
          Map<String,Object> data = new LinkedHashMap<>();
          data.put("ret",false);
          data.put("msg","App未获得录音权限");
          data.put("code",-1);
          result.success(data);
        }else{
          startListening(result);
        }
      }else{
        startListening(result);
      }
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
      synthesizer.startSpeaking(msg,syListener);
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
}
