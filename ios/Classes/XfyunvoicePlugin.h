#import <Flutter/Flutter.h>
#import <iflyMSC/IFlyMSC.h>

@interface XfyunvoicePlugin : NSObject<FlutterPlugin>

@property (nonatomic, strong) IFlySpeechRecognizer *speechRecognizer;

@property (nonatomic, strong) IFlySpeechSynthesizer *speechSynthesizer;

@end
