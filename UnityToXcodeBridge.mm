//
//UnityToXcodeBridge
//
//Implementation of UnityToXcodeBridge class
//

#import "UnityToXcodeBridge.h"

#pragma mark - PRIVATE -

@implementation UnityToXcodeBridge

@synthesize heartRateValueReceivedFromWatch;
@synthesize stepCountValueReceivedFromWatch;
@synthesize buttonPressReceivedFromWatch;

//Static reference to the UnityToXcodeBridge class
static UnityToXcodeBridge * unityToXcode;

/// <summary>
/// Returns the reference to the UnityToXcodeBridge.
/// </summary>
+ (UnityToXcodeBridge*) instance
{
    @synchronized (self)
    {
        //If it hasn't been initialized then initialize it
        if(unityToXcode == nil)
        {
            unityToXcode = [[self alloc] init];
        }
    }
    return unityToXcode;
}

/// <summary>
/// Initializes the UnityToXcodeBridge class.
/// </summary>
-(id) init
{
    //Set initial values
    heartRateValueReceivedFromWatch = @"0";
    stepCountValueReceivedFromWatch = @"0";
    buttonPressReceivedFromWatch = @"None";
    
    //Check if healthData is available
    if([HKHealthStore isHealthDataAvailable])
    {
        //Initialize the healthStore
        self.healthStore = [[HKHealthStore alloc] init];
    }
    
    //Check if WatchConnectivity is supported by this device
    if([WCSession isSupported])
    {
        //Activate the session
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        
        //Request Authorization to share some health data
        [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]] readTypes:[NSSet setWithObject:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]] completion:^(BOOL success, NSError *error){
            if(!success){
                NSLog(@"%@", error);
            }
            else //if no errors occur then ask for permission to use the pedometer
            {
                if(!self.pedometer)
                {
                    //Initialize the pedometer
                    self.pedometer = [[CMPedometer  alloc] init];
                    //Query for the pedometer data, this forces the Motion & Fitness permission request to popup
                    [self.pedometer queryPedometerDataFromDate:[NSDate date] toDate:[NSDate date] withHandler:
                     ^(CMPedometerData* data, NSError *error)
                    {
                        if(error != nil)
                        {
                            NSLog(@"Error: %@",error.localizedFailureReason);
                        }
                    }];
                }
            }
        }];

    }
    else
    {
        NSLog(@"WatchConnectivity is not supported on this device");
    }
    return [super init];
}

/// <summary>
/// Receives messages sent from the watch
/// Gets called automatically when the phone receives a message from the watch.
/// </summary>
/// <param name="message">A dictionary that holds the messages received and a key with each message.</param>
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    //If the dictionary contains a message with the key below (used when the watch sends a heart rate)
    if([message objectForKey:@"returnedHeartRateValueKey"] != nil)
    {
        //Set the heart rate received
        heartRateValueReceivedFromWatch = [message objectForKey:@"returnedHeartRateValueKey"];
		NSLog(@"%@", heartRateValueReceivedFromWatch);
    }
    //else if the dictionary contains a message with the key below (used when the watch sends the step count)
    else if([message objectForKey:@"returnedStepCountValueKey"] != nil)
    {
        //Store the received step count
        stepCountValueReceivedFromWatch = [message objectForKey:@"returnedStepCountValueKey"];
        NSLog(@"%@", stepCountValueReceivedFromWatch);
    }
    //else if the dictionary contains a message with the key below
	//This will happen when a button is pressed on the watch
    else if([message objectForKey:@"ButtonPressed"] != nil)
    {
        //Store the received button press
        buttonPressReceivedFromWatch = [message objectForKey:@"ButtonPressed"];
        NSLog(@"%@", buttonPressReceivedFromWatch);
    }
}

/// <summary>
/// Sends a message to the watch to start the heart rate recording on the watch.
/// </summary>
- (void)startHeartRate
{
    //Reset the heartRateValueReceivedFromWatch
    heartRateValueReceivedFromWatch = 0;
    
    //Send the StartHeartRate message to the watch
    [[UnityToXcodeBridge instance] sendCharToWatch:"StartHeartRate" WithKey:@"Message"];
}

/// <summary>
/// Sends a message to the watch to stop the heart rate recording on the watch.
/// </summary>
- (void)stopHeartRate
{
    //Send the StopHeartRate message to the watch
    [[UnityToXcodeBridge instance] sendCharToWatch:"StopHeartRate" WithKey:@"Message"];
}

/// <summary>
/// Sends a message to the watch to activate the pedometer reading
/// </summary>
- (void)startPedometer
{
    //Reset the stepCountValueReceivedFromWatch
    stepCountValueReceivedFromWatch = 0;
    
    //Send the StartPedometer message to the watch
    [[UnityToXcodeBridge instance] sendCharToWatch:"StartPedometer" WithKey:@"Message"];
}

/// <summary>
/// Sends a message to the watch to stop the pedometer reading.
/// </summary>
- (void)stopPedometer
{
    //Send the StopPedometer message to the watch
    [[UnityToXcodeBridge instance] sendCharToWatch:"StopPedometer" WithKey:@"Message"];
}

/// <summary>
/// Send "message" to the watch with "key".
/// </summary>
/// <param name="message">the const char* that will be sent.</param>
/// <param name="key">The key that gets passed with the message.</param>
- (void)sendCharToWatch:(const char*) message WithKey:(NSString*) key
{
    NSError *error;
    
    NSLog(@"%s", message);
    
    if(![[WCSession defaultSession] transferUserInfo:@{key : [NSString stringWithUTF8String:message]}])
    {
        NSLog(@"SendCharToWatch failed with error %@", error);
    }
}

/// <summary>
/// Send NSData* "dataToSend" to the watch. Used for sending images to the Watch
/// Breaks the data up into managable chunks that the watch can handle
/// </summary>
/// <param name="dataToSend">image data that is being sent to the watch.</param>
- (void)sendImageToWatchApp:(NSData*)dataToSend
{
	//Number of pieces to break the data into
    int pieces = 4;
    
    //Break up the data into small enough sizes to send to the watch
    NSData *chunkOfImageData = [dataToSend subdataWithRange:NSMakeRange(0, dataToSend.length/pieces)];
    
	//Add the data to mutableData (this way we can add bytes to the end of it)
    NSMutableData *mutableData = [NSMutableData dataWithBytes:chunkOfImageData.bytes length:chunkOfImageData.length];
    
    for(int i = 0; i<pieces; i++)
    {
		//Set the data for this chunk
        chunkOfImageData = [dataToSend subdataWithRange:NSMakeRange((i * dataToSend.length) / pieces, dataToSend.length / pieces)];
		//Set mutableData to this chunk of data
        mutableData = [NSMutableData dataWithBytes:chunkOfImageData.bytes length:chunkOfImageData.length];
		//Create an array of 4 bytes all set to zero
		//These bytes will be extracted from the received data on the watch to determine
		//if the packet of data the watch receives is the last packet for the image or not
        char bytes[4] = {0,0,0,0};
		//If sending the last piece of data then set the bytes to one
        if(i == pieces-1)
        {
            bytes[0] = 1;
            bytes[1] = 1;
            bytes[2] = 1;
            bytes[3] = 1;
        }
        
		//Add the bytes onto the end of the mutableData
        [mutableData appendBytes:bytes length:sizeof(bytes)];
    
		//If the watch is reachable
        if([[WCSession defaultSession] isReachable])
        {
			//Send the data to the watch
            [[WCSession defaultSession] sendMessageData:[NSData dataWithData:mutableData]//Create an NSData object out of the NSMutableData object
                                           replyHandler:^(NSData *reply){
                                               NSLog(@"Successful");
                                           }
                                           errorHandler:^(NSError *NSError){
                                               NSLog(@"%@",NSError);
                                           }
             ];}
        else
        {
            NSLog(@"Watch session is unreachable");
        }
    }
}

@end


#pragma mark - EXTERN -

//These are the methods used in Unity to call Objective c code
extern "C"
{
    /// <summary>
    /// Returns the stored Heart Rate.
    /// </summary>
    double GetHeartRateFromWatch()
    {
        double numRepresentationOfHeartRate = [[UnityToXcodeBridge instance].heartRateValueReceivedFromWatch doubleValue];
        return numRepresentationOfHeartRate;
    }
    
    /// <summary>
    /// Returns the stored Step Count.
    /// </summary>
    double GetStepCountFromWatch()
    {
        double numRepresentationOfStepCount = [[UnityToXcodeBridge instance].stepCountValueReceivedFromWatch doubleValue];
        return numRepresentationOfStepCount;
    }
    
    /// <summary>
    /// Starts recording Heart Rate on the watch.
    /// </summary>
    void StartRecordingHeartRate()
    {
        [[UnityToXcodeBridge instance] startHeartRate];
    }
    
    /// <summary>
    /// Stops recording Heart Rate on the watch.
    /// </summary>
    void StopRecordingHeartRate()
    {
        [[UnityToXcodeBridge instance] stopHeartRate];
    }
    
    /// <summary>
    /// Starts streaming the pedometer from the watch.
    /// </summary>
    void StartStreamingPedometer()
    {
        [[UnityToXcodeBridge instance] startPedometer];
    }
    
    /// <summary>
    /// Stops streaming the pedometer on the watch.
    /// </summary>
    void StopStreamingPedometer()
    {
        [[UnityToXcodeBridge instance] stopPedometer];
    }
    
    /// <summary>
    /// Send const char* "inputMessage" to the watch.
    /// Intended to be used as way for communicating button presses on the phone to the watch
    /// </summary>
    /// <param name="inputMessage">const char* message sent to the watch.</param>
    void SendInputToXcode(const char* inputMessage)
    {
        //Sends the message with the key "Input"
        [[UnityToXcodeBridge instance] sendCharToWatch:inputMessage WithKey:@"Input"];
    }
    
    /// <summary>
    /// Send const char* "message" to the watch.
    /// used for sending messages to the watch
    /// </summary>
    /// <param name="message">const char* message sent to the watch.</param>
    void SendMessageToXcode(const char* message)
    {
        [[UnityToXcodeBridge instance] sendCharToWatch:message WithKey:@"Message"];
    }

    
    /// <summary>
    /// Returns "buttonPressReceivedFromWatch" if it isn't nil.
	/// Sends button press to the phone that were received from the watch
    /// </summary>
    const char* GetButtonPressFromWatch()
    {
        if([UnityToXcodeBridge instance].buttonPressReceivedFromWatch != nil)
        {
            const char *constCharToSendToPhone = strdup([[UnityToXcodeBridge instance].buttonPressReceivedFromWatch UTF8String]);
            NSLog(@"%s", constCharToSendToPhone);
            return constCharToSendToPhone;
        }
        else
        {
            return "";
        }
    }
    
    /// <summary>
    /// Send the texture to the watch.
    /// </summary>
    /// <param name="texture">a pointer to the texture.</param>
    /// <param name="width">width of the texture.</param>
    /// <param name="height">height of the texture.</param>
    void SendImageToWatch(UInt8* texture, int width, int height)
    {
        //Get the length of the data
        NSInteger dataLength = width*height*sizeof(UInt8);
        //Get the image data
        NSData* imageData = [[NSData alloc] initWithBytes:(void*)texture length:dataLength];
        //Send it to the watch
        [[UnityToXcodeBridge instance] sendImageToWatchApp:imageData];
    }
    
	/// <summary>
    /// Send a message to the watch telling it which file to display as the background on the watch.
    /// </summary>
    /// <param name="fileName">a const char* that represents the fileName of the image to use as the background.</param>
    void SendImageFileNameToWatch(const char* fileName)
    {
        [[UnityToXcodeBridge instance] sendCharToWatch:fileName WithKey:@"Background"];
    }
}




