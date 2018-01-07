package napalm.framework.managers
{
	import flash.events.TimerEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.net.InternetChecker;
	import napalm.framework.resource.AssetManagerExt;
	import napalm.framework.resource.updater.AssetsUpdater;
	import napalm.framework.resource.updater.ResourceJSONLoader;
	import napalm.framework.utils.ArrayUtil;
	import napalm.framework.utils.FileUtil;
	import napalm.framework.utils.ObjectUtil;
	import napalm.framework.utils.URLUtil;
	
	import starling.events.Event;
	
	[Event(name="updateResourcesProgress", type="starling.events.Event")]
	[Event(name="preloadProgress", type="starling.events.Event")]
	[Event(name="loadComplete", type="starling.events.Event")]
	[Event(name="loadProgress", type="starling.events.Event")]

	/**
	 * ResourceManager.
	 * 
	 * Note: all "mobile" prefixes in identifiers mean also "desktop" as well 
	 * (because both realized in AIR).
	 * @author alex.panoptik@gmail.com
	 */
	public class ResourceManager extends BaseManager
	{

		// Class constants

		public static const UPDATE_RESOURCES_PROGRESS:String = "updateResourcesProgress";
		public static const PRELOAD_PROGRESS:String = "preloadProgress";
		public static const PRELOAD_COMPLETE:String = "loadComplete";
		public static const LOAD_PROGRESS:String = "loadProgress";

		private static const UPDATE_PRELOAD_ASSETS_PROGRESS_INTERVAL:int = 100;

		// Class variables

		// Class methods

		private static function calculateRatioForArray(assetManagerArray:Array, totalAssetManagerCount:int = -1):Number
		{
			var ratio:Number = 0;
			if (!assetManagerArray || !assetManagerArray.length)
			{
				ratio = 1;
			}
			else
			{
				// ratioSum
				var ratioSum:Number = 0;
				var assetManagerCount:int = assetManagerArray.length;
				for (var i:int = 0; i < assetManagerCount; i++)
				{
					var assetManager:AssetManagerExt = assetManagerArray[i] as AssetManagerExt;
					if (assetManager)
					{
						ratioSum += assetManager.loadingRatio;
					}
					//log.info(Channel.RESOURCE, ResourceManager, "(calculateRatioForArray) i:",i, "/",assetManagerArray.length, 
					//		"assetManager:", assetManager, ".loadingRatio:", assetManager.loadingRatio);
				}
				
				// Result ratio
				var count:int = totalAssetManagerCount > 0 ? totalAssetManagerCount : assetManagerCount;
				ratio = ratioSum / count;
			}
			return ratio;
		}

		// Variables

		// (Set in your overridden Main.initializeManagers)
		public var isMobile:Boolean;
		public var platformCode:String;
		public var platformCodeArray:Array;
		public var availablePlatformCodeArray:Array;
		
		// ["assets1", "assets2", {"assetPackName": "assets3_dialog", "additionalPackNames": ["assets3_item"]}]
		public var preloadAssetPackNameArray:Array;
		public var loadingAnimationFactoryFunc:Function;

		// (Set up in your overridden Main.initializeManagers())
		// (Set up using setUpByRootPath(), and also setUpByVersionJSON(), setUpByResourceJSON())
		// URL of remote (usually CDN) root directory with assets (to update mobile assets using version.json)
		private var remoteRootURL:String;
		// Local (mobile) path to root directory with assets (usually updated from CDN using version.json)
		private var mobileRootPath:String;

		// (Set up using setUpByVersionJSON())
		// Remote version.json full URL
		private var versionJSONURL:String;
		// Local (mobile) version.json full path
		private var mobileVersionJSONPath:String;
		
		// (Set up using setUpByResourceJSON())
		// Remote resource.json full URL
		private var resourceJSONURL:String;
		// Local (mobile) resource.json full path
		private var mobileResourceJSONPath:String;

		// version.json (defaultResourceJSON), resource.json
		private var defaultResourceJSON:Object;
		private var resourceJSON:Object;

		private var assetsUpdater:AssetsUpdater;
		private var resourceJSONLoader:ResourceJSONLoader;
		
		// Asset managers
		private var assetManagerByPackNameLookup:Dictionary = new Dictionary();
		//#?private var assetManagerByAdditionalPackNameLookup:Dictionary = new Dictionary();
		private var assetManagerCountByPackNameLookup:Dictionary = new Dictionary();

		private var preloadAssetManagerArray:Array = [];
		private var preloadAssetManagerCount:int = 0;
		private var loadingAssetManagerArray:Array = [];
		private var loadingAssetManagerCount:int = 0;
		
		private var updateProgressTimer:Timer;

		// Properties

//		private var _isDebugLoad:Boolean = false;
//		public function get isDebugLoad():Boolean
//		{
//			return _isDebugLoad;
//		}
//		public function set isDebugLoad(value:Boolean):void
//		{
//			_isDebugLoad = value;
//
//			AssetManagerExt.isDebugLoad = value;
//		}
//
//		//private var _debugLoadIntervalMsec:int = 2000;
//		public function get debugLoadLatencyMsec():int
//		{
//			return AssetManagerExt.debugLoadLatencyMsec;//_debugLoadIntervalMsec;
//		}
//		public function set debugLoadLatencyMsec(value:int):void
//		{
//			//_debugLoadIntervalMsec = value;
//
//			AssetManagerExt.debugLoadLatencyMsec = value;
//		}
		
		private var _isPreloading:Boolean = false;
		public function get isPreloading():Boolean
		{
			return _isPreloading;
		}
		
		private var _updateResourcesRatio:Number = 0;
		public function get updateResourcesRatio():Number
		{
			return _updateResourcesRatio;
		}
		
		private var _preloadingAssetsRatio:Number = 0;
		public function get preloadingAssetsRatio():Number
		{
			return _preloadingAssetsRatio;
		}
		
		private var _loadingAssetsRatio:Number = 0;
		public function get loadingAssetsRatio():Number
		{
			return _loadingAssetsRatio;
		}

		private function get platformDir():String
		{
			return platformCode ? platformCode + "/" : "";
		}
		
		// Constructor
		
		public function ResourceManager()
		{
		}
		
		// Methods
		
		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);
			
			log.info(Channel.RESOURCE, this, "(initialize)");
		}

		override public function dispose():void
		{
			log.info(Channel.RESOURCE, this, "(dispose)");

			platformCode = null;
			platformCodeArray = null;
			availablePlatformCodeArray = null;
			preloadAssetPackNameArray = null;
			
			remoteRootURL = null;
			mobileRootPath = null;
			versionJSONURL = null;
			mobileVersionJSONPath = null;
			resourceJSONURL = null;
			mobileResourceJSONPath = null;
			
			if (assetsUpdater)
			{
				assetsUpdater.dispose();
			}
			assetsUpdater = null;

			if (resourceJSONLoader)
			{
				resourceJSONLoader.dispose();
			}
			resourceJSONLoader = null;

			for each (var assetManager:AssetManagerExt in assetManagerByPackNameLookup)
			{
				assetManager.purge();
			}

			defaultResourceJSON = null;
			resourceJSON = null;
			assetManagerByPackNameLookup = new Dictionary();
			//#?assetManagerByAdditionalPackNameLookup = new Dictionary();
			assetManagerCountByPackNameLookup = new Dictionary();
			
			_isPreloading = false;
			preloadAssetManagerArray.length = 0;
			preloadAssetManagerCount = 0;
			loadingAssetManagerArray.length = 0;
			loadingAssetManagerCount = 0;
			
			_updateResourcesRatio = 0;
			_preloadingAssetsRatio = 0;
			_loadingAssetsRatio = 0;
			
			stopUpdateProgressTimer();

			super.dispose();
		}
		
		public function createLoadingAnimationFor(component:Object):Object
		{
			if (loadingAnimationFactoryFunc == null)
			{
				return null;
			}
			
			if (!loadingAnimationFactoryFunc.length)
			{
				return loadingAnimationFactoryFunc();
			}
			else
			{
				return loadingAnimationFactoryFunc(component);
			}
		}

		public function getDefinition(name:String):Class
		{
			var applicationDomain:ApplicationDomain = ApplicationDomain.currentDomain;
			return applicationDomain.hasDefinition(name) ? applicationDomain.getDefinition(name) as Class : null;
		}

		/**
		 * The best choice of set up. version.json should be generated by php-script. 
		 * If assets updated and version.json changed, files will be loaded by new URLs for browser, 
		 * and reload to local storage for mobile.
		 * 
		 * Use this for multiversioning on server and  different assets for each platform and quality.
		 * 
		 * All "resource.json" files will be loaded automatically if they're mentioned in version JSON.
		 * So there is no need to call setUpByResourceJSON().
		 * 
		 * @param versionJSONURL
		 * @param mobileVersionJSONPath
		 */
		public function setUpByVersionJSON(versionJSONURL:String, mobileVersionJSONPath:String):void
		{
			this.versionJSONURL = versionJSONURL;
			this.mobileVersionJSONPath = mobileVersionJSONPath;
			remoteRootURL = URLUtil.getDirectoryPath(versionJSONURL);
			mobileRootPath = URLUtil.getDirectoryPath(mobileVersionJSONPath);

			log.log(Channel.RESOURCE, this, "(setUpByVersionJSON) versionJSONURL:", versionJSONURL, "mobileVersionJSONPath:", mobileVersionJSONPath);
			
			// (Only one set up method can be used)
			resourceJSONURL = null;
			mobileResourceJSONPath = null;
		}
		
		/**
		 * Use this kind of set up for demo and project quick start or for projects with 
		 * single platform-quality assets directory and assets updates not critical 
		 * (for web or when assets are inside mobile app package).
		 * 
		 * Disabled mobile assets updating from Internet.
		 * Disabled anticache by adding version get parameter to assets' URLs. 
		 * So after some assets changed, cache should be cleaned in browser, 
		 * and app package should reinstalled for mobile. 
		 * 
		 * @param resourceJSONURL
		 * @param mobileResourceJSONPath
		 */
		public function setUpByResourceJSON(resourceJSONURL:String, mobileResourceJSONPath:String):void
		{
			this.resourceJSONURL = resourceJSONURL;
			this.mobileResourceJSONPath = mobileResourceJSONPath;
			remoteRootURL = URLUtil.getDirectoryPath(resourceJSONURL);
			mobileRootPath = URLUtil.getDirectoryPath(mobileResourceJSONPath);

			log.log(Channel.RESOURCE, this, "(setUpByResourceJSON) resourceJSONURL:", resourceJSONURL, "mobileResourceJSONPath:", mobileResourceJSONPath);
			
			// (Only one set up method can be used)
			versionJSONURL = null;
			mobileVersionJSONPath = null;
		}

		/**
		 * Use this kind of set up for demo and project quick start. 
		 * 
		 * For mobile all assets must be included into package at start.
		 * Only one platform and quality type of assets supported by these URL/path.
		 * 
		 * When loading assets for each package will be built an array of URLs:
		 * var base:String = remoteRootURL(or mobileRootPath) + platformDir + packageName + "/" + packageName;
		 * var loadURLArray:Array = [base + ".json", base + ".png", base + ".xml", base + "_skeleton.json"].
		 * 
		 * @param remoteRootURL
		 * @param mobileRootPath
		 */
		public function setUpByRootPath(remoteRootURL:String, mobileRootPath:String):void
		{
			this.remoteRootURL = remoteRootURL;
			this.mobileRootPath = mobileRootPath;

			log.log(Channel.RESOURCE, this, "(setUpByRootPath) remoteRootURL:", remoteRootURL, "mobileRootPath:", mobileRootPath);
			
			// (Only one set up method can be used)
			versionJSONURL = null;
			mobileVersionJSONPath = null;
			resourceJSONURL = null;
			mobileResourceJSONPath = null;
		}

		/**
		 * Register static class with references to embedded resources. 
		 * Needed to use embedded assets in Starling.
		 * 
		 * @param embedReferencesClass
		 * @param packName
		 */
		public function registerEmbedReferencesClass(embedReferencesClass:Class, packName:String = null):void
		{
			if (!embedReferencesClass)
			{
				return;
			}
			
			packName ||= ObjectUtil.getClassName(embedReferencesClass);
			log.log(Channel.RESOURCE, this, "(registerEmbedReferencesClass) embedReferencesClass:", embedReferencesClass, "packName:", packName);
			
			embedReferencesClassByPackName[packName] = embedReferencesClass;
		}

		public function preload():void
		{
			log.log(Channel.RESOURCE, "[START-STEP-7-(a)bcdefghi] [Preload]", 
					_isPreloading ? "<return> isPreloading: " + _isPreloading : "");
			if (_isPreloading)
			{
				return;
			}
			_isPreloading = true;

			log.log(Channel.RESOURCE, this, "(preload) <updateAssets>", "isMobile:", isMobile, "versionJSONURL:", versionJSONURL, 
					"mobileVersionJSONPath:", mobileVersionJSONPath, "(resourceJSONURL:", resourceJSONURL, 
					"mobileResourceJSONPath:", mobileResourceJSONPath + ")", "((remoteRootURL:", remoteRootURL,
					"mobileRootPath:", mobileRootPath, "preloadAssetPackNameArray:", preloadAssetPackNameArray + "))");

			// Start
			if (versionJSONURL || mobileVersionJSONPath)
			{
				updateAssets();
			}
			else if (resourceJSONURL || mobileResourceJSONPath)
			{
				loadResourceJSON();
			}
			else
			{
				preloadAssets();
			}
		}

		private function updateAssets():void
		{
//			if (assetsUpdater)
//			{
//				log.warn(Channel.RESOURCE, this, " (updateAssets) <return>", "assetsUpdater:", assetsUpdater);
//				return;
//			}
			log.log(Channel.RESOURCE, "[START-STEP-7-a(b)cdefghi] Update Assets by versionJSON");
			//log.log(Channel.RESOURCE, this, " (updateAssets) <updateAssets>");
 
			// Get version JSON (and update mobile assets to local storage)
			assetsUpdater = new AssetsUpdater();
			assetsUpdater.isMobile = isMobile;
			assetsUpdater.remoteRootURL = remoteRootURL;
			assetsUpdater.mobileRootPath = mobileRootPath;
			assetsUpdater.platformCodeArray = platformCodeArray;
			assetsUpdater.availablePlatformCodeArray = availablePlatformCodeArray;

			assetsUpdater.updateAssets(versionJSONURL, mobileVersionJSONPath, loadResourceJSON, assetUpdater_onProgress);
		}

		private function loadResourceJSON(parsedVersionContentDic:Dictionary = null, defaultResourceJSON:Object = null, 
										  resourceJSONURLArray:Array = null):void
		{
			if (assetsUpdater)
			{
				assetsUpdater.dispose();
				assetsUpdater = null;
			}
//			if (resourceJSONLoader)
//			{
//				log.warn(Channel.RESOURCE, this, " (loadResourceJSON) <return>", "resourceJSONLoader:", resourceJSONLoader);
//				return;
//			}
			
			log.log(Channel.RESOURCE, "[START-STEP-7-abcdef(g)hi] Load Resource JSONs");
			log.log(Channel.RESOURCE, this, " (loadResourceJSON)", "parsedVersionContentDic:", parsedVersionContentDic);
			
			this.defaultResourceJSON = defaultResourceJSON;
			
			// (URLs for resource JSONs are given by version JSON (if setUpByVersionJSON() was used) 
			// or by params of setUpByResourceJSON())
			resourceJSONURLArray ||= [isMobile ? mobileResourceJSONPath : resourceJSONURL];

			if (!parsedVersionContentDic && (versionJSONURL || mobileVersionJSONPath))
			{
				log.fatal(Channel.RESOURCE, this, "Version JSON wasn't loaded!", "parsedVersionContentDic:", parsedVersionContentDic,
						"versionJSONURL:", versionJSONURL, "mobileVersionJSONPath:", mobileVersionJSONPath, 
						"isMobile:", isMobile);
				return;
			}

			log.log(Channel.RESOURCE, this, "  (loadResourceJSON) defaultResourceJSON:", 
					ObjectUtil.stringify(defaultResourceJSON, Log.isLogFullData ? -1 : 400));

			// Load all resource JSONs and merge in single object
			resourceJSONLoader = new ResourceJSONLoader();
			resourceJSONLoader.isMobile = isMobile;
			resourceJSONLoader.remoteRootURL = remoteRootURL;
			resourceJSONLoader.mobileRootPath = mobileRootPath;
			resourceJSONLoader.availablePlatformCodeArray = availablePlatformCodeArray;
			resourceJSONLoader.parsedVersionContentDic = parsedVersionContentDic;
			resourceJSONLoader.load(resourceJSONURLArray, preloadAssets);
		}

		private function preloadAssets(resourceJSON:Object = null):void
		{
			if (resourceJSONLoader)
			{
				resourceJSONLoader.dispose();
				resourceJSONLoader = null;
			}

			this.resourceJSON = resourceJSON;

			log.info(Channel.RESOURCE, this, "   (preloadAssets)", "resourceJSON:", ObjectUtil.stringify(resourceJSON, Log.isLogFullData ? -1 : 400));
			log.log(Channel.RESOURCE, "[START-STEP-7-abcdefg(h)i] Preload Asset packs");
			log.log(Channel.RESOURCE, this, "    (preloadAssets) preloadAssetPackNameArray:",preloadAssetPackNameArray);

			// Create & load assetManagers
			if (preloadAssetPackNameArray)
			{
				for each (var assetPack:Object in preloadAssetPackNameArray)
				{
					var assetPackName:String = assetPack as String || (assetPack.hasOwnProperty("assetPackName") ? assetPack.assetPackName : null);
					var additionalPackNames:Array = assetPack.hasOwnProperty("additionalPackNames") ? assetPack.additionalPackNames : null;
					log.log(Channel.RESOURCE, this, "     (preloadAssets) <preloadAssetManager.load> assetPackName:",assetPackName, "additionalPackNames:", additionalPackNames);
					if (assetPackName)
					{
						var preloadAssetManager:AssetManagerExt = getAssetManagerByPackName(assetPackName, additionalPackNames);
						preloadAssetManagerArray[preloadAssetManagerArray.length] = preloadAssetManager;
					}
				}

				for each (preloadAssetManager in preloadAssetManagerArray)
				{
					preloadAssetManager.load(preloadAssetManager_onLoadComplete);//, preloadAssetManager_onLoadProgress
				}
			}

			// Progress
			updateLoadingAssetsProgress();

			checkPreloadComplete();
		}

		public function getAssetManagerByPackName(assetPackName:String, additionalPackNames:Array = null,
												  postLoadPackNames:Array = null):AssetManagerExt
		{
			if (!assetPackName)
			{
				return null;
			}

			var useCount:int = assetManagerCountByPackNameLookup[assetPackName] || 0;
			useCount++;
			assetManagerCountByPackNameLookup[assetPackName] = useCount;

			// If we need assetManager for dialog
			var assetManager:AssetManagerExt = assetManagerByPackNameLookup[assetPackName] as AssetManagerExt;
			log.info(Channel.RESOURCE, this, "(getAssetManagerByPackName) assetPackName:", assetPackName, "after-useCount:", useCount,
					"assetManager:", assetManager, "platformCode:", platformCode);
			if (!assetManager)
			{
				log.log(Channel.RESOURCE, this, " (getAssetManagerByPackName) <createAssetManager>", "assetPackName:", assetPackName,
						"additionalPackNames:", additionalPackNames, "after-useCount(1!):",useCount);
				// Create
				assetManager = createAssetManager(assetPackName, additionalPackNames, postLoadPackNames);

				// Register
				assetManagerByPackNameLookup[assetPackName] = assetManager;
			}

			return assetManager;
		}

		private function createAssetManager(assetPackName:String, additionalPackNames:Array = null,
											postLoadPackNames:Array = null):AssetManagerExt
		{
			var assetManager:AssetManagerExt = new AssetManagerExt();
			// (name - only for logging)
			assetManager.name = assetPackName;// + index++;
			//-assetManager.verbose = log.isVerboseAssetManager;

			// Listeners
			assetManager.addEventListener(AssetManagerExt.LOAD_START, assetManager_loadStartHandler);
			assetManager.addEventListener(AssetManagerExt.LOAD_COMPLETE, assetManager_loadCompleteHandler);
			assetManager.addEventListener(Event.IO_ERROR, assetManager_ioErrorHandler);

			// Set up
			setUpAssetManagerByPackName(assetManager, assetPackName);
			if (additionalPackNames)
			{
				for each (var packName:* in additionalPackNames)
				{
					setUpAssetManagerByPackName(assetManager, packName);
					//#?assetManagerByAdditionalPackNameLookup[packName] = assetManager;
				}
			}
			if (postLoadPackNames)
			{
				for each (packName in postLoadPackNames)
				{
					setUpAssetManagerByPackName(assetManager, packName, true);
					//#?assetManagerByAdditionalPackNameLookup[packName] = assetManager;
				}
			}
			return assetManager;
		}

		public function disposeAssetManagerByPackName(assetPackName:String):void
		{
			if (!assetPackName)
			{
				return;
			}

			var useCount:int = assetManagerCountByPackNameLookup[assetPackName] || 0;
			useCount--;
			assetManagerCountByPackNameLookup[assetPackName] = Math.max(useCount, 0);
			log.info(Channel.RESOURCE, this, "(disposeAssetManagerByPackName) assetPackName:", assetPackName,"after-useCount:",useCount);

			if (useCount <= 0)
			{
				var assetManager:AssetManagerExt = assetManagerByPackNameLookup[assetPackName];
				log.log(Channel.RESOURCE, this, " (disposeAssetManagerByPackName) <dispose-AssetManager> " +
						"assetPackName:", assetPackName,"after-useCount(0!):",useCount,"assetManager:",assetManager);

				// Dispose
				if (assetManager)
				{
					assetManager.purge();
					// Listeners
					assetManager.removeEventListener(AssetManagerExt.LOAD_START, assetManager_loadStartHandler);
					assetManager.removeEventListener(AssetManagerExt.LOAD_COMPLETE, assetManager_loadCompleteHandler);
					assetManager.removeEventListener(Event.IO_ERROR, assetManager_ioErrorHandler);
				}

				// Unregister
				delete assetManagerByPackNameLookup[assetPackName];

				//#?ObjectUtil.deleteByValue(assetManagerByAdditionalPackNameLookup, assetManager);
			}
		}

		private var embedReferencesClassByPackName:Dictionary = new Dictionary();
		/**
		 * 
		 * @param assetManager
		 * @param packName		(String|Class)
		 * @param isPostLoad
		 */
		public function setUpAssetManagerByPackName(assetManager:AssetManagerExt, packName:*, isPostLoad:Boolean = false):void
		{
			if (!resourceJSON && !defaultResourceJSON)
			{
				log.warn(Channel.RESOURCE, this, "  (setUpAssetManagerByPackName) resourceURL.json wasn't loaded or set. Default resourceURL list will be generated.");
				//-return;
			}

			// Pack name
			var assetPackName:String = ObjectUtil.getClassName(packName);
			if (!assetManager || !assetPackName)
			{
				return;
			}

			// Get URLs
			var resourceArray:Array = resourceJSON && resourceJSON[platformCode] ? 
					resourceJSON[platformCode][assetPackName] : null;
			if (!resourceArray && defaultResourceJSON)
			{
				resourceArray = defaultResourceJSON[platformCode] ?
						defaultResourceJSON[platformCode][assetPackName] : null;
			}

			if (!resourceArray)
			{
				var embedReferencesClass:Class = embedReferencesClassByPackName[assetPackName] as Class;
				
				if (isMobile)
				{
					//				log.info(Channel.RESOURCE, this, "  (setUpAssetManagerByPackName) Asset pack wasn't defined in resourceURL.json. " +
					//						"The pack will be generated from versionJSON.", "assetPackName:", assetPackName, "resourceArray:",resourceArray);
					log.info(Channel.RESOURCE, this, "  (setUpAssetManagerByPackName) Asset pack wasn't defined in resourceJSON and versionJSON." +
							"The pack will be generated from directory.", "assetPackName:", assetPackName, "resourceArray:",resourceArray);

					//was resourceArray = generateResourceArray(assetPackName);
					CONFIG::mobile
					{
						var resourcePath:String = mobileRootPath + platformDir + assetPackName + "/";
						resourceArray = [FileUtil.getFile(resourcePath)];//[File.applicationStorageDirectory.resolvePath(resourcePath)];
						log.info(Channel.RESOURCE, this, "   (setUpAssetManagerByPackName) <FileUtil.getFile>", 
								//"mobileRootPath:", mobileRootPath, "platformDir:", platformDir, "assetPackName:", assetPackName, 
								"resourcePath:", resourcePath, "resourceArray:", ArrayUtil.getSubArrayByPropertyName(resourceArray, "url"),
								"exists:", ArrayUtil.getSubArrayByPropertyName(resourceArray, "exists"));
					}
				}
				else if (embedReferencesClass)
				{
					resourceArray = [embedReferencesClass];
					log.log(Channel.RESOURCE, this, "   (setUpAssetManagerByPackName) embedReferencesClass registered! assetPackName:",
							assetPackName, "embedReferencesClass:", embedReferencesClassByPackName[assetPackName]);
				}
				else if (!defaultResourceJSON && !resourceJSON)
				{
					var resourceItemPrefix:String = platformDir + assetPackName + "/" + assetPackName;
					resourceArray = [resourceItemPrefix + ".png", resourceItemPrefix + ".xml", 
							resourceItemPrefix + ".json", resourceItemPrefix + "_skeleton.json"];
					log.log(Channel.RESOURCE, this, "   (setUpAssetManagerByPackName) resourceArray generated by assetPackName! assetPackName:",
							assetPackName, "resourceArray:", resourceArray, "platformCode:", platformCode,
							"defaultResourceJSON:", defaultResourceJSON, "resourceJSON:", resourceJSON);
				}
				else
				{
					log.warn(Channel.RESOURCE, this, "   (setUpAssetManagerByPackName) No resourceArray with such assetPackName!!! assetPackName:",
							assetPackName, "resourceArray:", resourceArray, "==null:", resourceArray == null,
							"platformCode:", platformCode, resourceJSON && resourceJSON[platformCode],
							defaultResourceJSON ? defaultResourceJSON[platformCode] : "-", "|",
									resourceJSON && resourceJSON[platformCode] ? resourceJSON[platformCode][assetPackName] || "null" : "-",
									defaultResourceJSON && defaultResourceJSON[platformCode] ? defaultResourceJSON[platformCode][assetPackName] || "null" : "-");
				}
			}

			// Enqueue
			log.info(Channel.RESOURCE, this, "    (setUpAssetManagerByPackName) <assetManager.enqueue>", "mobileRootPath:", mobileRootPath, "resourceArray:", resourceArray);
			// resourceURL: URL or File of pack directory
			for each (var resourceURL:Object in resourceArray)
			{
				if (resourceURL is String)
				{
//					resourceURL = mobileRootPath + resourceURL;//prepareURL(resourceURL as String);
					resourceURL = (isMobile ? mobileRootPath : remoteRootURL) + resourceURL;
					CONFIG::mobile
					{
						if (FileUtil.checkExists(String(resourceURL)))
						{
							resourceURL = FileUtil.getFile(resourceURL);
						}
					}
				}
				log.info(Channel.RESOURCE, this, "     (setUpAssetManagerByPackName) <assetManager.enqueue> resourceURL:", resourceURL);
				if (resourceURL)
				{
					if (isPostLoad && !isMobile)
					{
						assetManager.postEnqueue(resourceURL);
					}
					else
					{
						assetManager.enqueue(resourceURL);
					}
				}
			}
		}

		private function preloadAssetManager_onLoadComplete(assetManager:AssetManagerExt):void
		{
			ArrayUtil.removeItem(preloadAssetManagerArray, assetManager);
			log.log(Channel.RESOURCE, this, "     (preloadAssetManager_onLoadComplete) assetManager:",assetManager,
					"preloadAssetManagerArray_length:", preloadAssetManagerArray.length, 
					"preloadAssetManagerCount:", preloadAssetManagerCount);

			checkPreloadComplete();
		}

		private function checkPreloadComplete():void
		{
			// Count
			preloadAssetManagerCount = Math.max(preloadAssetManagerCount, preloadAssetManagerArray.length);
			
			if (preloadAssetManagerArray.length == 0)
			{
				log.log(Channel.RESOURCE, this, "[START-STEP-7-abcdefgh(i)] Complete Preloading!");
				updateLoadingAssetsProgress();
				// Count
				preloadAssetManagerCount = 0;

				_isPreloading = false;

				log.log(Channel.RESOURCE, this, "      (checkPreloadComplete) <dispatch-LOAD_COMPLETE>", 
						"preloadAssetManagerCount:", preloadAssetManagerCount);
				// Dispatch
				dispatchEventWith(PRELOAD_COMPLETE);
			}
		}

		private function startUpdateProgressTimer():void
		{
			// Count
			loadingAssetManagerCount = Math.max(loadingAssetManagerCount, loadingAssetManagerArray.length);
			
			if (!updateProgressTimer)
			{
				updateProgressTimer = new Timer(UPDATE_PRELOAD_ASSETS_PROGRESS_INTERVAL);
				// Listeners
				updateProgressTimer.addEventListener(TimerEvent.TIMER, updateProgressTimer_timerHandler);
			}
			updateProgressTimer.start();
		}

		private function stopUpdateProgressTimer():void
		{
			// Count
			loadingAssetManagerCount = 0;
			
			if (updateProgressTimer)
			{
				// Listeners
				updateProgressTimer.removeEventListener(TimerEvent.TIMER, updateProgressTimer_timerHandler);
				updateProgressTimer.stop();
				updateProgressTimer = null;
			}
		}

		private function updateLoadingAssetsProgress():void
		{
			// Preload progress
			if (preloadAssetManagerArray && preloadAssetManagerArray.length)
			{
				var prevPreloadingAssetsRatio:Number = _preloadingAssetsRatio;
				_preloadingAssetsRatio = calculateRatioForArray(preloadAssetManagerArray, preloadAssetManagerCount);

				// Dispatch
				if (prevPreloadingAssetsRatio != _preloadingAssetsRatio)
				{
					dispatchEventWith(PRELOAD_PROGRESS, false, _preloadingAssetsRatio);
				}
			}

			// Load progress
			var prevLoadingAssetsRatio:Number = _loadingAssetsRatio;
			_loadingAssetsRatio = calculateRatioForArray(loadingAssetManagerArray, loadingAssetManagerCount);

			//!log.info(Channel.RESOURCE, this, "(updateLoadingAssetsProgress)", "loadingAssetsRatio:", _loadingAssetsRatio, 
			//		"preloadingAssetsRatio:", _preloadingAssetsRatio);
			// Dispatch
			if (prevLoadingAssetsRatio != _loadingAssetsRatio)
			{
				dispatchEventWith(LOAD_PROGRESS, false, _loadingAssetsRatio);
			}
		}

		// Event handlers

		private function assetManager_loadStartHandler(event:Event):void
		{
			var assetManager:AssetManagerExt = event.target as AssetManagerExt;
			if (assetManager)
			{
				ArrayUtil.pushUnique(loadingAssetManagerArray, assetManager);
				startUpdateProgressTimer();
			}
		}

		private function assetManager_loadCompleteHandler(event:Event):void
		{
			var assetManager:AssetManagerExt = event.target as AssetManagerExt;
			if (assetManager)
			{
				ArrayUtil.removeItem(loadingAssetManagerArray, assetManager);
				if (loadingAssetManagerArray.length == 0)
				{
					stopUpdateProgressTimer();
				}

				updateLoadingAssetsProgress();
			}
		}

		private function assetManager_ioErrorHandler(event:Event):void
		{
			InternetChecker.checkInternetConnection();
		}

		private function assetUpdater_onProgress(progressRatio:Number):void
		{
			_updateResourcesRatio = progressRatio;

			// Dispatch
			dispatchEventWith(UPDATE_RESOURCES_PROGRESS, false, progressRatio);
		}

		private function updateProgressTimer_timerHandler(timer:TimerEvent):void
		{
			updateLoadingAssetsProgress();
		}

	}
}
