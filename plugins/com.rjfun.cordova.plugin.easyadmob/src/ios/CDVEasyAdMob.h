//
//  CDVEasyAdMob.h

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GADAdSize.h"
#import "GADBannerView.h"
#import "GADInterstitial.h"
#import "GADBannerViewDelegate.h"
#import "GADInterstitialDelegate.h"

@class GADBannerView;
@class GADInterstitial;

@interface CDVEasyAdMob : CDVPlugin <GADBannerViewDelegate, GADInterstitialDelegate> {
}

@property(nonatomic, retain) GADBannerView *bannerView;
@property(nonatomic, retain) GADInterstitial *interstitialView;

@property (nonatomic, retain) NSString* publisherId;
@property (nonatomic, retain) NSString* interstitialAdId;

@property (assign) GADAdSize adSize;
@property (assign) BOOL bannerAtTop;
@property (assign) BOOL bannerOverlap;
@property (assign) BOOL offsetTopBar;

@property (assign) BOOL isTesting;
@property (nonatomic, retain) NSDictionary* adExtras;

@property (assign) BOOL bannerIsVisible;
@property (assign) BOOL bannerIsInitialized;
@property (assign) BOOL bannerShow;
@property (assign) BOOL autoShow;

- (void) setOptions:(CDVInvokedUrlCommand *)command;

- (void) showBanner:(CDVInvokedUrlCommand *)command;
- (void) removeBanner:(CDVInvokedUrlCommand *)command;

- (void) requestInterstitial:(CDVInvokedUrlCommand *)command;
- (void) showInterstitial:(CDVInvokedUrlCommand *)command;

@end
