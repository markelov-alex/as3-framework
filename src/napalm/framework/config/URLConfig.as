package napalm.framework.config
{
	import napalm.framework.config.constants.ArtPlatformType;
	import napalm.framework.config.constants.Platform;
	import napalm.framework.config.constants.QualityType;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.ObjectUtil;
	
	/**
	 * URLConfig.
	 *
	 * All URLs and paths from app's configuration.
	 * @author alex.panoptik@gmail.com
	 */
	public class URLConfig
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		private var configObject:Object = {};

		// Properties
		
		protected var log:Log;

		// Preloader
		
		public function get loaderURL():String
		{
			return configObject["loaderURL"] || "";
		}

		public function get preloaderViewSWFURL():String
		{
			return configObject["preloaderViewSWFURL"];
		}

		public function get applicationSWFURL():String
		{
			return configObject["applicationSWFURL"];
		}

//-		private var _languageURLLookup:Object = {};
//		public function get languageURLLookup():Object
//		{
//			return _languageURLLookup;
//		}
//
//		private var _mobileLanguagePathLookup:Object = {};
//		public function get mobileLanguagePathLookup():Object
//		{
//			return _mobileLanguagePathLookup;
//		}
		
		// Assets

		public function get assetsVersionJSONURL():String
		{
			return configObject["assetsVersionJSONURL"];//was "version_url"
		}

		public function get mobileAssetsVersionJSONPath():String
		{
			return configObject["mobileAssetsVersionJSONPath"];
			//-was return mobileStaticRootPathURL + "version.json";
		}
//?
//		/**
//		 * Path to directory of versionJSON on remote server.
//		 * Example: "http://domain/dev_cdn/assets/"
//		 */
//		private var _assetsRootURL:String;
//		public function get assetsRootURL():String
//		{
//			return _assetsRootURL;//configObject["assets_url"];
//		}
//
//		/**
//		 * Path to directory of versionJSON on device's local storage.
//		 * Example: "assets/"
//		 */
//		private var _mobileAssetsRootPath:String;
//		public function get mobileAssetsRootPath():String
//		{
//			return _mobileAssetsRootPath;
//		}

		// ["web_hd", "web_sd", "ios_hd", "ios_sd", "and_hd", ...]
		private var _platformCodeArray:Array;
		public function get platformCodeArray():Array
		{
			if (!_platformCodeArray)
			{
				_platformCodeArray = [];
				for each (var artPlatformType:String in ArtPlatformType.LIST)
				{
					for each (var qualityType:String in QualityType.LIST)
					{
						_platformCodeArray[_platformCodeArray.length] = artPlatformType + "_" + qualityType;
					}
				}
			}
			return _platformCodeArray;
		}

		// [web_hd", "web_sd"] or [and_hd", "and_sd"] ...
		private var _currentPlatformCodeArray:Array;
		private function get currentPlatformCodeArray():Array
		{
			if (!_currentPlatformCodeArray)
			{
				_currentPlatformCodeArray = [];
				for each (var qualityType:String in QualityType.LIST)
				{
					_currentPlatformCodeArray[_currentPlatformCodeArray.length] = Device.artPlatformType + "_" + qualityType;
				}
			}
			return _currentPlatformCodeArray;
		}

		// "web_sd", "ios_hd", "and_sd"
		public function get platformCode():String
		{
			return Device.artPlatformType + "_" + Device.qualityType;
		}

		//?
		// "web_sd/", "ios_hd/", "and_sd/"
		public function get platformDir():String
		{
			return platformCode + "/";
		}

		/**
		 * In web HD is theoretically available (when open in full screen on Retina display, for example).
		 * For mobile application always opens in full screen and so it cannot have different resolutions
		 * on the same device.
		 */
			// [web_hd", "web_sd"] or [and_hd"] or ["and_sd"] or ["ios_sd"] ...
		public function get availablePlatformCodeArray():Array
		{
			return Device.isMobile ? [platformCode] : currentPlatformCodeArray;
		}
		
		// Server

//?		public function get serverAPIURL():String
//		{
//			return Device.isMobile ? mobileServerAPIURL : remoteServerAPIURL;
//		}

		private var _remoteServerAPIURL:String;
		public function get remoteServerAPIURL():String
		{
			return _remoteServerAPIURL;
		}

		private var _mobileServerAPIURL:String;
		public function get mobileServerAPIURL():String
		{
			return _mobileServerAPIURL;
		}

//		//was "soc":{}
//		//"mobile_social_main_url":{
//		//		"ok":"http://web60.socialquantum.com/server_kitchen_mobile/index.php",
//		//		"mm":"http://web61.socialquantum.com/server_kitchen_mm_mobile/index.php",
//		//		"vk":"http://zombieranch-ok.ilogos-ua.com/server_kitchen_vk_mobile/index.php",
//		//		"fb":"http://nweb39.socialquantum.com/server_kitchen_fb_mobile/index.php"
//		//},
//		//see getMobileSocialMainURLByNetwork
//		public function get mobileSocialMainURL():String
//		{
//			return configObject["mobile_social_main_url"][AppConfig.socialNetwork];
//		}
//
//		//was "soc_connections":{}
//		//"mobile_social_auth_url":{
//		//	"ok":"http://www.odnoklassniki.ru/oauth/authorize?client_id=%APP_ID%&scope=VALUABLE ACCESS&response_type=code&layout=m&v=4.0&redirect_uri=%REDIRECT_URL%",
//		//	"mm":"https://connect.mail.ru/oauth/authorize?client_id=%APP_ID%&response_type=token&display=mobile&scope=messages,guestbook,stream&redirect_uri=%REDIRECT_URL%",
//		//	"vk":"https://oauth.vk.com/authorize?client_id=%APP_ID%&scope=notify,friends,wall&response_type=token&display=mobile&v=4.0&redirect_uri=%REDIRECT_URL%",
//		//	"fb":""
//		//},
//		// (Needed for OK and MM only)?
//		public function getMobileSocialAuthURLBySocialNetwork(socialNetwork:String):String
//		{
//			return configObject["mobile_social_auth_url"][socialNetwork];
//		}
//
//		//"mobile_social_auth_callback_url":{
//		//		"mm":"http://web37.socialquantum.com/mmAuth.php?access_token=%ACCESS_TOKEN%",
//		//		"ok":"http://web60.socialquantum.com/server_kitchen_mobile/okAuth.php",
//		//		"vk":"https://oauth.vk.com/blank.html",
//		//		"fb":""
//		//},
//		// (Needed for OK and MM only)?
//		public function getMobileSocialAuthCallbackURLBySocialNetwork(socialNetwork:String):String
//		{
//			return configObject["mobile_social_auth_callback_url"][socialNetwork];
//		}
//
//		//"mobile_base_url":{
//		//		"ok":"http://web60.socialquantum.com/server_kitchen_mobile/",
//		//		"mm":"http://web61.socialquantum.com/server_kitchen_mm_mobile/",
//		//		"vk":"http://zombieranch-ok.ilogos-ua.com/server_kitchen_vk_mobile/",
//		//		"fb":"http://nweb39.socialquantum.com/server_kitchen_fb_mobile/"
//		//},
//		public function get mobileBaseURL():String
//		{
//			return configObject["mobile_base_url"][AppConfig.socialNetwork];
//		}
//
//		//"mobile_api_url":"http://web61.socialquantum.com/server_mobile/mobile.php",
//		public function get mobileAPIURL():String
//		{
//			return configObject["mobile_api_url"];
//		}
//
//		//?
//		//"mobile_log_url":"http://web61.socialquantum.com/server_mobile/mobile_log.php",
//		public function get mobileLogURL():String
//		{
//			return configObject["mobile_log_url"];
//		}
//
//		//"mobile_verify_purchase_url":"http://web61.socialquantum.com/server_mobile/mobile_order.php",
//		public function get mobileVerifyPurchaseURL():String
//		{
//			return configObject["mobile_verify_purchase_url"];
//		}
//
//		//"mobile_save_token_url":"http://web61.socialquantum.com/server_mobile/mobile_token.php",
//		public function get mobileSaveTokenURL():String
//		{
//			return configObject["mobile_save_token_url"];
//		}
//
//		//"mobile_posts_url":"http://mb.static.socialquantum.ru/kitchen/server_kitchen/assets/posting/",
//		public function get mobilePostingPathURL():String
//		{
//			return configObject["mobile_posts_url"];
//		}
//
//		//"mobile_ok_share_url":"http://mb.static.socialquantum.ru/kitchen_mm/server_mobile/assets_mobile/okMobile.html",
//		public function get mobileShareOkURL():String
//		{
//			return configObject["mobile_ok_share_url"];
//		}
//
//		//"mobile_facebook_og":{
//		//		"fb_action_url":"https://nweb39.socialquantum.com/server_kitchen_fb/data/og/object.php"
//		//},
//		public function get mobileFacebookActionURL():String
//		{
//			return configObject["mobile_facebook_og"] ? configObject["mobile_facebook_og"]["fb_action_url"] : null;
//		}

		// For preloader
		private var _mobileAppInStoreURL:String;
		public function get mobileAppInStoreURL():String
		{
			return _mobileAppInStoreURL;
		}

		// For preloader
		private var _androidAppInStoreURL:String;
		public function get androidAppInStoreURL():String
		{
			return _androidAppInStoreURL;
		}

		// For preloader
		private var _iosAppInStoreURL:String;
		public function get iosAppInStoreURL():String
		{
			return _iosAppInStoreURL;
		}
//
//		public function get applicationFBURL():String
//		{
//			return configObject["application_fb"];
//		}

		public function get statisticsDeltaDNAURL():String
		{
			return configObject["stats"] && configObject["stats"]["deltadna"] ? 
				configObject["stats"]["deltadna"]["url"] : null;
		}

		public function get statisticsNanigansURL():String
		{
			return configObject["stats"] && configObject["stats"]["nanigans"] ? 
					configObject["stats"]["nanigans"]["url"] : null;
		}

		//"http://web61.socialquantum.com/server_mobile/mobile_internet.php"
		public function get mobileCheckInternetURL():String
		{
			return configObject["mobileCheckInternetURL"];
		}

		//?-
		//"http://web61.socialquantum.com/server_mobile/mobile_internet.txt"
		public function get mobileCheckInternetStaticURL():String
		{
			return configObject["mobileCheckInternetStaticURL"];
		}

		//TODO add to config.json
		//"http://domain/server/log/bug_report.php"
		public function get bugReportURL():String
		{
			return configObject["bugReportURL"];
		}

		//"support_maillist_ios" : {
		//		"en" : "",
		//		"ru" : "maxim.efimov@nikaent.com"
		//},
		//"support_maillist_android" : {
		//		"en" : "?kitchen_int_support_ios_eng@socialquantum.com",
		//		"ru" : "maxim.efimov@nikaent.com"
		//},
		private var _supportEMail:String;
		public function get supportEMail():String
		{
			return _supportEMail;
		}

		// Constructor

		public function URLConfig()
		{
		}

		// Methods

		internal function initialize(appConfig:AppConfig, configObject:Object, flashVarsObject:Object = null):void
		{
			log = Log.instance;
			log.log(Channel.CONFIG, this, "(initialize) configObject:", configObject);

			// Set
			setUpByObject(configObject, appConfig);
			setUpByObject(flashVarsObject, appConfig);
		}
		
		internal function dispose():void
		{
			log = null;
		}

		private function setUpByObject(configObject:Object, appConfig:AppConfig):void
		{
			ObjectUtil.copy(configObject, this.configObject);
//-
//			// Language
//			var debugString:String = "";
//			var languageDirURL:String = configObject["language_dir_url"];
//			var mobileLanguageDirURL:String = configObject["mobile_language_dir"];
//			for each (var languageCode:String in appConfig.availableLanguageCodeArray)
//			{
//				_languageURLLookup[languageCode] = languageDirURL + languageCode + ".json";
//				_mobileLanguagePathLookup[languageCode] = mobileLanguageDirURL + languageCode + ".json";
//				debugString += languageCode + ": \"" + _languageURLLookup[languageCode] + "\" \"" + _mobileLanguagePathLookup[languageCode] + "\" ";
//			}

			// Other
			var platformSuffix:String = Device.isIOS ? "ios" : "android";
			var maillistByLanguageCode:Object = configObject["supportMaillist_" + platformSuffix];
			_supportEMail = maillistByLanguageCode ? maillistByLanguageCode[appConfig.languageCode] : null;

//			_assetsRootURL = URLUtil.getDirectoryPath(assetsVersionJSONURL);
//			_mobileAssetsRootPath = URLUtil.getDirectoryPath(mobileAssetsVersionJSONPath);//FileUtil.treatAppStorageURL(configObject["mobile_assets_dir_path"]);

			if (configObject && configObject.hasOwnProperty("apiURL"))
			{
				_remoteServerAPIURL = configObject["apiURL"];
			}

			_mobileAppInStoreURL = getMobileAppInStoreURL(null, appConfig.languageCode);
			_androidAppInStoreURL = getMobileAppInStoreURL(Platform.ANDROID, appConfig.languageCode);
			_iosAppInStoreURL = getMobileAppInStoreURL(Platform.IOS, appConfig.languageCode);
		}

		//"mobile_store_links":{
		//		"amazon_int":"http://www.amazon.com/gp/mas/dl/android?p=air.com.sq.kitchen.int.amazon",
		//		"android_int":"https://play.google.com/store/apps/details?id=air.com.sq.kitchen.int",
		//		"android_ru":"https://play.google.com/store/apps/details?id=air.com.sq.kitchen",
		//		"ios_int":"https://itunes.apple.com/us/app/magic-kitchen-match-3-puzzle/id878614118?mt=8",
		//		"ios_ru":"https://itunes.apple.com/ua/app/magiceskaa-kuhna-tri-v-rad/id852421504?mt=8"
		//}
		private function getMobileAppInStoreURL(platform:String = null, languageCode:String = null):String
		{
			var linksObject:Object = configObject["mobileStoreLinks"];
			if (!linksObject)
			{
				//log.warn(Channel.CONFIG, URLConfig, "(getMobileAppInStoreURL) configObject doesn't have property \"mobile_store_links\" linksObject:", linksObject);
				return null;
			}
			
			if (!platform)
			{
				platform = Device.isAmazon ? Platform.AMAZON : 
						(Device.isAndroid ? Platform.ANDROID : (Device.isIOS ? Platform.IOS : "-"));
			}
			var result:String = linksObject[platform + "_" + languageCode];
			if (!result)
			{
				result = linksObject[platform + "_int"];
			}
			return result;
		}

		public function getRemoteLanguageURLByCode(languageCode:String):String
		{
			return configObject["languageDirURL"] && languageCode ? 
					configObject["languageDirURL"] + languageCode + ".json" : null;
		}

		public function getMobileLanguagePathByCode(languageCode:String):String
		{
			return configObject["mobileLanguageDirPath"] && languageCode ? 
					configObject["mobileLanguageDirPath"] + languageCode + ".json" : null;//was "mobile_language_dir"
		}

//		//was "soc":{}
//		//"mobile_social_main_url":{
//		//		"ok":"http://web60.socialquantum.com/server_kitchen_mobile/index.php",
//		//		"mm":"http://web61.socialquantum.com/server_kitchen_mm_mobile/index.php",
//		//		"vk":"http://zombieranch-ok.ilogos-ua.com/server_kitchen_vk_mobile/index.php",
//		//		"fb":"http://nweb39.socialquantum.com/server_kitchen_fb_mobile/index.php"
//		//},
//		// see SocialNetwork for values
//		public function getMobileSocialMainURLByNetwork(socialNetwork:String):String
//		{
//			return configObject["mobile_social_main_url"][socialNetwork];
//		}

		//-public function getApplicationURLByAdID(adID:String):String
		//{
		//	return applicationURL + "?ad_id=" + adID;
		//}
		
	}
}
