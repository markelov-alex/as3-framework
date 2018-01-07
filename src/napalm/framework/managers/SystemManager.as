package napalm.framework.managers
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.utils.Dictionary;
	
	import napalm.framework.config.Device;
	import napalm.framework.config.Preferences;
	import napalm.framework.core.Application;
	import napalm.framework.display.GUIConstructor;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.EventDispatcher;
	
	/**
	 * SystemManager.
	 *
	 * Note: We can use only the managers which we have in this package,
	 * 		 we cann't extend these managers.
	 * @author alex.panoptik@gmail.com
	 */
	public class SystemManager extends EventDispatcher
	{
		
		// Class constants

		// Class variables
		
		private static var instance:SystemManager;
		private static var instanceByAppID:Dictionary = new Dictionary();
		private static var isCreationEnabled:Boolean = false;
		
		// Class properties

		private static var _instanceCount:int = 0;
		public static function get instanceCount():int
		{
			return _instanceCount;
		}
		
		// Class methods
		
		/**
		 * Use getInstance() to get/create SystemManager.
		 * Multiple instances could be used when one loader app loads other application. 
		 * If only one instance used in application appID can be ommitted (set to null).
		 * 
		 * @param appID
		 * @return
		 */
		public static function getInstance(appID:String = null):SystemManager
		{
			if (appID)
			{
				var systemManager:SystemManager = instanceByAppID[appID] as SystemManager;
				if (!systemManager)
				{
					isCreationEnabled = true;
					systemManager = new SystemManager(appID);
					_instanceCount++;
					isCreationEnabled = false;
					instanceByAppID[appID] = systemManager;
				}
				return systemManager;
			}
			
			if (!instance)
			{
				isCreationEnabled = true;
				instance = new SystemManager();
				_instanceCount++;
				isCreationEnabled = false;
			}
			return instance;
		}
		
		// Variables
		
		private var isInitialized:Boolean = false;
		private var isLocked:Boolean = false;
		
		private var controllerByTypeLookup:Dictionary = new Dictionary();
		private var modelByTypeLookup:Dictionary = new Dictionary();
		
		// Properties

		private var _appID:String;
		public function get appID():String
		{
			return _appID;
		}
		
		private var _isDebug:Boolean = false;
		public function get isDebug():Boolean
		{
			return _isDebug;
		}
		public function set isDebug(value:Boolean):void
		{
			if (isLocked || _isDebug === value)
			{
				if (isLocked)
				{
					log.warn(Channel.SYSTEM, this, "SystemManager is already locked! Cannot set isDebug. " +
						"cur-isDebug:", isDebug, "value:", value);
				}
				return;
			}

			log.info(Channel.SYSTEM, this, "(set-isDebug) prev:",_isDebug, "new:", value);
			_isDebug = value;
		}
		
		private var _log:Log;
		public function get log():Log
		{
			return _log;
		}

		private var _main:DisplayObjectContainer;
		public function get main():flash.display.Sprite { return _main as flash.display.Sprite; }
		
		public function get application():Application { return _main as Application; }

		public function get stage():Stage { return _main ? _main.stage : null; }

		private var _starlingArray:Array;
		public function get starlingArray():Array { return _starlingArray; }

		private var _starling:Starling;
		public function get starling():Starling { return _starling; }

		private var _starlingRoot:Sprite;
		public function get starlingRoot():Sprite { return _starlingRoot; }

		public function get starlingStage():starling.display.Stage { return _starlingRoot ? _starlingRoot.stage : null; }

		private var _preferences:Preferences;
		public function get preferences():Preferences
		{
			return _preferences;
		}
		
		// Managers
		
		private var _resourceManager:ResourceManager;
		public function get resourceManager():ResourceManager { return _resourceManager; }
		
		private var _resizeManager:ResizeManager;
		public function get resizeManager():ResizeManager { return _resizeManager; }
		
		private var _componentManager:ComponentManager;
		public function get componentManager():ComponentManager { return _componentManager; }
		
		private var _audioManager:AudioManager;
		public function get audioManager():AudioManager { return _audioManager; }
		
		private var _languageManager:LanguageManager;
		public function get languageManager():LanguageManager { return _languageManager; }
		
		private var _screenManager:ScreenManager;
		public function get screenManager():ScreenManager { return _screenManager; }
		
		private var _dialogManager:DialogManager;
		public function get dialogManager():DialogManager { return _dialogManager; }

		private var _keyboardManager:KeyboardManager;
		public function get keyboardManager():KeyboardManager { return _keyboardManager; }

		// GUIConstructor
		
		private var _guiConstructor:GUIConstructor;
		public function get guiConstructor():GUIConstructor { return _guiConstructor; }
		
		// Starling layers
		
		private var _underScreensLayer:Sprite;
		public function get underScreensLayer():Sprite { return _underScreensLayer; }
		
		private var _screensLayer:Sprite;
		public function get screensLayer():Sprite { return _screensLayer; }
		
		private var _underDialogsLayer:Sprite;
		public function get underDialogsLayer():Sprite { return _underDialogsLayer; }
		
		private var _dialogsLayer:Sprite;
		public function get dialogsLayer():Sprite { return _dialogsLayer; }
		
		private var _topLayer:Sprite;
		public function get topLayer():Sprite { return _topLayer; }

		private var _screensLayerFl:flash.display.Sprite;
		public function get screensLayerFl():flash.display.Sprite { return _screensLayerFl; }

		private var _dialogsLayerFl:flash.display.Sprite;
		public function get dialogsLayerFl():flash.display.Sprite { return _dialogsLayerFl; }
		
		// Constructor
		
		public function SystemManager(appID:String = null)
		{
			_appID = appID;
			_log = appID ? new Log(appID) : Log.instance;
			
			if (!isCreationEnabled)
			{
				throw new Error("SystemManager could not be created by constructor in app! Use SystemManager.getInstance().")
			}
		}
		
		// Methods

		/**
		 * 
		 * @param main      root or stage (NativeWindow doesn't have root)
		 * @param starlings (Starling|Array of Starling) the first item in array should be the main one 
		 * 					(to set "starling" and "starlingRoot")
		 */
		public function initialize(main:DisplayObjectContainer, starlings:*):void
		{
			if (isInitialized || !main)
			{
				log.log(Channel.SYSTEM, this, "(initialize) <return> main:", main, "isInitialized:",isInitialized);
				return;
			}
			
			log.log(Channel.SYSTEM, this, "(initialize) main:", main, "starlings:", starlings, "isInitialized:",isInitialized, "(appID:", appID + ")");
			
			isInitialized = true;
			
			// Main references
			_main = main;
			_starlingArray = starlings is Starling ? [starlings] : starlings as Array;
			_starling = _starlingArray && _starlingArray.length ? _starlingArray[0] : null;
			_starlingRoot = starling ? starling.root as Sprite : null;

			//temp
			Device.initialize(stage, false);
			
			// Layers
			_underScreensLayer = new Sprite();
			_screensLayer = new Sprite();
			_underDialogsLayer = new Sprite();
			_dialogsLayer = new Sprite();
			_topLayer = new Sprite();

			if (_starlingRoot)
			{
				_starlingRoot.addChild(_underScreensLayer);
				_starlingRoot.addChild(_screensLayer);
				_starlingRoot.addChild(_underDialogsLayer);
				_starlingRoot.addChild(_dialogsLayer);
				_starlingRoot.addChild(_topLayer);
			}
			
			// Flash layers
			_screensLayerFl = new flash.display.Sprite();
			_dialogsLayerFl = new flash.display.Sprite();
			_main.addChild(_screensLayerFl);
			_main.addChild(_dialogsLayerFl);

			_preferences = new Preferences(appID || "napalm_default");//??getQualifiedClassName(main) + "_" +
			
			// Managers
			_resourceManager = new ResourceManager();
			_resizeManager = new ResizeManager();
			_componentManager = new ComponentManager();
			_audioManager = new AudioManager();
			_languageManager = new LanguageManager();
			_screenManager = new ScreenManager();
			_dialogManager = new DialogManager();
			_keyboardManager = new KeyboardManager();
			
			// (1st)
			_resourceManager.initialize(this);
			_resizeManager.initialize(this);
			_componentManager.initialize(this);
			// (2nd)
			_audioManager.initialize(this);
			_languageManager.initialize(this);
			_screenManager.initialize(this);
			_dialogManager.initialize(this);
			_keyboardManager.initialize(this);
			
			// GUIConstructor
			_guiConstructor = new GUIConstructor();
			_guiConstructor.initialize(starlingStage, resizeManager);
		}
		
		public function dispose():void
		{
			if (!isInitialized)
			{
				return;
			}
			log.log(Channel.SYSTEM, this, "(dispose) main:", application, "starling:", starling,
				"isInitialized:",isInitialized, "isLocked:", isLocked, "(appID:", appID + ")");
			
			isInitialized = false;
			isLocked = false;
			
			// Dispose
			if (application)
			{
				application.dispose();
			}

			if (_guiConstructor)
			{
				_guiConstructor.dispose();
				_guiConstructor = null;
			}
			
			if (_resourceManager)
			{
				_resourceManager.dispose();
				_resizeManager.dispose();
				_componentManager.dispose();
				_audioManager.dispose();
				_languageManager.dispose();
				_screenManager.dispose();
				_dialogManager.dispose();
				_keyboardManager.dispose();
			}

			// Layers
			if (_underScreensLayer)
			{
				_underScreensLayer.removeFromParent();
				_screensLayer.removeFromParent();
				_underDialogsLayer.removeFromParent();
				_dialogsLayer.removeFromParent();
				_topLayer.removeFromParent();
				
				_underScreensLayer = null;
				_screensLayer = null;
				_underDialogsLayer = null;
				_dialogsLayer = null;
				_topLayer = null;
			}

			// Flash layers
			_screensLayerFl.parent.removeChild(_screensLayerFl);
			_dialogsLayerFl.parent.removeChild(_dialogsLayerFl);
			_screensLayerFl = null;
			_dialogsLayerFl = null;
			
			if (_starlingRoot)
			{
				_starlingRoot.removeChildren();
			}//?-?(0, -1, true);
			
			// Null
			controllerByTypeLookup = new Dictionary();
			modelByTypeLookup = new Dictionary();
			_resourceManager = null;
			_resizeManager = null;
			_componentManager = null;
			_audioManager = null;
			_languageManager = null;
			_screenManager = null;
			_dialogManager = null;
			_keyboardManager = null;

			_main = null;
			_starlingArray = null;
			_starling = null;
			_starlingRoot = null;

			if (_appID)
			{
				instanceByAppID[_appID] = null;
			}
			else
			{
				instance = null;
			}
			_appID = null;
			_instanceCount--;
		}

		/**
		 * Lock SystemManager to prevent registering global controllers 
		 * and models after application was initialized.
		 */
		public function lock():void
		{
			log.log(Channel.SYSTEM, this, "(lock) prev-isLocked:", isLocked);
			isLocked = true;
		}

		/**
		 * You may store some global controllers here.
		 *
		 * Useful to override some controllers in derived projects (like components in ComponentManager).
		 * 
		 * Note: Don't register controllers if they're using only in bounds 
		 * 		 of a single Dialog or a single Screen. Such controllers aren't global!
		 * 
		 * @param controllerType
		 * @param controller
		 */
		public function registerController(controllerType:Class, controller:Object):void
		{
			if (controllerByTypeLookup[controllerType])
			{
				log.warn(Channel.SYSTEM, this, "Skip controller! Controller of type '" + controllerType + 
					"' is already registered! prev-controller:", controllerByTypeLookup[controllerType], " new-controller:", controller);
				return;
			}
			if (isLocked)
			{
				log.warn(Channel.SYSTEM, this, "SystemManager is already locked! You cannot register any global controller. " +
					"controllerType:", controllerType, "controller:", controller);
				return;
			}

			log.log(Channel.SYSTEM, this, "(registerController) controllerType:",controllerType,"controller:", controller);
			controllerByTypeLookup[controllerType] = controller;
		}
		
		/**
		 * You may store some global models here.
		 * 
		 * Useful to override some models in derived projects (like components in ComponentManager).
		 * 
		 * Note: Don't register models if they're using only in bounds
		 * 		 of a single Dialog or a single Screen. Such models aren't global!
		 * 
		 * @param modelType
		 * @param model
		 */
		public function registerModel(modelType:Class, model:Object):void
		{
			if (modelByTypeLookup[modelType])
			{
				log.warn(Channel.SYSTEM, this, "Skip model! Model of type '" + modelType +
					"' is already registered! prev-model:", modelByTypeLookup[modelType], " new-model:", model);
				return;
			}
			if (isLocked)
			{
				log.warn(Channel.SYSTEM, this, "SystemManager is already locked! You cannot register any global model. " +
					"modelType:", modelType,"model:", model);
				return;
			}
			
			log.log(Channel.SYSTEM, this, "(registerModel) modelType:", modelType,"model:", model);
			modelByTypeLookup[modelType] = model;
		}

		/**
		 * Best practice: Use only in Dialog or Screen subclass!
		 * All other components (panels, lists, etc) should
		 * get references through their initialize() method.
		 * 
		 * @param controllerType
		 * @return
		 */
		public function getController(controllerType:Class):Object
		{
			return controllerByTypeLookup[controllerType];
		}
		
		/**
		 * Best practice: Use only in Dialog or Screen subclass!
		 * All other components (panels, lists, etc) should 
		 * get references through their initialize() method.
		 * 
		 * @param modelType
		 * @return
		 */
		public function getModel(modelType:Class):Object
		{
			return modelByTypeLookup[modelType];
		}
		
		// Event handlers
		
	}
}
