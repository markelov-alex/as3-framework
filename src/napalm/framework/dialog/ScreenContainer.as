package napalm.framework.dialog
{
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
	 * ScreenContainer.
	 * 
	 * Note: You can override ScreenContainer like any other component
	 * in your overridden Main.initializeManagers():
	 *    componentManager.registerComponentType(ScreenContainer, MyCustomScreenContainer);
	 *
	 *    Note: ScreenContainer can operate only with Screen and its subclasses.
	 * @author alex.panoptik@gmail.com
	 */
	public class ScreenContainer extends DialogContainer
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		// (Dialog type used to maintain both Screen and FScreen)
		private var previousScreen:Dialog;//Screen;
		private var nextScreenObject:Object;

		// Properties
		
		private var _currentScreen:Dialog;//Screen;
		public function get currentScreen():Dialog//Screen
		{
			return _currentScreen;
		}

		// Constructor

		public function ScreenContainer()
		{
		}

		// Methods

		override public function dispose():void
		{
			_currentScreen = null;
			previousScreen = null;
			nextScreenObject = null;
			
			super.dispose();
		}

		override public function show(dialogType:Class, args:Array = null, isForce:Boolean = false):Dialog
		{
			log.log(Channel.SCREEN, this, "-[DLG](show) dialogType:", dialogType, "args:", args, "currentScreen:", _currentScreen);
			if (_currentScreen && _currentScreen.componentType == dialogType)
			{
				log.info(Channel.SCREEN, this, "-[DLG] (show) <return-currentScreen>", "currentScreen-type:", _currentScreen.componentType);
				return _currentScreen;
			}
			
			if (_currentScreen)
			{
				log.log(Channel.SCREEN, this, "-[DLG] (show) <hide-current> prev-nextScreenObject:", 
					nextScreenObject ? nextScreenObject.dialogType + " " + nextScreenObject.args : "-");
				
				nextScreenObject = {dialogType: dialogType, args: args};
				hide(_currentScreen);
				return null;
			}

			_currentScreen = super.show(dialogType, args);// as Screen;
			return _currentScreen;
		}

		//override public function hide(dialog:*, isForce:Boolean = false):Dialog
		//{
		//	return super.hide(dialog, isForce);
		//}

		override protected function createDialogComponent(dialogType:Class):Dialog
		{
			var dialog:Dialog = super.createDialogComponent(dialogType);

			var screen:Dialog = dialog as Dialog;//var screen:Screen = dialog as Screen;//
			if (!screen && dialog)
			{
				log.warn(Channel.SCREEN, "Component of type '" + dialogType + "' is not screen! " +
					"dialog:", dialog, "screen:", screen);
			}

			return screen;
		}

		// Event handlers

//		override protected function dialog_loadStartHandler(event:Event):void
//		{
//			super.dialog_loadStartHandler(event);
//		}
//
//		override protected function dialog_loadCompleteHandler(event:Event):void
//		{
//			super.dialog_loadCompleteHandler(event);
//		}

		override protected function dialog_showStartHandler(event:Event):void
		{
			// Hide previous screen at all when next screen is ready and starts showing
			log.info(Channel.SCREEN, this, "-[DLG](dialog_showStartHandler) <previousScreen.doHidden> dialog:", event.data,"previousScreen:",previousScreen);
			if (previousScreen)
			{
				previousScreen.doHidden();
			}
			
			super.dialog_showStartHandler(event);
		}

//		override protected function dialog_showCompleteHandler(event:Event):void
//		{
//			super.dialog_showCompleteHandler(event);
//		}
//
//		override protected function dialog_hideStartHandler(event:Event):void
//		{
//			super.dialog_hideStartHandler(event);
//		}

		override protected function dialog_hideCompleteHandler(event:Event):void
		{
			super.dialog_hideCompleteHandler(event);

			// Show next screen when hiding animation of previous one 
			// was played and it is ready to be hidden at all
			var screen:Dialog = event.data as Dialog;//var screen:Screen = event.data as Screen;//
			log.info(Channel.SCREEN, this, "-[DLG](dialog_hideCompleteHandler) dialog:", event.data, "screen:", screen, 
				"currentScreen:", _currentScreen,"==>",screen == _currentScreen, "nextScreenObject:", nextScreenObject);
			if (screen == _currentScreen && nextScreenObject)
			{
				previousScreen = _currentScreen;
				_currentScreen = doShow(nextScreenObject.dialogType, nextScreenObject.args);// as Screen;
				nextScreenObject = null;
			}
		}

	}
}
