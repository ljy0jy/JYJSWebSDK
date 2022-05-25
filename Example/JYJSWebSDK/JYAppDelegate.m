//
//  JYAppDelegate.m
//  JYJSWebSDK
//
//  Created by ljy0jy on 04/01/2022.
//  Copyright (c) 2022 ljy0jy. All rights reserved.
//

#import "JYAppDelegate.h"
#import "JYJSWebSDK/JYJSWebSDK.h"
@interface JYAppDelegate()
@property (nonatomic,strong) JYJSWebViewController *jyweb;
@end
@implementation JYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    JYJSWebViewController *jyweb = [[JYJSWebViewController alloc] init];
    jyweb.animationFile = @"loadingdata.json";
    jyweb.loadingType = LoadingTypeAnimation;
    jyweb.appId = @"1618396982";
    jyweb.appsflyerKey = @"xCdEAqFvxd49rLWbjod9DA";
    jyweb.appsflyerDebug = true;
    self.jyweb = jyweb;
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [UIViewController new];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = jyweb;
    jyweb.urlString = @"http://bitrun.saifurong.cn/home";
   
//    [jyweb loadJsonString:@"https://bitrun-jp.s3.amazonaws.com/bitrun.json" callback:^(id  _Nonnull responseData) {
//        self.window.rootViewController = jyweb;
//        jyweb.urlString = @"http://bitrun.saifurong.cn/home";
////        if (responseData) {
////
////            NSString *version = [NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
////            if(responseData[version]){
////                self.window.rootViewController = jyweb;
//////                jyweb.urlString = @"http://bitrun.saifurong.cn/home/";
////                jyweb.urlString = responseData[@"url"];
////
////            }
////        }
//    }];


    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.jyweb appsflyerStart];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
