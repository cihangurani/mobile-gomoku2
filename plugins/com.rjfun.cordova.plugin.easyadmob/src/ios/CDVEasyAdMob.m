//
//  CDVEasyAdMobMob.m
//  Ad Plugin for PhoneGap
//
//  Created by Liming Xie, 2014-7-28.
//
//  Copyright 2014 Liming Xie. All rights reserved.

#import <CommonCrypto/CommonDigest.h>
#import "CDVEasyAdMob.h"
#import "GADAdMobExtras.h"
#import "MainViewController.h"

@interface CDVEasyAdMob()

- (void) __setOptions:(NSDictionary*) options;
- (void) __createBanner;
- (void) __showAd:(BOOL)show;
- (bool) __isLandscape;
- (void) __showInterstitial:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString*) __md5: (NSString*) s;

@end

@implementation CDVEasyAdMob

@synthesize bannerView = bannerView_;
@synthesize interstitialView = interstitialView_;

@synthesize publisherId, interstitialAdId, adSize;
@synthesize bannerAtTop, bannerOverlap, offsetTopBar;
@synthesize isTesting, adExtras;

@synthesize bannerIsVisible, bannerIsInitialized;
@synthesize bannerShow, autoShow;

#define DEFAULT_PUBLISHER_ID    @"ca-app-pub-6869992474017983/4806197152"

#define OPT_PUBLISHER_ID    @"publisherId"
#define OPT_INTERSTITIAL_ADID   @"interstitialAdId"
#define OPT_AD_SIZE         @"adSize"
#define OPT_BANNER_AT_TOP   @"bannerAtTop"
#define OPT_OVERLAP         @"overlap"
#define OPT_OFFSET_TOPBAR   @"offsetTopBar"
#define OPT_IS_TESTING      @"isTesting"
#define OPT_AD_EXTRAS       @"adExtras"
#define OPT_AUTO_SHOW       @"autoShow"

#pragma mark Cordova JS bridge

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView {
  self = (CDVEasyAdMob *)[super initWithWebView:theWebView];
  if (self) {
    // These notifications are required for re-placing the ad on orientation
    // changes. Start listening for notifications here since we need to
    // translate the Smart Banner constants according to the orientation.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(deviceOrientationChange:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];

      bannerShow = false;
      publisherId = DEFAULT_PUBLISHER_ID;
      interstitialAdId = DEFAULT_PUBLISHER_ID;
      adSize = [self __AdSizeFromString:@"SMART_BANNER"];
      
      bannerAtTop = false;
      bannerOverlap = false;
      offsetTopBar = false;
      isTesting = false;
      
      autoShow = false;
      
      bannerIsInitialized = false;
      bannerIsVisible = false;
  }
  return self;
}

- (void) setOptions:(CDVInvokedUrlCommand *)command
{
    NSLog(@"setOptions");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
	NSUInteger argc = [args count];
    if( argc >= 1 ) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showBanner:(CDVInvokedUrlCommand *)command
{
    NSLog(@"showBanner");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

	NSUInteger argc = [args count];
    if( argc >= 1 ) {
        bannerShow = [[args objectAtIndex:0] boolValue];
    }
    if(bannerShow && (argc >= 2)) {
        NSDictionary* options = [command.arguments objectAtIndex:1 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    if(self.bannerView != nil) {
        [self __showAd:bannerShow];
        
    } else {
        [self __createBanner];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showAd:(CDVInvokedUrlCommand *)command
{
    NSLog(@"showAd");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;

	NSUInteger argc = [arguments count];
	if (argc >= 1) {
        NSString* showValue = [arguments objectAtIndex:0];
        BOOL show = showValue ? [showValue boolValue] : YES;
        [self __showAd:show];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) removeBanner:(CDVInvokedUrlCommand *)command
{
    NSLog(@"removeBanner");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    
    if(self.bannerView) {
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
        
        [self resizeViews];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) requestInterstitial:(CDVInvokedUrlCommand *)command
{
    NSLog(@"requestInterstitial");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self __cycleInterstitial];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showInterstitial:(CDVInvokedUrlCommand *)command
{
    NSLog(@"showInterstitial");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    [self __showInterstitial:YES];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.bannerView) {
        
        CGRect superViewFrame = self.webView.superview.frame;
        if([self __isLandscape]) {
            superViewFrame.size.width = self.webView.superview.frame.size.height;
            superViewFrame.size.height = self.webView.superview.frame.size.width;
        }
        
        CGRect adViewFrameNew = self.bannerView.frame;
        adViewFrameNew.size = [self.bannerView sizeThatFits:superViewFrame.size];
        self.bannerView.frame = adViewFrameNew;
        
        [self resizeViews];
    }
}

- (void)resizeViews {
    // Frame of the main container view that holds the Cordova webview.
    CGRect superViewFrame = self.webView.superview.frame;
    // Frame of the main Cordova webview.
    CGRect webViewFrame = self.webView.frame;
    
    // Let's calculate the new position and size
    CGRect superViewFrameNew = superViewFrame;
    CGRect webViewFrameNew = webViewFrame;
    
    bool isLandscape = [self __isLandscape];
    if( isLandscape ) {
        superViewFrameNew.size.width = superViewFrame.size.height;
        superViewFrameNew.size.height = superViewFrame.size.width;
    }
    
    // ensure y = 0, as strange that sometimes not 0 ?
    superViewFrameNew.origin.y = 0;
    
    // If the ad is not showing or the ad is hidden, we don't want to resize anything.
    BOOL adIsShowing = (self.bannerView != nil) &&
    [self.webView.superview.subviews containsObject:self.bannerView] &&
    (! self.bannerView.hidden);
    
    if(adIsShowing) {
        // Handle changing Smart Banner constants for the user.
        if( isLandscape ) {
            if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerLandscape)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
            }
        } else {
            if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerPortrait)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
            }
        }
        
        CGRect bannerViewFrame = self.bannerView.frame;
        CGRect bannerViewFrameNew = bannerViewFrame;
        
        bannerViewFrameNew.origin.x = (superViewFrameNew.size.width - bannerViewFrameNew.size.width) * 0.5f;
        
        // iOS7 Hack, handle the Statusbar
        MainViewController *mainView = (MainViewController*) self.webView.superview.window.rootViewController;
        BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
        CGFloat top = isIOS7 ? mainView.topLayoutGuide.length : 0.0;
        
        if(! self.offsetTopBar) top = 0.0;
        
        // banner overlap webview, no resizing needed, but we need bring banner over webview, and put it center.
        if(self.bannerOverlap) {
            webViewFrameNew.origin.y = top;
            
            if(self.bannerAtTop) {
                bannerViewFrameNew.origin.y = top;
            } else {
                bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
            }
            
            [self.webView.superview bringSubviewToFront:self.bannerView];
            
        } else {
            if(self.bannerAtTop) {
                // move banner view to top
                bannerViewFrameNew.origin.y = top;
                
                // move the web view to below
                webViewFrameNew.origin.y = bannerViewFrameNew.origin.y + bannerViewFrameNew.size.height;
                webViewFrameNew.size.height = superViewFrameNew.size.height - webViewFrameNew.origin.y;
            } else {
                // move the banner view to below
                bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
                
                webViewFrameNew.origin.y = top;
                webViewFrameNew.size.height = bannerViewFrameNew.origin.y - top;
            }
            
            webViewFrameNew.size.width = superViewFrameNew.size.width;
        }
        
        NSLog(@"webview: %d x %d, banner view: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height,
              (int) bannerViewFrameNew.size.width, (int) bannerViewFrameNew.size.height );
        
        self.bannerView.frame = bannerViewFrameNew;
        
    } else { // banner hidden
        webViewFrameNew = superViewFrameNew;
        
        NSLog(@"webview: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height );
        
    }
    
    self.webView.frame = webViewFrameNew;
}

#pragma mark -
#pragma mark Private Methods

- (void) __setOptions:(NSDictionary*) options
{
    if ((NSNull *)options != [NSNull null]) {
        NSString* str = nil;
        
        str = [options objectForKey:OPT_PUBLISHER_ID];
        if(str && [str length]>0) publisherId = str;
        
        str = [options objectForKey:OPT_INTERSTITIAL_ADID];
        if(str && [str length]>0) interstitialAdId = str;
        
        str = [options objectForKey:OPT_AD_SIZE];
        if(str) adSize = [self __AdSizeFromString:str];
        
        str = [options objectForKey:OPT_BANNER_AT_TOP];
        if(str) bannerAtTop = [str boolValue];
        
        str = [options objectForKey:OPT_OVERLAP];
        if(str) bannerOverlap = [str boolValue];
        
        str = [options objectForKey:OPT_OFFSET_TOPBAR];
        if(str) offsetTopBar = [str boolValue];
        
        str = [options objectForKey:OPT_IS_TESTING];
        if(str) isTesting = [str boolValue];
        
        NSDictionary* dict = [options objectForKey:OPT_AD_EXTRAS];
        if(dict) adExtras = dict;
        
        str = [options objectForKey:OPT_AUTO_SHOW];
        if(str) autoShow = [str boolValue];
    }
}

- (void) __createBanner
{
    // set background color to black
    //self.webView.superview.backgroundColor = [UIColor blackColor];
    //self.webView.superview.tintColor = [UIColor whiteColor];
    
    if (!self.bannerView){
        self.bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
        self.bannerView.adUnitID = [self publisherId];
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self.viewController;
        
		self.bannerIsInitialized = YES;
		self.bannerIsVisible = NO;
        
        //[self.webView.superview addSubview:self.bannerView];
        [self resizeViews];

        [self.bannerView loadRequest:[self __buildAdRequest]];
    }
}

- (GADRequest*) __buildAdRequest
{
    GADRequest *request = [GADRequest request];
    
    if (self.isTesting) {
		// Make the request for a test ad. Put in an identifier for the simulator as
		// well as any devices you want to receive test ads.
		request.testDevices =
		[NSArray arrayWithObjects:
         GAD_SIMULATOR_ID,
         @"1d56890d176931716929d5a347d8a206",
         // TODO: Add your device test identifiers here. They are
         // printed to the console when the app is launched.
         nil];
	}
	if (self.adExtras) {
		//GADAdMobExtras *extras = [[[GADAdMobExtras alloc] init] autorelease];
		GADAdMobExtras *extras = [[GADAdMobExtras alloc] init];
		NSMutableDictionary *modifiedExtrasDict =
		[[NSMutableDictionary alloc] initWithDictionary:self.adExtras];
		[modifiedExtrasDict removeObjectForKey:@"cordova"];
		[modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
		extras.additionalParameters = modifiedExtrasDict;
		[request registerAdNetworkExtras:extras];
	}
    
    return request;
}

- (void) __showAd:(BOOL)show
{
	NSLog(@"CDViAd Show Ad: %d", show);
	
	if (!self.bannerIsInitialized){
		[self __createBanner];
	}
	
	if (show == self.bannerIsVisible) { // same state, nothing to do
        if( self.bannerIsVisible) {
            [self resizeViews];
        }
	} else if (show) {
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        [parentView addSubview:self.bannerView];
        [parentView bringSubviewToFront:self.bannerView];
        [self resizeViews];
		
		self.bannerIsVisible = YES;
	} else {
		[self.bannerView removeFromSuperview];
        [self resizeViews];
		
		self.bannerIsVisible = NO;
	}
	
}

- (bool)__isLandscape {
    bool landscape = NO;
    
    //UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    //if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
    //    landscape = YES;
    //}
    // the above code cannot detect correctly if pad/phone lying flat, so we check the status bar orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            landscape = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            landscape = YES;
            break;
        default:
            landscape = YES;
            break;
    }
    
    return landscape;
}

- (void) __cycleInterstitial
{
    NSLog(@"__cycleInterstitial");

    // Clean up the old interstitial...
    self.interstitialView.delegate = nil;
    self.interstitialView = nil;
    
    // and create a new interstitial. We set the delegate so that we can be notified of when
    if (!self.interstitialView){
        self.interstitialView = [[GADInterstitial alloc] init];
        self.interstitialView.adUnitID = self.interstitialAdId;
        self.interstitialView.delegate = self;
        
        [self.interstitialView loadRequest:[self __buildAdRequest]];
    }
}

- (void) __showInterstitial:(BOOL)show
{
    NSLog(@"__showInterstitial");

	if (! self.interstitialView){
		[self __cycleInterstitial];
	}
    
    if(self.interstitialView && self.interstitialView.isReady) {
        [self.interstitialView presentFromRootViewController:self.viewController];
        
    } else {
        
    }
}

- (void)deviceOrientationChange:(NSNotification *)notification {
	[self resizeViews];
}

#pragma mark GADBannerViewDelegate implementation

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
	NSLog(@"%s: Received ad successfully.", __PRETTY_FUNCTION__);
    
    if(self.bannerShow) {
        [self writeJavascript:@"cordova.fireDocumentEvent('onReceiveAd');"];
        [self __showAd:YES];
    }
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	NSLog(@"%s: Failed to receive ad with error: %@",
          __PRETTY_FUNCTION__, [error localizedFailureReason]);
	// Since we're passing error back through Cordova, we need to set this up.
	NSString *jsString =
    @"cordova.fireDocumentEvent('onFailedToReceiveAd',"
    @"{ 'error': '%@' });";
	[self writeJavascript:[NSString stringWithFormat:jsString, [error localizedFailureReason]]];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
	//[self writeJavascript:@"cordova.fireDocumentEvent('onLeaveToAd');"];
    NSLog( @"adViewWillLeaveApplication" );
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
	[self writeJavascript:@"cordova.fireDocumentEvent('onPresentAd');"];
    NSLog( @"adViewWillPresentScreen" );
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
	[self writeJavascript:@"cordova.fireDocumentEvent('onDismissAd');"];
    NSLog( @"adViewDidDismissScreen" );
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial {
    if (self.interstitialView){
        [self writeJavascript:@"cordova.fireDocumentEvent('onReceiveInterstitialAd');"];
        if(self.autoShow) {
            [self __showInterstitial:YES];
        }
    }
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial {
    if (self.interstitialView){
        [self writeJavascript:@"cordova.fireDocumentEvent('onPresentInterstitialAd');"];
    }
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitialView = nil;
}

- (GADAdSize)__AdSizeFromString:(NSString *)string {
	if ([string isEqualToString:@"BANNER"]) {
		return kGADAdSizeBanner;
	} else if ([string isEqualToString:@"IAB_MRECT"]) {
		return kGADAdSizeMediumRectangle;
	} else if ([string isEqualToString:@"IAB_BANNER"]) {
		return kGADAdSizeFullBanner;
	} else if ([string isEqualToString:@"IAB_LEADERBOARD"]) {
		return kGADAdSizeLeaderboard;
	} else if ([string isEqualToString:@"SMART_BANNER"]) {
		// Have to choose the right Smart Banner constant according to orientation.
        if([self __isLandscape]) {
			return kGADAdSizeSmartBannerLandscape;
		}
		else {
			return kGADAdSizeSmartBannerPortrait;
		}
	} else {
		return kGADAdSizeInvalid;
	}
}

- (NSString*) __md5:(NSString *) s
{
    const char *cstr = [s UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark Cleanup

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
    
	bannerView_.delegate = nil;
	bannerView_ = nil;
    interstitialView_.delegate = nil;
    interstitialView_ = nil;
    
	self.bannerView = nil;
    self.interstitialView = nil;
}

@end

