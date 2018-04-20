//
//UnityToXcodeBridge.h
//
//Acts as a bridge between Unity and Xcode
//allowing information to be passed between the two
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <HealthKit/HealthKit.h>
#import <CoreMotion/CoreMotion.h>

@interface UnityToXcodeBridge : NSObject <WCSessionDelegate>
{
    @public NSString *heartRateValueReceivedFromWatch;
    @public NSString *returnedStepCountValue;
    @public NSString *buttonPressReceivedFromWatch;
}
//Stores the heart rate value received from the watch
@property (nonatomic, retain) NSString *heartRateValueReceivedFromWatch;
//Stores the step count value received from the watch
@property (nonatomic, retain) NSString *stepCountValueReceivedFromWatch;
//Stores any button press received from the watch
@property (nonatomic, retain) NSString *buttonPressReceivedFromWatch;
//Reference to the HealthStore, used by HealthKit
@property (nonatomic, strong) HKHealthStore *healthStore;
//Stores a reference to a CMPedometer, that is used to force the Motion & Fitness permission popup
//to appear on the phone and at the initial launch of the application
@property (strong, nonatomic) CMPedometer *pedometer;

//Reference to the stored instance of UnityToXcodeBridge
+ (UnityToXcodeBridge*) instance;
//Initialization method for UnityToXcode
- (id)  init;
//Starts recording the heart rate
- (void)startHeartRate;
//Stops recording the heart rate
- (void)stopHeartRate;
//Starts streaming the Pedometer
- (void)startPedometer;
//Stops streaming the Pedometer
- (void)stopPedometer;
//Sends a character string to the watch with a specific key
- (void)sendCharToWatch:(const char*) message WithKey:(NSString*) key;
//Sends image data to the watch
- (void)sendImageToWatchApp:(NSData*)dataToSend;

@end
