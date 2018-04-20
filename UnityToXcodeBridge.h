//
//UnityToXcodeBridge.h
//
//Acts as a bridge between Unity and Xcode
//allowing information to be passed between the two
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <HealthKit/HealthKit.h>

@interface UnityToXcodeBridge : NSObject <WCSessionDelegate>
{
    @public NSString *returnedValue;
    @public NSString *messageReceived;
}
//Stores any returned values from the watch, used for the heart rate
@property (nonatomic, retain) NSString *returnedValue;
//Stores any message received from the watch
@property (nonatomic, retain) NSString *messageReceived;
//Reference to the HealthStore, used by HealthKit
@property (nonatomic, strong) HKHealthStore *healthStore;

//Reference to the stored instance of UnityToXcodeBridge
+ (UnityToXcodeBridge*) instance;
//Initialization method for UnityToXcode
- (id)  init;
//Starts recording the heart rate
- (void)startHeartRate;
//Stops recording the heart rate
- (void)stopHeartRate;
//Sends a character string to the watch with a specific key
- (void)sendCharToWatch:(const char*) message WithKey:(NSString*) key;
//Sends image data to the watch
- (void)sendImageToWatchApp:(NSData*)dataToSend;

@end
