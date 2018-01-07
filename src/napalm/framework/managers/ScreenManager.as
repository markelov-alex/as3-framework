package napalm.framework.managers
{
	import napalm.framework.dialog.Dialog;
	import napalm.framework.dialog.DialogConstants;
	import napalm.framework.dialog.ScreenContainer;
	import napalm.framework.log.Channel;
	
	import starling.events.Event;
	
	//type="napalm.framework.dialog.DialogConstants"
	[Event(name="loadStart", type="starling.events.Event")]
	[Event(name="loadComplete", type="starling.events.Event")]
	[Event(name="showStart", type="starling.events.Event")]
	[Event(name="showComplete", type="starling.events.Event")]
	[Event(name="hideStart", type="starling.events.Event")]
	[Event(name="hideComplete", type="starling.events.Event")]
	
	/**
	 * ScreenManager.
	 * 
	 * Using example (not good for multiapp loading):
	 * 	MyDialog.show(myarg1, myarg2);
	 * 	
	 * 	// In MyDialog:
	 * 	public static function show(myarg1:int, myarg2:String):void
	 * 	{
	 * 		SystemManager.getInstance().screenManager.show(MyDialog, [myarg1, myarg2]);
	 * 	}
	 * @author alex.panoptik@gmail.com
	 */
	public class ScreenManager extends BaseManager
	{
		
		// Class constants

		// Class variables
		
		// Class methods

		// Variables

		// (Set in your overridden Main.initializeManagers)
		public var loadingDialogType:Class;

		private var dialogManager:DialogManager;
		
		private var screenContainer:ScreenContainer;
		
		// Properties

		// (Dialog type used to maintain both Screen and FScreen)
		public function get currentScreen():Dialog//Screen//
		{
			return screenContainer.currentScreen;
		}

		private var _previousScreen:Dialog//Screen//;
//		public function get previousScreen():Dialog//Screen//
//		{
//			return _previousScreen;
//		}
		
		// Constructor
		
		public function ScreenManager()
		{
		}
		
		// Methods
		
		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);
			log.log(Channel.SCREEN, this, "[SCR][DLG](initialize) screenContainer:",screenContainer);

			dialogManager = systemManager.dialogManager;
			
			var componentManager:ComponentManager = systemManager.componentManager;

			screenContainer = componentManager.createComponent(ScreenContainer) as ScreenContainer;
			screenContainer.initialize([systemManager]);
			screenContainer.skinObject = systemManager.screensLayer;
			screenContainer.containerFl = systemManager.screensLayerFl;

			// Listeners
			screenContainer.addEventListener(DialogConstants.LOAD_START, screenContainer_loadStartHandler);
			screenContainer.addEventListener(DialogConstants.LOAD_COMPLETE, screenContainer_loadCompleteHandler);
			screenContainer.addEventListener(DialogConstants.SHOW_START, screenContainer_showStartHandler);
			screenContainer.addEventListener(DialogConstants.SHOW_COMPLETE, screenContainer_showCompleteHandler);
			screenContainer.addEventListener(DialogConstants.HIDE_START, screenContainer_hideStartHandler);
			screenContainer.addEventListener(DialogConstants.HIDE_COMPLETE, screenContainer_hideCompleteHandler);
		}
		
		override public function dispose():void
		{
			log.log(Channel.SCREEN, this, "[SCR][DLG](initialize) screenContainer:",screenContainer, "currentScreen:", currentScreen);
			
			// Listeners
			screenContainer.removeEventListener(DialogConstants.LOAD_START, screenContainer_loadStartHandler);
			screenContainer.removeEventListener(DialogConstants.LOAD_COMPLETE, screenContainer_loadCompleteHandler);
			screenContainer.removeEventListener(DialogConstants.SHOW_START, screenContainer_showStartHandler);
			screenContainer.removeEventListener(DialogConstants.SHOW_COMPLETE, screenContainer_showCompleteHandler);
			screenContainer.removeEventListener(DialogConstants.HIDE_START, screenContainer_hideStartHandler);
			screenContainer.removeEventListener(DialogConstants.HIDE_COMPLETE, screenContainer_hideCompleteHandler);

			screenContainer.dispose();

			dialogManager = null;
			screenContainer = null;
			_previousScreen = null;

			super.dispose();
		}
		
		public function show(screenType:Class, args:Array = null):void
		{
			log.log(Channel.SCREEN, "\n -SHOW-SCREEN-", String(screenType));
			if (!screenType)
			{
				return;
			}
			
			log.log(Channel.SCREEN, log.getTotalInfo());
			log.log(Channel.SCREEN, this, "[SCR][DLG](SHOW) screenType:",screenType,"args:", args, "currentScreen:", currentScreen);
			_previousScreen = currentScreen;
			screenContainer.show(screenType, args);// as Screen;
		}
		
		/**
		 * 
		 * @param screen (Class|Screen)
		 */
		public function hide(screen:*, isForce:Boolean = false):void
		{
			log.log(Channel.SCREEN, this, "[SCR][DLG](HIDE) screen:",screen, "isForce:", isForce);
			screenContainer.hide(screen, isForce);
		}
		
		// Event handlers

		private function screenContainer_loadStartHandler(event:Event):void
		{
			log.log(Channel.SCREEN, this, "[SCR][DLG](screenContainer_loadStartHandler) <show-loadingdialog?> " +
				"loadingDialogType:",loadingDialogType, "currentScreen:", currentScreen);
			
			if (loadingDialogType && currentScreen)
			{
				dialogManager.show(loadingDialogType);
			}

			// Redispatch
			dispatchEvent(event);
		}

		private function screenContainer_loadCompleteHandler(event:Event):void
		{
			log.info(Channel.SCREEN, this, "[SCR][DLG](screenContainer_loadCompleteHandler) <hide-loadingdialog?> " +
				"loadingDialogType:",loadingDialogType, "currentScreen:", currentScreen);
			
			if (loadingDialogType)
			{
				dialogManager.hide(loadingDialogType);
			}
			
			// Redispatch
			dispatchEvent(event);
		}

		private function screenContainer_showStartHandler(event:Event):void
		{
			log.info(Channel.SCREEN, this, "[SCR][DLG](screenContainer_showStartHandler) currentScreen:", currentScreen);
			
			// Redispatch
			dispatchEvent(event);
		}

		private function screenContainer_showCompleteHandler(event:Event):void
		{
			log.info(Channel.SCREEN, this, "[SCR][DLG](screenContainer_showCompleteHandler) currentScreen:", currentScreen);
			
			// Redispatch
			dispatchEvent(event);
		}

		private function screenContainer_hideStartHandler(event:Event):void
		{
			log.info(Channel.SCREEN, this, "[SCR][DLG](screenContainer_hideStartHandler) currentScreen:", currentScreen);
			
			// Redispatch
			dispatchEvent(event);
		}

		private function screenContainer_hideCompleteHandler(event:Event):void
		{
			var screen:Dialog = event.data as Dialog;//var screen:Screen = event.data as Screen;//
			log.info(Channel.SCREEN, this, "[SCR][DLG](screenContainer_hideCompleteHandler) screen:", screen,"currentScreen:", currentScreen);
			
			if (screen == currentScreen)
			{
				_previousScreen = currentScreen;
			}

			// Redispatch
			dispatchEvent(event);
		}
		
	}
}
