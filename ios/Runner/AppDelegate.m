#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"



@import Firebase;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
    if (FIRApp.defaultApp == nil) {
        [FIRApp configure];
    }
    
    /*
    self.uploading = 0;
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel* uploadChannel = [FlutterMethodChannel methodChannelWithName:@"samples.flutter.dev/upload" binaryMessenger: controller];
    
    __weak typeof(self) weakSelf = self;
    [uploadChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result){
        if ( [@"uploadVideo" isEqualToString:call.method] ){
            NSString* path = call.arguments[@"path"];
            NSString* partNum = call.arguments[@"partNum"];
            
            int ret = [weakSelf uploadVideo:path partNum:partNum];
            result(@(ret));
        }
        else if ( [@"checkUpload" isEqualToString:call.method] ){
            result(@(self.uploading));
        }
    }];
    */
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

/*
- (int)uploadVideo:(NSString*) path partNum:(NSString*) partNum{
    NSLog(@"%@======%@", path, partNum);
    
    if ( self.uploading == 1 ){
        return 0;
    }
    
    self.uploading = 1;
    
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"upload1"];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 10;
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURL* localUrl = [NSURL URLWithString:@""];
    NSURL* url = [NSURL URLWithString:@""];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL: url];
    [request setValue:<#(nullable id)#> forKey:@"]
    [request setHTTPMethod:@"POST"];
    NSURLSessionUploadTask* uploadTask = [session uploadTaskWithRequest:request fromFile:localUrl completionHandler:^(NSData* data, NSURLResponse* response, NSError* error){
        self.uploading = 2;
    }];
    [uploadTask resume];
    
    return 1;
}

*/

@end
