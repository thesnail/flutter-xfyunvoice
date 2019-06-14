#import "XfyunvoicePlugin.h"

@interface XfyunvoicePlugin ()<IFlySpeechRecognizerDelegate,IFlySpeechSynthesizerDelegate>{
    NSString *_result; // 记录语音识别返回的结果
}

@end

@implementation XfyunvoicePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"xfyunvoice" binaryMessenger:[registrar messenger]];
  XfyunvoicePlugin* instance = [[XfyunvoicePlugin alloc] init];
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
  }else if([@"startListening" isEqualToString:call.method]){
      if (self.speechRecognizer == nil) {
          [self initRecognizer];
      }
      [_speechRecognizer cancel];
      
      [_speechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
      [_speechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
      [_speechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
      [_speechRecognizer setDelegate:self];
      if(_speechSynthesizer != nil){
          [_speechSynthesizer stopSpeaking];
      }
      [_speechRecognizer cancel];
      
      BOOL ret = [_speechRecognizer startListening];
      result(@(ret));
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
    NSLog(@"======>onCompleted     errorCode:%d",[error errorCode]);
    NSLog(@"======>onCompleted     errorDesc:%@",[error errorDesc]);
    NSLog(@"======>onCompleted     errorType:%d",[error errorType]);
    
    if(self.speechRecognizer != nil){
        [self.speechRecognizer cancel];
    }
}

- (void)onResults:(NSArray *)results isLast:(BOOL)islast{
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    NSString * resultFromJson = [self stringFromJson:resultString];
    if (_result == nil) {
        _result = @"";
    }
    _result = [NSString stringWithFormat:@"%@%@",_result,resultFromJson];
    if (islast){
        NSLog(@"======>语音识别结束onResults:%@",_result);
    }else{
        NSLog(@"======>语音识别onResults:%@",_result);
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
    //NSLog(@"======>onVolumeChanged  %d",volume);
}

- (void)onBeginOfSpeech{
    NSLog(@"======>开始语音识别onBeginOfSpeech  ");
}

- (void) onEndOfSpeech{
    NSLog(@"======>语音识别结束onEndOfSpeech:%@",_result);
}

- (void)onCancel{
    _result = @"";
    NSLog(@"======>语音识别结束->onCancel  ");
}

@end
