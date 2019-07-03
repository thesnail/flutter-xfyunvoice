#import "XfyunvoicePlugin.h"

@interface XfyunvoicePlugin ()<IFlySpeechRecognizerDelegate,IFlySpeechSynthesizerDelegate>{
    NSString *_result; // 记录语音识别返回的结果
}


@end

@implementation XfyunvoicePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"xfyunvoice" binaryMessenger:[registrar messenger]];
    XfyunvoicePlugin* instance = [[XfyunvoicePlugin alloc] init];
    [instance setChannelMethod:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"setAppId" isEqualToString:call.method]) {
      NSDictionary *data = call.arguments;
      if([data objectForKey:@"args"]){
          NSString *appId = [NSString stringWithFormat: @"%@",[data objectForKey:@"args"]];
          NSLog(@"=======>appId:%@",appId);
          [IFlySpeechUtility createUtility:appId];
          if (self.speechRecognizer == nil) {
              [self initRecognizer];
          }
          result(@YES);
      }else{
          result(@NO);
      }
  }else if([@"requestPermission" isEqualToString: call.method]){
      NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
      if( [[UIApplication sharedApplication]canOpenURL:url] ) {
          [[UIApplication sharedApplication]openURL:url];
      }
  }else if([@"startListening" isEqualToString:call.method]){
      AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
      if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
          result(@{@"ret":@NO,@"msg":@"App未获得录音权限",@"code":@(-1)});
      }else{
          if (self.speechRecognizer == nil) {
              [self initRecognizer];
          }
          [_speechRecognizer cancel];
          if(_speechSynthesizer != nil){
              [_speechSynthesizer stopSpeaking];
          }
          [_speechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
          [_speechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
          [_speechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
          [_speechRecognizer setDelegate:self];
          BOOL ret = [_speechRecognizer startListening];
          
          result(@{@"ret":@(ret),@"msg":@"正在语音识别中",@"code":@0});
      }
  }else if([@"stopListening" isEqualToString:call.method]){
      if(_speechRecognizer != nil){
          [self.speechRecognizer stopListening];
      }
  }else if([@"cancel" isEqualToString:call.method]){
      if(_speechRecognizer != nil){
          [self.speechRecognizer cancel];
      }
  }else if([@"startSpeaking" isEqualToString:call.method]){
      NSString *msg = [NSString stringWithFormat: @"%@",call.arguments];
      if(_speechSynthesizer == nil){
          [self initSynthesizer];
      }
      [_speechSynthesizer stopSpeaking];
      [_speechSynthesizer setDelegate:self];
      [_speechSynthesizer startSpeaking: msg];
      result(@(YES));
  }else if([@"isSpeaking" isEqualToString:call.method]){
      if(_speechSynthesizer == nil){
          result(@(NO));
      }else{
          result(@([_speechSynthesizer isSpeaking]));
      }
  }else if([@"pauseSpeaking" isEqualToString:call.method]){
      if(_speechSynthesizer != nil){
          [_speechSynthesizer pauseSpeaking];
      }
  }else if([@"resumeSpeaking" isEqualToString:call.method]){
      if(_speechSynthesizer != nil){
          [_speechSynthesizer resumeSpeaking];
      }
  }else if([@"destroy" isEqualToString:call.method]){
      if(_speechSynthesizer == nil){
          result(@(NO));
      }else{
          result(@([IFlySpeechSynthesizer destroy]));
      }
  }else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)initSynthesizer{
    if(_speechSynthesizer == nil){
        _speechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    }
    [[IFlySpeechUtility getUtility] setParameter:@"tts" forKey:[IFlyResourceUtil ENGINE_START]];
    
    [_speechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant SPEED]];
    [_speechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant VOLUME]];
    [_speechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant PITCH]];
    [_speechSynthesizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    [_speechSynthesizer setParameter:@"xiaoyan" forKey:[IFlySpeechConstant VOICE_NAME]];
    [_speechSynthesizer setParameter:@"unicode" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    [_speechSynthesizer setParameter:@"cloud" forKey:[IFlySpeechConstant ENGINE_TYPE]];
}

-(void)initRecognizer{
    if (self.speechRecognizer == nil) {
        [self setSpeechRecognizer:[IFlySpeechRecognizer sharedInstance]];
    }
    [self.speechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [self.speechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    if (_speechRecognizer != nil) {
        [_speechRecognizer setParameter:@"30000" forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        [_speechRecognizer setParameter:@"2000" forKey:[IFlySpeechConstant VAD_EOS]];
        [_speechRecognizer setParameter:@"3000" forKey:[IFlySpeechConstant VAD_BOS]];
        [_speechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        [_speechRecognizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
        [_speechRecognizer setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
        [_speechRecognizer setParameter:@"mandarin" forKey:[IFlySpeechConstant ACCENT]];
        [_speechRecognizer setParameter:@"0" forKey:[IFlySpeechConstant ASR_PTT]];
        
        [_speechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        [_speechRecognizer setParameter:IFLY_AUDIO_SOURCE_STREAM forKey:@"audio_source"];
    }
}



- (void)onCompleted:(IFlySpeechError *)error{
    if(self.speechRecognizer != nil){
        [self.speechRecognizer cancel];
    }
    if(_channelMethod != nil && error != nil){
        NSDictionary *data = @{
                               @"code":@(error.errorCode),
                               @"desc":error.errorDesc,
                               @"type":@(error.errorType)};
        [_channelMethod invokeMethod:@"onCompleted" arguments:data];
    }
}

- (void)onResults:(NSArray *)results isLast:(BOOL)islast{
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    NSString * resultFromJson = [self stringFromJson:resultString];
    _result = [NSString stringWithFormat:@"%@%@",_result,resultFromJson];
    
    if(_channelMethod != nil){
        [_channelMethod invokeMethod:@"onResults" arguments:@{@"result":_result,@"isLast":@(islast)}];
    }
}

-(NSString *)stringFromJson:(NSString*)params{
    if (params == NULL) {
        return nil;
    }
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:
                                [params dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    if (resultDic!= nil) {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];
        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex: i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString: str];
            }
        }
    }
    return tempStr;
}

- (void)onVolumeChanged:(int)volume{
    if(_channelMethod != nil){
        [_channelMethod invokeMethod:@"onVolumeChanged" arguments:@{@"volume":@(volume)}];
    }
}

- (void)onBeginOfSpeech{
    _result = @"";
    if(_channelMethod != nil){
        [_channelMethod invokeMethod:@"onBeginOfSpeech" arguments:@{}];
    }
}

- (void) onEndOfSpeech{
    if(_channelMethod != nil){
        [_channelMethod invokeMethod:@"onEndOfSpeech" arguments:@{@"result":_result}];
    }
}

- (void)onCancel{
    if(_channelMethod != nil){
        [_channelMethod invokeMethod:@"onCancel" arguments:@{}];
    }
}

@end
