#import <WatchConnectivity/WatchConnectivity.h>
#import <TroposCore/TroposCore.h>
#import <HockeySDK/HockeySDK.h>
#import "TRAppDelegate.h"
#import "TRAnalyticsController.h"
#import "TRApplicationController.h"

#ifndef DEBUG
#import "Secrets.h"
#endif

@interface TRAppDelegate () <WCSessionDelegate>
@end

@implementation TRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([self isCurrentlyTesting]) {
        return YES;
    }

#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:TRHockeyIdentifier];
    [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus:BITCrashManagerStatusAutoSend];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    [[TRAnalyticsController sharedController] install];
#endif

    [[TRSettingsController new] registerSettings];
    [[TRWatchUpdateController defaultController] activateSessionWithDelegate:self];

    self.applicationController = [TRApplicationController new];

    [self.applicationController setMinimumBackgroundFetchIntervalForApplication:application];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = self.applicationController.rootViewController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    RACSignal *signal = [self.applicationController performBackgroundFetch];

    [signal subscribeNext:^(id x) {
        completionHandler(UIBackgroundFetchResultNewData);
    } error:^(NSError *error) {
        completionHandler(UIBackgroundFetchResultFailed);
    }];
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext
{
    TRWeatherUpdate *update = [[TRWatchUpdateController defaultController] unpackWeatherUpdateFromContext:applicationContext];
    if (update) {
        [[TRWeatherUpdateCache new] archiveWeatherUpdate:update];
    }
}

- (BOOL)isCurrentlyTesting
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"TRTesting"];
}

@end
