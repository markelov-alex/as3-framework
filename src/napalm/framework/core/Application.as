package napalm.framework.core
{
	import napalm.framework.config.AppConfig;
	import napalm.framework.config.Device;
	import napalm.framework.config.URLConfig;
	import napalm.framework.dialog.DialogConstants;
	import napalm.framework.log.BugReporter;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.AudioManager;
	import napalm.framework.managers.ComponentManager;
	import napalm.framework.managers.DialogManager;
	import napalm.framework.managers.LanguageManager;
	import napalm.framework.managers.ResizeManager;
	import napalm.framework.managers.ResourceManager;
	import napalm.framework.managers.ScreenManager;
	import napalm.framework.managers.SystemManager;
	import napalm.framework.net.InternetChecker;
	import napalm.framework.preloader.classes.PreloadingEvent;
	import napalm.framework.preloader.classes.PreloadingPartName;
	import napalm.framework.utils.StarlingUtil;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	/**
	 * Application.
	 * 
	 * Base class of your Main class for using with framework.
	 * 
	 * Application initialization processed here.
	 *
	 * Initialization steps:
	 * 1. Wait for added to stage.
	 * 2. Init Starling (wait for ROOT_CREATED).
	 * 3. Init Framework (managers, create initial component tree).
	 * 4. Load resources (according to created component tree. Wait for LOAD_COMPLETE).
	 * 5. Start application!
	 * @author alex.panoptik@gmail.com
	 */
	public class Application extends SimpleApplication
	{

		// Class constants

		// Class variables

		// Class methods

		// Variables
		
		protected var appConfig:AppConfig;
		protected var urlConfig:URLConfig;

		// Set in subclasses!
		protected var startScreenType:Class;

		protected var systemManager:SystemManager;
		protected var resourceManager:ResourceManager;
		protected var resizeManager:ResizeManager;
		protected var componentManager:ComponentManager;
		protected var audioManager:AudioManager;
		protected var languageManager:LanguageManager;
		protected var screenManager:ScreenManager;
		protected var dialogManager:DialogManager;

		// Properties

		// Constructor

		public function Application()
		{
			// (Use ResizeManager inside your components instead of updateSize() here)
			isListenResize = false;
			
			// In subclass:
			//GUIConstructor.isDebugRectEnabled = true;
			// Set up logs
			//log.defaultLogPriority = log.INFO_PRIORITY;
			// Framework
			//log.setChannelPriority(ComponentManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(DialogManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(ResizeManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(ResourceManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(ScreenManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(SystemManager.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(GUIConstructor.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(GUISkin.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(Component.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(Container.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(GUIComponent.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(Dialog.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(DialogContainer.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(Screen.Channel.APPLICATION, log.INFO_PRIORITY);
			//log.setChannelPriority(ScreenContainer.Channel.APPLICATION, log.INFO_PRIORITY);
			// Other
			//log.setChannelPriority(.Channel.APPLICATION, log.INFO_PRIORITY);
			// Block
			//log.setBlockChannelPriority(.Channel.APPLICATION, log.INFO_PRIORITY);
		}

		// Methods

		/**
		 * Initialize from Preloader before added to stage.
		 *
		 * @param appConfig
		 */
		public function initialize(appConfig:AppConfig = null):void
		{
			log.log(Channel.APPLICATION, this, "(initialize) appConfig:", appConfig);
			if (!appConfig)
			{
				//todo load config and call initialize() again
				return;
			}
			
			this.appConfig = appConfig;
			urlConfig = appConfig.urlConfig;

			log.log(Channel.APPLICATION, this, "");
			log.log(Channel.APPLICATION, this, appConfig.getAppInfo());

			BugReporter.reportURL = urlConfig.bugReportURL;
			BugReporter.isProduction = appConfig.isProduction;
			BugReporter.socialUserID = appConfig.socialUserID;
			BugReporter.socialNetwork = appConfig.socialNetwork;
			BugReporter.appInfo = appConfig.getAppInfo();
			BugReporter.isAttachScreenShot = true;

			//In subclass:
			//appConfig.setVersion(Version.VERSION, Version.REVISION, Version.BUILD_TIMESTAMP);
		}

		override public function dispose():void
		{
			appConfig = null;
			urlConfig = null;

			if (systemManager)
			{
				systemManager.dispose();
				systemManager = null;
			}

			//explicitAppWidth = -1;
			//explicitAppHeight = -1;

			// Set in subclasses!
			///startScreenType = null;

			resourceManager = null;
			resizeManager = null;
			componentManager = null;
			audioManager = null;
			languageManager = null;
			screenManager = null;
			dialogManager = null;
			
			super.dispose();
		}

		override public function setAppSize(appWidth:int, appHeight:int):void
		{
			if (resizeManager)
			{
				resizeManager.setAppSize(appWidth, appHeight);
			}

			super.setAppSize(appWidth, appHeight);
		}

		override protected function startApplication():void
		{
			if (starling)
			{
				BugReporter.getScreenShot = function ():void
				{
					StarlingUtil.getScreenShotBase64(starling, 0.75, 0, 40);
				};
			}

			// Initialize framework
			log.log(Channel.APPLICATION, this, "[START-STEP-3] Create & init Managers");
			initFramework();

			// Start Starling
			log.log(Channel.APPLICATION, this, "[START-STEP-4] Start Starling");
			super.startApplication();

			// Preload
			log.log(Channel.APPLICATION, this, "[START-STEP-5] [Preload resources]..");
			preloadAndStart();
		}

		private function initFramework():void
		{
			log.log(Channel.APPLICATION, this, "\n-Initialize-Main-");
			log.log(Channel.APPLICATION, this, "(initFramework) <create-SystemManager-managers> starlingRoot:", starlingRoot, 
					"Starling-driverInfo:", Starling.context ? Starling.context.driverInfo : "-", "visible:", visible);

			// Start managers
			var appID:String = !SystemManager.instanceCount ? null : "napalm_" + appConfig.socialAppID + "_" + "app" + SystemManager.instanceCount;
			systemManager = SystemManager.getInstance(appID);
			// All managers created and initialized here
			systemManager.initialize(this, starling);
			log = systemManager.log;

			resourceManager = systemManager.resourceManager;
			resizeManager = systemManager.resizeManager;
			componentManager = systemManager.componentManager;
			audioManager = systemManager.audioManager;
			languageManager = systemManager.languageManager;
			screenManager = systemManager.screenManager;
			dialogManager = systemManager.dialogManager;

			// Configure managers
			initializeManagers();
			systemManager.lock();
		}

		// Override
		protected function initializeManagers():void
		{
			log.log(Channel.APPLICATION, this, "(initializeManagers) <custom-managers-setup> urlConfig.assetsVersionJSONURL:", urlConfig.assetsVersionJSONURL);

			if (!appConfig)
			{
				log.warn(Channel.APPLICATION, this, "(initializeManagers) appConfig wasn't set! Create empty appConfig. appConfig, urlConfig:", 
						appConfig, urlConfig);
				appConfig = new AppConfig();
				urlConfig = appConfig.urlConfig;
			}

			if (!appConfig.isDevVersion && starling)
			{
				starling.showStatsAt();//HAlign.RIGHT, VAlign.CENTER, 1);//
				starling.showStats = true;
			}
			
			InternetChecker.pingURL = urlConfig.mobileCheckInternetStaticURL || urlConfig.mobileCheckInternetURL;

			systemManager.isDebug = appConfig.isDevVersion && !appConfig.isProduction;

			resourceManager.isMobile = Device.isMobile;
			resourceManager.platformCode = urlConfig.platformCode;
			resourceManager.platformCodeArray = urlConfig.platformCodeArray;
			resourceManager.availablePlatformCodeArray = urlConfig.availablePlatformCodeArray;
			resourceManager.setUpByVersionJSON(urlConfig.assetsVersionJSONURL, urlConfig.mobileAssetsVersionJSONPath);

			resizeManager.setAppSize(explicitAppWidth, explicitAppHeight);

			componentManager;
			audioManager;

			languageManager.availableLanguageCodeArray = appConfig.availableLanguageCodeArray;
			languageManager.getRemoteLanguageURLByCode = urlConfig.getRemoteLanguageURLByCode;
			languageManager.getMobileLanguagePathByCode = urlConfig.getMobileLanguagePathByCode;
			languageManager.socialNetwork = appConfig.socialNetwork;
			languageManager.currentLanguageCode = appConfig.languageCode;

			screenManager;
			dialogManager;

//			// In subclasses:
//			//! Use "StarlingUtil.makeAllContainersTouchable(displayContainer)" in components
//			//GUIConstructor.isAllTouchableByDefault = false;
//			
//			//resizeManager.setInitialHDAssetsSize(2000, 1300);
//			
//			//systemManager.registerController(MyController, new MyController());
//			//systemManager.registerModel(MyModel, new MyModel());
//
//			//componentManager.registerComponentType(BaseComponent, CustomComponent);
//
//			resourceManager.versionURL = urlConfig.assetsVersionJSONURLURL;
//			resourceManager.mobileVersionPath = urlConfig.mobileVersionPath;
//
//			// All: "http://buttons.local/client_flash/assets/" or "http://buttons-test.3a-games.com/dev_cdn/"
//			resourceManager.remoteRootURL = urlConfig.staticRootPathURL;
//			// Web: "http://buttons.local/client_flash/assets/" or "http://buttons-test.3a-games.com/dev_cdn/"
//			// Mobile: "assets/"
//			resourceManager.mobileRootPath = urlConfig.mobileRootPath;
//			log.log(Channel.APPLICATION, this, " (initializeManagers) resourceManager", "versionURL:", resourceManager.versionURL,
//				"mobileVersionPath:", resourceManager.mobileVersionPath, "remoteRootURL:", resourceManager.remoteRootURL,
//				"mobileRootPath:", resourceManager.mobileRootPath, "urlConfig.mobileRootPath:", urlConfig.mobileRootPath);
//
//			//resourceManager.preloadAssetPackNameArray = ["LoadingDialog", "LoadingGateDialog", new CashDialog()];
//
//			//audioManager. = ;
//			//screenManager. = ;
//			//dialogManager. = ;
//			CONFIG::web
//			{
//				languageManager.currentLanguageCode = appConfig.languageCode;
//			}
//
//			//startScreenType = LobbyScreen;
		}

		private function preloadAndStart():void
		{
			log.log(Channel.APPLICATION, this, "(preloadAndStart) <loadLanguages>");
			loadLanguages();
		}

		private function loadLanguages():void
		{
			log.log(Channel.APPLICATION, this, "[START-STEP-6] Load Languages");
			log.log(Channel.APPLICATION, this, "(loadLanguages) <LangManager.loadLanguages>");
			languageManager.loadLanguages(preloadAssets);
		}

		private function preloadAssets():void
		{
			setPreloadingPartProgress(PreloadingPartName.LANGUAGES, 1);

			log.log(Channel.APPLICATION, this, "[START-STEP-7] [Preload Assets]");
			log.log(Channel.APPLICATION, this, "(preloadAssets) <resourceManager.preloadAssets>");
			
			// Listeners
			resourceManager.addEventListener(ResourceManager.UPDATE_RESOURCES_PROGRESS, 
					resourceManager_updateResourcesProgressHandler);
			resourceManager.addEventListener(ResourceManager.PRELOAD_PROGRESS, resourceManager_preloadProgressHandler);
			resourceManager.addEventListener(ResourceManager.PRELOAD_COMPLETE, resourceManager_preloadCompleteHandler);

			// Add assets to load in initializeManagers()
			resourceManager.preload();
		}

		// Override
		protected function launchApplication():void
		{
			// In subclass you can change startScreenType:
			//if (isTutorialBegin)
			//{
			//	startScreenType = GameScreen;
			//}

			log.log(Channel.APPLICATION, this, "[START-STEP-9] [Start Application] Show screen:", startScreenType);
			log.log(Channel.APPLICATION, this, "\n-Start-Main-");
			log.log(Channel.APPLICATION, this, "(startApplication) <screenManager-show> startScreenType:", startScreenType);

			// Listeners
			resourceManager.addEventListener(ResourceManager.LOAD_PROGRESS, resourceManager_loadProgressHandler);
			screenManager.addEventListener(DialogConstants.SHOW_COMPLETE, screenManager_showCompleteHandler);

			if (!startScreenType)
			{
				log.warn(Channel.APPLICATION, this, "(startApplication) Please set startScreenType in your Main.initializeManagers()!", 
						"startScreenType:", startScreenType);
			}

			screenManager.show(startScreenType);
		}

		protected function setPreloadingPartProgress(preloadingPartName:String, loadingRatio:Number):void
		{
			// Dispatch preloading data for preloader
			// Dispatch
			dispatchEvent(new PreloadingEvent(preloadingPartName, loadingRatio));
		}

//		public static const STATISTIC_DELTA_DNA:String = "deltaDNA";
//		public static const STATISTIC_NANIGANS:String = "nanigans";
//		
//		protected function addStatistic(service:String, userID:String):void
//		{
//			var platform:String;
//
//			if (Device.isMobile)
//			{
//				if (Device.isIOS)
//				{
//					platform = DeltaDNAParamTypes.IOS_PLATFORM;
//				}
//				else
//				{
//					platform = DeltaDNAParamTypes.ANDROID_PLATFORM;
//				}
//			}
//			else
//			{
//				if (appConfig.socialNetwork == SocialNetwork.FB)
//				{
//					Statistics.millisecondsOffset = -8 * 60 * 60 * 1000;
//					platform = DeltaDNAParamTypes.FACEBOOK_PLATFORM;
//				}
//				else
//				{
//					if (appConfig.socialNetwork == SocialNetwork.OK)
//					{
//						Statistics.millisecondsOffset = 3 * 60 * 60 * 1000;
//					}
//
//					platform = DeltaDNAParamTypes.WEB_PLATFORM;
//				}
//			}
//
//			switch (service)
//			{
//				case STATISTIC_DELTA_DNA:
//					if (appConfig.isEnableStatisticDeltaDNA)
//					{
//						Statistics.addService(DeltaDNAService, userID, urlConfig.statisticDeltaDNA, platform);
//					}
//					break;
//
//				case STATISTIC_NANIGANS:
//					if (appConfig.isEnableStatisticNanigans)
//					{
//						Statistics.addService(NanigansService, userID, urlConfig.statisticNanigans, platform);
//					}
//					break;
//			}
//		}

		// Event handlers

		private function resourceManager_updateResourcesProgressHandler(event:Event):void
		{
			//!log.info(Channel.APPLICATION, this, "(resourceManager_updateResourcesProgressHandler) updateResourcesRatio:", 
			// resourceManager.updateResourcesRatio);

			setPreloadingPartProgress(PreloadingPartName.RESOURCES, resourceManager.updateResourcesRatio);
		}

		private function resourceManager_preloadProgressHandler(event:Event):void
		{
			//!log.info(Channel.APPLICATION, this, "(resourceManager_preloadAssetsProgressHandler) preloadingAssetsRatio:", 
			// resourceManager.preloadingAssetsRatio);

			setPreloadingPartProgress(PreloadingPartName.ASSETS, resourceManager.preloadingAssetsRatio);
		}

		private function resourceManager_preloadCompleteHandler(event:Event):void
		{
			log.log(Channel.APPLICATION, this, "(resourceManager_preloadCompleteHandler) <startApplication>");
			log.log(Channel.APPLICATION, this, "[START-STEP-8] [Resource Loading Complete]");

			// Listeners
			resourceManager.removeEventListener(ResourceManager.UPDATE_RESOURCES_PROGRESS, resourceManager_updateResourcesProgressHandler);
			resourceManager.removeEventListener(ResourceManager.PRELOAD_PROGRESS, resourceManager_preloadProgressHandler);
			resourceManager.removeEventListener(ResourceManager.PRELOAD_COMPLETE, resourceManager_preloadCompleteHandler);

			// Start
			launchApplication();
		}

		private function resourceManager_loadProgressHandler(event:Event):void
		{
			//!log.info(Channel.APPLICATION, this, "(resourceManager_loadAssetsProgressHandler) loadingAssetsRatio:", 
			// resourceManager.loadingAssetsRatio);

			setPreloadingPartProgress(PreloadingPartName.GUI, resourceManager.loadingAssetsRatio);
		}

		protected function screenManager_showCompleteHandler(event:Event):void
		{
			log.log(Channel.APPLICATION, this, "(screenManager_showCompleteHandler) <applicationStarted>");

			// Listeners
			resourceManager.removeEventListener(ResourceManager.LOAD_PROGRESS, resourceManager_loadProgressHandler);
			screenManager.removeEventListener(DialogConstants.SHOW_COMPLETE, screenManager_showCompleteHandler);

			log.log(Channel.APPLICATION, this, "[START-STEP-10-LAST] Application Ready! (Screen show complete)");
			// Ready
			applicationLaunched();
		}

	}
}
