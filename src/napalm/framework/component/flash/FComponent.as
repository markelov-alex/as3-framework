package napalm.framework.component.flash
{
	import napalm.framework.component.Component;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.ComponentManager;
	import napalm.framework.managers.DialogManager;
	import napalm.framework.managers.LanguageManager;
	import napalm.framework.managers.ResizeManager;
	import napalm.framework.managers.ResourceManager;
	import napalm.framework.managers.ScreenManager;
	import napalm.framework.managers.SystemManager;
	
	import starling.events.Event;
	
	/**
	 * fcomponent.
	 *
	 * Note: set all settings (component's public vars) before initialize()!
	 * Note: set skinObject after initialize()!
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class FComponent extends FSimpleComponent
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		public var componentType:Class;

		// (Use in subclasses)
		protected var componentManager:ComponentManager;
		protected var resourceManager:ResourceManager;
		protected var languageManager:LanguageManager;
		protected var dialogManager:DialogManager;
		protected var screenManager:ScreenManager;
		protected var resizeManager:ResizeManager;
//		protected var assetManager:AssetManagerExt;

		// Set by initialize()
//		protected var assetManagerName:String;
		// Set in subclass
		protected var isLanguageAutoUpdate:Boolean = false;

//		private var isAssetManagerGotByName:Boolean = false;

		// Properties

		override public final function set skinObject(value:Object):void
		{
			if (!_systemManager && value)
			{
				log.warn(Channel.COMPONENT, this, "Component " + this + " is not yet initialized, but skinObject is set!", Component.isProductionMode ? new Error().getStackTrace() : "");
				trace(new Error().getStackTrace());
			}
			
			// Make crash on any error
			if (!Component.isProductionMode)
			{
				super.skinObject = value;
				return;
			}
			
			// Hide crash to log
			try
			{
				super.skinObject = value;
			}
			catch (error:Error)
			{
				log.fatal(Channel.COMPONENT, "Error while setting skinObject!", this, "skinObject:", skinObject, "value:", value, error, error.getStackTrace());
			}
			
			// Language
			if (value && isLanguageAutoUpdate && languageManager)
			{
				updateTexts();
				
				// Listeners
				languageManager.addEventListener(LanguageManager.LANGUAGE_UPDATE, languageManager_languageUpdateHandler)
			}
		}

		private var _systemManager:SystemManager;
		protected function get systemManager():SystemManager
		{
			return _systemManager;
		}

		// Constructor

		public function FComponent()
		{
			// Set in subclasses:
			//isLanguageAutoUpdate = true;
		}

		// Methods

		/**
		 * Initialize component by args. Use dispose() to deinitalize.
		 *
		 * @param args[0]    systemManager:SystemManager - if null or other type is set,
		 *                    then SystemManager.getInstance() is used
		 *
		 * Recommendations:
//		 * args[1] - assetManagerName:String || assetManager:AssetManagerExt,
		 * args[2] - skinContainer:Sprite (see GUIComponent),
		 * args[3] - model,
		 * args[4+] - others
		 */
		// Override
		override public function initialize(args:Array = null):void
		{
			super.initialize(args);

			_systemManager = (args ? args[0] as SystemManager : null) || SystemManager.getInstance();
//			assetManagerName = (args ? args[1] as String : null) || assetManagerName;
//			assetManager = (args ? args[1] as AssetManagerExt : null) || assetManager;

			log = _systemManager.log;
			componentManager = _systemManager.componentManager;
			resourceManager = _systemManager.resourceManager;
			languageManager = _systemManager.languageManager;
			dialogManager = _systemManager.dialogManager;
			screenManager = _systemManager.screenManager;
			resizeManager = _systemManager.resizeManager;

//			//was in attachSkin()
//			// AssetManager
//			if (assetManagerName && !assetManager)
//			{
//				log.info(Channel.COMPONENT, this, "(attachSkin) assetManager:", assetManager);
//				assetManager = resourceManager.getAssetManagerByPackName(assetManagerName);
//				if (assetManager)
//				{
//					isAssetManagerGotByName = true;
//				}
//			}
		}

		// Override
		override public function dispose():void
		{
			// Dispose skinObject first
			skinObject = null;

			//was in detachSkin()
//			// AssetManager
//			if (isAssetManagerGotByName)
//			{
//				log.info(Channel.COMPONENT, this, "(detachSkin) assetManager:", assetManager);
//				resourceManager.disposeAssetManagerByPackName(assetManagerName);
//				assetManager = null;
//			}
//
//			assetManagerName = null;
//			assetManager = null;

			_systemManager = null;
			componentManager = null;
			resourceManager = null;
			languageManager = null;
			dialogManager = null;
			screenManager = null;

			super.dispose();
		}

		// Override
		// Note: when attachSkin() is called (set skinObject property) skinObject should be already added to stage!
		override protected function attachSkin():void
		{
			//(temp?)
			if (!systemManager)
			{
				initialize();
			}

			super.attachSkin();
		}

		// Override
		override protected function detachSkin():void
		{
			// Language
			if (languageManager)
			{
				// Listeners
				languageManager.removeEventListener(LanguageManager.LANGUAGE_UPDATE, languageManager_languageUpdateHandler)
			}

			super.detachSkin();
		}

		// Override
		/**
		 * Set isLanguageAutoUpdate=true to enable this method.
		 * Update all text fields here.
		 */
		protected function updateTexts():void
		{
		}

		// Event handlers

		private function languageManager_languageUpdateHandler(event:Event):void
		{
			updateTexts();
		}

	}
}
