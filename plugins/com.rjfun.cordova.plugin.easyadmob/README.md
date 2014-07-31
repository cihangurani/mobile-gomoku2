# cordova-plugin-easyadmob #

This is the easiest way to add Ad to your cordova apps, less code and smaller package size. 

* How easy? 
Single line of js code.

* How small the package can be? 
Android APK, ~578KB. iOS IPA, ~542KB. (measured with single HTML page, without splash images)

Platform SDK supported (SDK included):
* Android, using AdMob, Google Play Service v4.4.
* iOS, using AdMob SDK v6.10.0
* Windows Phone, using AdMob SDK v6.5.11 (experimental)

Required:
* Cordova >= 2.9.0

## See Also ##
Besides EasyAdMob plugin, there are some other options, all working on cordova:
* [cordova-plugin-admob](https://github.com/floatinghotpot/cordova-plugin-admob), Google AdMob service. 
* [cordova-plugin-iad](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [cordova-plugin-flurry](https://github.com/floatinghotpot/cordova-plugin-flurry), Flurry Ads service.

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-easyadmob.git

Note: 
Ensure you have a proper AdMob account and create an Id for your android app. For iOS, admob key not needed, since it will link to your Apple Id.

## Quick start with cordova CLI ##
    cordova create testad com.rjfun.testad TestAd
    cd testad
    cordova platform add android
    cordova platform add ios
    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-easyadmob.git
    rm -r www/*
    cp plugins/com.rjfun.cordova.plugin.easyadmob/test/* www/
    cordova prepare; cordova run android; cordova run ios;
    // or import into Xcode / eclipse

## Javascript API ##

APIs:
- setOptions(options, success, fail);
- showBanner(true/false, options, success, fail);
- removeBanner(success, fail);
- requestInterstital(options, success, fail);
- showInterstitial(success, fail);

Options:
- publiserId // the ad unit id get from AdMob
- interstitalAdId // use same publiserId with banner Ad if not specified, set if use a different Ad Id
- bannerAtTop // false if not specified
- overlap // false if not specified, set to true to allow banner overlap webview
- offsetTopBar // false if not specified, set to true to avoid overlapped by iOS7 status bar
- isTesting // false if not specified, set to true to accept test Ad
- autoShow // false if not specified, set to true, to display interstital once loaded

Events: 
- for banner: onReceiveAd, onFailedToReceiveAd, onPresentAd, onDismissAd, onLeaveToAd
- for interstitial: onReceiveInterstitialAd, onPresentInterstitialAd, onDismissInterstitialAd

## Example code ##
Call the following code inside onDeviceReady(), because only after device ready you will have the plugin working.
```javascript
// --- copy the code snippets to your js file --
var ad = null;
if ( window.plugins && window.plugins.EasyAdMob ) {
	var ad = window.plugins.EasyAdMob;

	var admob_ios_key = 'ca-app-pub-6869992474017983/4806197152';
	var admob_android_key = 'ca-app-pub-6869992474017983/9375997553';
	
	ad.setOptions({
	    publisherId: isAndroidDevice() ? admob_android_key : admob_ios_key,
	    bannerAtTop: false,
	    overlap: false,
	    offsetTopBar: false,
	    isTesting: true,
	    autoShow: true
	});
		
	document.addEventListener('onReceiveAd', function(){
	});
	document.addEventListener('onFailedToReceiveAd', function(data){
	});
	document.addEventListener('onPresentAd', function(){
	});
	document.addEventListener('onDismissAd', function(){
	});
	document.addEventListener('onLeaveToAd', function(){
	});
	document.addEventListener('onReceiveInterstitialAd', function(){
    });
	document.addEventListener('onPresentInterstitialAd', function(){
    });
	document.addEventListener('onDismissInterstitialAd', function(){
    });
}
// --- end of snippets ---

// the most simple code to show Ad
if(ad) ad.showBanner(true);
if(ad) ad.requestInterstitial();
if(ad) ad.showInterstitial();

```

See the working example code in [demo under test folder](test/index.html), and here are some screenshots.
 
## Donate ##
 To support this project, donation is welcome.  
* [Donate directly via Payoneer / PayPal / AliPay](http://floatinghotpot.github.io/#donate)

