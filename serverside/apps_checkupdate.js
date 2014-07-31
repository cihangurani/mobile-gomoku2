
var apps = apps || {};

apps['com.rjfun.gomoku2'] = {
	name : '经典五子棋2',
	icon : 'http://rjfun.com/gomoku2/icon.png',
	screenshot : 'http://rjfun.com/gomoku2/screenshot.jpg',
	desc : "最经典的五子棋，算法强，棋力厉害！",
	android : {
		version : '1.0.20140730',
		vercode : 20140730,
		url : 'http://rjfun.com/gomoku2/gomoku2-1.0.20140730.apk'
	},
	ios : {
		version : '1.0.20140730',
		vercode : 20140730,
		url : "javascript:alert('已经提交苹果审核，敬请期待！');" //"https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=896349671&mt=8" 
	}
};

function doAlert(msg, title) {
	if(navigator && navigator.notification && navigator.notification.alert) {
		navigator.notification.alert(msg, function(){}, title);
	} else {
		alert(msg);
	}
}

function doConfirm(msg, title, okfunc, cancelfunc) {
	if(navigator && navigator.notification && navigator.notification.confirm) {
		navigator.notification.confirm(msg, function(btnIndex){
			if(btnIndex == 1) okfunc();
			else cancelfunc();
		}, title);
	} else {
		if(confirm(msg)) okfunc();
		else cancelfunc();
	}
}

function openURL( url ) {
	if (typeof navigator !== "undefined" && navigator.app) {
		// Mobile device.
		navigator.app.loadUrl(url, {
			openExternal : true
		});
	} else {
		// Possible web browser
		window.open(url, "_blank");
	}
}


// Note: all apps using applist need have following items:
// app_key, like 'com.rjfun.jumprope'
// app_vercode, like 20140622
// app_data.versionAsked
// saveData(); 

function listApp( div_id ) {
	var html = "";
	var platforms = ['android', 'ios'];
	
	for(var k in apps) {
		var appitem = apps[k];
		
		html += "<p><div><img src='" + appitem.icon + "' style='float:left;margin:5px;'/>" + 
		'<br/><strong>' + appitem.name + '</strong>' +
		'<br/>介绍: ' + appitem.desc + '</div>' +
		'<br/>下载: <ul>';
		for(var i=0; i<platforms.length; i++) {
			var platform = platforms[i];
			var veritem = appitem[ platform ];
			if(veritem && veritem.url) {
				html += "<li><a href=\"" + veritem.url + "\">" + platform + "版</a>, v" + veritem.version + "</li>";
			}
		}
		html += '</ul>';
		html += "<img width=300 src='" + appitem.screenshot + "'/></p>";
	}
	
	var div = document.getElementById( div_id );
	div.innerHTML = html;
}

// now check version update
function checkUpdate( manual_check ) {
	if(manual_check == null) manual_check = true;
	
	// not from an cordova apps, ignore
	if(typeof app_key == 'undefined') return;
	if(typeof app_vercode == 'undefined') return;
	if(typeof app_data !== 'object') return;
	if(typeof saveData !== 'function') return;
	
	var platform = 'android';
	if( /(android)/i.test(navigator.userAgent) ) platform = 'android';
	else if( /(iphone|ipad|ipod)/i.test(navigator.userAgent) ) platform = 'ios';

	var appitem = apps[ app_key ];
	if(! appitem) return;
	
	var veritem = appitem[ platform ];
	if(! veritem) return;

	// already newer version
	if(app_vercode >= veritem.vercode) {
		if(manual_check) doAlert('这已经是最新版本了。', '无需更新');
		return;
	}
	
	var needAsk = (!! manual_check) 
			|| (! app_data.versionAsked)
			|| (app_data.versionAsked < veritem.vercode);
	if(! needAsk) return;

	doConfirm(
		'发现新版本: \n' + appitem.name + ' v' + veritem.version + ', \n要更新吗？',
		'可以更新',
		function() {
			openURL( veritem.url );
		}, function() {
			app_data.versionAsked = veritem.vercode;
			saveData();
		});
}

checkUpdate( false );
