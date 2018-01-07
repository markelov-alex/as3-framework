package napalm.framework.config
{
	import napalm.framework.config.constants.LanguageCode;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.ObjectUtil;
	
	/**
	 * AppConfig.
	 * 
	 * Common application configuration.
	 * All URLs in URLConfig.
	 * @author alex.panoptik@gmail.com
	 */
	public class AppConfig
	{
		
		// Class constants
		// Class variables
		// Class methods
		
		// Variables
		
		protected var log:Log;
		private var configObject:Object = {};
		
		// Properties

		private var _isInitialized:Boolean = false;
		public function get isInitialized():Boolean
		{
			return _isInitialized;
		}

		private var _urlConfig:URLConfig = new URLConfig();
		public function get urlConfig():URLConfig
		{
			return _urlConfig;
		}

		private var _userAgent:String;
		public function get userAgent():String
		{
			//if (!_userAgent && ExternalInterface.available)
			//{
			//	_userAgent = ExternalInterface.call("function () { return navigator.userAgent; }");
			//}
			return _userAgent;
		}

		public function get preloaderClassName():String
		{
			return configObject["preloaderClass"];
		}

		public function get applicationClassName():String
		{
			//trace("applicationClassName - configObject.applicationClass:",configObject["applicationClass"]);
			return configObject["applicationClass"];
		}

		private var _isLocalServer:Boolean = false;
		public function get isLocalServer():Boolean
		{
			return _isLocalServer;
		}

		private var _isDevVersion:Boolean = false;
		public function get isDevVersion():Boolean
		{
			return _isDevVersion;
		}

		private var _isProduction:Boolean = false;
		public function get isProduction():Boolean
		{
			return !isDevVersion;//?_isProduction;
		}

		//"fb", "vk", "ok", "mm" @see SocialNetwork.FB,VK,OK,MM
		private var _socialNetwork:String;
		public function get socialNetwork():String
		{
			return _socialNetwork;
		}
		public function set socialNetwork(value:String):void
		{
			if (Device.isMobile)
			{
				_socialNetwork = value;
			}
			else
			{
				//throw new Error("Property socialNetwork is read-only.");
			}
		}

		// "en","ru","jp" @see LanguageCode
		private var _languageCode:String = LanguageCode.EN;
		public function get languageCode():String
		{
			return _languageCode;
		}
		
		// ["en", "ru", "jp"]
		private var _availableLanguageCodeArray:Array = [];
		public function get availableLanguageCodeArray():Array
		{
			return _availableLanguageCodeArray;
		}
//?		
//		//1000
//		public function get initialAppWidth():int
//		{
//			return configObject["app_width"];
//		}
//		//650
//		public function get initialAppHeight():int
//		{
//			return configObject["app_height"];
//		}
		
		//true
		private var _isSuppressCache:Boolean = false;
		public function get isSuppressCache():Boolean
		{
			return _isSuppressCache;
		}

		private var _isFirstRun: Boolean = false;
		public function get isFirstRun():Boolean
		{
			return _isFirstRun;
		}

		//"social_app_id":{
		//		"ok":"1096962048",
		//		"mm":"723439",
		//		"vk":"3810320",
		//		"fb":"812313128801515"
		//},
		//"mobile_social_app_id":{
		//		"ok":"218641664",
		//		"mm":"719075",
		//		"vk":"4263404",
		//		"fb":"473706962675851"
		//},
		private var _socialAppID:String;
		public function get socialAppID():String
		{
			if (!_socialAppID)
			{
				var mobilePrefix:String = Device.isMobile ? "mobile_" : "";
				if (configObject.hasOwnProperty(mobilePrefix + "socialAppID"))
				{
					var appIDByNetwork:Object = configObject[mobilePrefix + "socialAppID"];
					_socialAppID = appIDByNetwork ? appIDByNetwork[socialNetwork] : null;
				}
			}
			return _socialAppID;
		}

		//(uncomment if needed)
		//public function get socialWebAppID():String
		//{
		//	return configObject["social_app_id"][socialNetwork];
		//}
		//(uncomment if needed)
		//public function get socialMobileAppID():String
		//{
		//	return configObject["mobile_social_app_id"][socialNetwork];
		//}

		private var _socialUserID:String;
		public function get socialUserID():String
		{
			return _socialUserID;
		}
		public function set socialUserID(value:String):void
		{
			if (Device.isMobile)
			{
				_socialUserID = value;
			}
			else
			{
				//throw new Error("Property socialUserID is read-only.");
			}
		}

		private var _userABTestGroup:String;
		public function get userABTestGroup():String
		{
			return _userABTestGroup;
		}
		
		private var _isShowAds:Boolean = false;
		public function get isShowAds():Boolean
		{
			return _isShowAds;
		}

		//[{"name":"resources", "max":10, "text":""},...]
		/**
		 * Social example:
			 "preload_parts":[
				 {"name":"preloader", "max":10, "text":""},
				 {"name":"resources", "max":25, "text":""},
				 {"name":"assets", "max":13, "text":""},
				 {"name":"dialogs", "max":20, "text":""},
				 {"name":"sounds", "max":0, "text":""},
				 {"name":"gameField", "max":30, "text":""},
				 {"name":"socialNetwork", "max":1, "text":""},
				 {"name":"loginToServer", "max":1, "text":""}
			 ],
		  * Mobile example:
			 "preload_parts":[
				 {"name":"resources", "max":53, "text":""},
				 {"name":"assets", "max":13, "text":""},
				 {"name":"dialogs", "max":18, "text":""},
				 {"name":"sounds", "max":0, "text":""},
				 {"name":"gameField", "max":2, "text":""},
				 {"name":"socialNetwork", "max":2, "text":""},
				 {"name":"loginToServer", "max":2, "text":""}
			 ],
		 */
		private var _preloadPartArray:Array = [];
		public function get preloadPartArray():Array
		{
			return _preloadPartArray;
		}

		private var _versionMajor:int = 0;
		public function get versionMajor():int
		{
			return _versionMajor;
		}

		private var _versionMinor:int = 0;
		public function get versionMinor():int
		{
			return _versionMinor;
		}

		private var _versionBuild:int = 0;
		public function get versionBuild():int
		{
			return _versionBuild;
		}
		private var _versionRevision:int = 0;
		public function get versionRevision():int
		{
			return _versionRevision;
		}

		/**
		 * 1.0.15.20151226
		 */
		public function get versionString():String
		{
			return _versionMajor + "." + _versionMinor + "." + _versionBuild + "." + _versionRevision;
		}

		private var _versionTimestamp:String;
		public function get versionTimestamp():String
		{
			return _versionTimestamp;
		}

		private var _preloaderVersion:String;
		public function get preloaderVersion():String
		{
			return _preloaderVersion;
		}

		public function get frameworkVersion():String
		{
			return "1.0.0.20160310";
		}

		/**
		 * для шифрования данных, динамически созданная часть ключа, что передается с сервера через флешвары.
		 */
		//was characterKey
		private var _encryptKey:String;
		public function get encryptKey():String
		{
			return _encryptKey;
		}

		private var _isStatisticsDeltaDNAEnabled:Boolean = false;
		public function get isStatisticsDeltaDNAEnabled():Boolean
		{
			return _isStatisticsDeltaDNAEnabled;
		}

		private var _isStatisticsNanigansEnabled:Boolean = false;
		public function get isStatisticsNanigansEnabled():Boolean
		{
			return _isStatisticsNanigansEnabled;
		}

		private var _branchNameArray:Array = [];
		public function get branchNameArray():Array
		{
			return _branchNameArray;
		}

		private var _currentBranchName:String;
		public function get currentBranchName():String
		{
			return _currentBranchName;
		}
		
		// Constructor

		public function AppConfig()
		{
			// (setPreloaderVersion() called before initialize())
			log = Log.instance;
		}
		
		// Methods
		
		public function initialize(configObject:Object, flashVarsObject:Object = null):void
		{
			log = Log.instance;
			log.log(Channel.CONFIG, "[PRELOAD-STEP-|4] Init all App Configs!");
			log.log(Channel.CONFIG, "(initialize) <setUpByObject;urlConfig.initialize;Preferences.initialize> " +
					"flashVarsObject:", flashVarsObject,"(stringify):",JSON.stringify(flashVarsObject),"configObject:", configObject);//,JSON.stringify(configObject)

			_isInitialized = true;

			// Set up
			setUpByObject(configObject);
			setUpByObject(flashVarsObject);
			
			// Initialize other configs
			//?????
			// (Default Preferences for single apps. For multiple apps loading use SystemManager's preferences)
			Preferences.initialize("napalm_" + socialAppID);// + "_" + socialNetwork + "_" + socialUserID
			
			urlConfig.initialize(this, configObject, flashVarsObject);
			
			_isLocalServer = urlConfig.loaderURL.indexOf(".local") != -1;
			
//			CONFIG::mobile
//			{
//				var ns:Namespace = NativeApplication.nativeApplication.applicationDescriptor.namespace();
//				var appName:String = NativeApplication.nativeApplication.applicationDescriptor.ns::name;
//				_isDevVersion =  appName ? (new RegExp(/\Wdev/)).test(appName.toLowerCase()) : false;
//			}
		}
		
		public function dispose():void
		{
			if (_urlConfig)
			{
				_urlConfig.dispose();
			}
			_urlConfig = null;
			
			log = null;
		}

		private function setUpByObject(configObject:Object):void
		{
			if (!configObject || configObject is String)
			{
				return;
			}

			ObjectUtil.copy(configObject, this.configObject);
			
			if (configObject.hasOwnProperty("logging"))
			{
				//todo refactor for multiinstance app
				configureLog(Log.instance, configObject["logging"]);
			}

			if (configObject.hasOwnProperty("isDev"))//was "is_dev"
			{
				_isDevVersion = configObject["isDev"];
			}
			if (configObject.hasOwnProperty("isSuppressCache"))//was "is_suppress_cache"
			{
				_isSuppressCache = configObject["isSuppressCache"];
			}
			if (configObject.hasOwnProperty("isShowAds"))//was "is_show_ads"
			{
				_isShowAds = configObject["isShowAds"];
			}
			if (configObject.hasOwnProperty("preloadParts"))//was "preload_parts"
			{
				_preloadPartArray = configObject["preloadParts"];
			}
			if (configObject.hasOwnProperty("stats"))
			{
				_isStatisticsDeltaDNAEnabled = configObject["stats"]["deltadna"]["enabled"];
				_isStatisticsNanigansEnabled = configObject["stats"]["nanigans"]["enabled"];
			}

			if (configObject.hasOwnProperty("userAgent"))
			{
				_userAgent = configObject["userAgent"];
			}
			if (configObject.hasOwnProperty("language"))
			{
				_languageCode = configObject["language"];
			}
			if (configObject.hasOwnProperty("langList"))//was "lang_list"
			{
				var string:String = configObject["langList"] || "";
				_availableLanguageCodeArray = string.split(",");
			}
			if (configObject.hasOwnProperty("socialUserID"))//was "userID"
			{
				_socialUserID = configObject["socialUserID"];
			}
			if (configObject.hasOwnProperty("userABTestGroup"))//was "userTestGroup"
			{
				_userABTestGroup = configObject["userABTestGroup"];
			}
			//?
			//if (configObject.hasOwnProperty("user_ab_session"))//? user_ab_session or userABTestGroup
			//{
			//	_userABTestGroup = configObject["user_ab_session"];
			//}
			if (configObject.hasOwnProperty("socialNetwork"))//was network
			{
				_socialNetwork = configObject["socialNetwork"];
			}
			if (configObject.hasOwnProperty("isFirstRun"))//was "first_run"
			{
				_isFirstRun = configObject["isFirstRun"];
			}
			if (configObject.hasOwnProperty("encryptKey"))//was "character"
			{
				_encryptKey = configObject["encryptKey"];
			}
			if (configObject.hasOwnProperty("branches"))
			{
				_branchNameArray.length = 0;
				for (var branchName:String in configObject["branches"])
				{
					_branchNameArray[_branchNameArray.length] = branchName;
				}
			}
			log.info(Channel.CONFIG, this, "(setUpByObject)", "languageCode:", languageCode, "socialUserID:", socialUserID,
					"userABTestGroup:", userABTestGroup, "socialNetwork:", socialNetwork, "userAgent:", userAgent);
		}
		
		public function setPreloaderVersion(version:String):void
		{
			if (!_preloaderVersion)
			{
				_preloaderVersion = version;
				log.log(Channel.CONFIG, this, "(setPreloaderVersion) preloaderVersion:", preloaderVersion);
			}
		}

		public function setVersion(version:String, revision:String = null, buildTimestamp:String = null):void
		{
			// (Set once)
			if (_versionMajor || _versionMinor || _versionBuild || _versionRevision || _versionTimestamp)
			{
				return;
			}
			
			var versionParts:Array = version.split(".");
			_versionMajor = int(versionParts[0]);
			_versionMinor = int(versionParts[1]);
			_versionBuild = int(versionParts[2]);
			_versionRevision = int(revision) || int(versionParts[3]) || 0;
			_versionTimestamp = buildTimestamp;
			log.log(Channel.CONFIG, this, "(setVersion) versionString:", versionString, "versionTimestamp:", versionTimestamp, "data:", version, revision, buildTimestamp);
		}

		/**
		 * Some properties in config.json should vary depending of build's purpose. 
		 * For example, properties isDev and isProduction will be different for prod and dev builds; 
		 * or developers wish to use their own assets (versionURL).
		 * 
		 * This realized by branches mechanism in config.json:
		 * 	{
		 * 		"isDev": false,
		 * 		"isProduction": true,
		 * 		"versionURL": "http://domain/prod/assets/"	
		 * 		...
		 * 		"branches": 
		 * 		{
		 * 			"dev": 
		 * 			{
		 * 				"isDev": true,
		 * 				"isProduction": false,
		 * 				"versionURL": "http://domain/dev/assets/"	
		 * 			}
		 * 			"alex": 
		 * 			{
		 * 				"isDev": true,
		 * 				"isProduction": false,
		 * 				"versionURL": "http://domain/alex/assets/"	
		 * 			}
		 * 		}
		 * 	}	
		 * 
		 * In preloader after config.json loaded and before other action for dev-build you place 
		 * combobox to select the branch you wish to use (by using branchNameArray, currentBranchName 
		 * and setBranch()).
		 * 
		 * @param branchName
		 */
		public function setBranch(branchName:String):void
		{
			if (!configObject.hasOwnProperty("branches") && !configObject.hasOwnProperty(branchName))
			{
				return;
			}

			var branchObject:Object = configObject["branches"][branchName];
			if (!branchObject)
			{
				return;
			}

			_currentBranchName = branchName;

			// Apply branch
			for (var property:String in branchObject)
			{
				configObject[property] = branchObject[property];
			}
			
			urlConfig.initialize(this, configObject);
		}

		/**
		 * Get all app's info for logging.
		 * 
		 * @param loaderInfo
		 * @return
		 */
		public function getAppInfo():String
		{
			return 	"\n[userAgent] " + userAgent + "\n" + 
					"[frameworkVersion] " + "v." + frameworkVersion + "\n" + 
					"[preloaderVersion] " + "v." + preloaderVersion + "\n" + 
					"[appVersion] " + "v." + versionString + " " + versionTimestamp + "\n" +
					"[prod] " + isProduction + " [dev] " + isDevVersion + " [local] " + isLocalServer + 
					" [branch] " + currentBranchName + "\n" +
					"[language] " + languageCode + " [available] " + availableLanguageCodeArray + "\n" +
					"[socialNetwork] " + socialNetwork + "\n" +
					"[socialAppID] " + socialAppID + "\n" +
					"[socialUserID] " + socialUserID + " [firstRun] " + isFirstRun + "\n" +
					"[userABTestGroup] " + userABTestGroup + "\n" + 
					"[stats] " + (isStatisticsDeltaDNAEnabled ? "D" : "-") + (isStatisticsNanigansEnabled ? "N" : "-") + "\n";
		}

//		public function getMobileSocialAppID(socialNetwork:String):String
//		{
//			var appIDByNetwork:Object = configObject["mobile_social_app_id"];
//			return appIDByNetwork ? appIDByNetwork[socialNetwork] : null;
//		}
//
//		public function getSocialAppIDBySocialNetwork(socialNetwork:String):String
//		{
//			var mobilePrefix:String = Device.isMobile ? "mobile_" : "";
//			var appIDByNetwork:Object = configObject[mobilePrefix + "social_app_id"];
//			return appIDByNetwork ? appIDByNetwork[socialNetwork] : null;
//		}

		/**
		 * logConfig example:
		 * 	{
		 * 		"isShowChannel": false,
		 * 		"defaultLogPriority": 2,
		 * 		"setChannelPriority": {
		 * 			"framework.screen.manager": 1, 
		 * 			"framework.dialog.screen": 1, 
		 * 			"framework.dialog.screen.container": 1
		 * 		},
		 * 		"setBlockChannelPriority": {
		 * 			"framework.net.updater": 1, 
		 * 			"framework.resource.unzip": 1
		 * 		}
		 * 	}
		 * 	
		 * @param logConfig
		 */
		private function configureLog(log:Log, logConfig:Object):void
		{
			if (!log || !logConfig)
			{
				return;
			}
			
			if (logConfig.hasOwnProperty("isShowChannel"))
			{
				log.isShowChannel = logConfig["isShowChannel"];
			}
//			if (logConfig.hasOwnProperty("isVerboseAssetManager"))
//			{
//				log.isVerboseAssetManager = logConfig["isVerboseAssetManager"];
//			}
			if (logConfig.hasOwnProperty("defaultLogPriority"))
			{
				log.defaultLogPriority = logConfig["defaultLogPriority"];
			}
			
			if (logConfig.hasOwnProperty("setChannelPriority"))
			{
				log.setChannelsPriorityByData(logConfig["setChannelPriority"]);
			}
//			if (logConfig.hasOwnProperty("setBlockChannelPriority"))
//			{
//				log.setBlockChannelsPriorityByData(logConfig["setBlockChannelPriority"]);
//			}
		}
		
	}
}
