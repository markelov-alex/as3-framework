package napalm.framework.dialog
{
	import napalm.framework.log.Channel;
	
	import starling.events.Event;
	
	/**
	 * Screen.
	 * 
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class Screen extends Dialog
	{

		// Class constants
		// Class variables
		// Class methods

		// In subclasses (for convenience):
		//public static function show(myparam:Boolean, myparam2:Number):void
		//{
		//	SystemManager.getInstance.screenManager.show(MyDialog, [myparam, myparam2]);
		//}
		//public static function hide(isForce:Boolean):void
		//{
		//	SystemManager.getInstance.screenManager.hide(MyScreen, isForce);
		//}

		// Variables

		public var preloaderDialogType:Class;
		
		private var preloaderDialog:Dialog;
		
		private var isScreenShown:Boolean = false;
		
		// Properties

		override public final function get isModal():Boolean
		{
			return false;
		}

		override public function get displayLevel():int
		{
			return -1;
		}

		override protected function get isHideOnHideComplete():Boolean
		{
			return false;
		}

		// Constructor

		public function Screen()
		{
			// Screens are fluid by default
			//?isFluidScaleMode = true;
			
			// Default show/hide tweens disabled because screens 
			// are showing in other way than dialogs
			isShowTweenEnabled = false;
			isHideTweenEnabled = false;
		}

		// Methods

		override public function initialize(args:Array = null):void
		{
			super.initialize(args);
			
			if (preloaderDialogType)
			{
				// Listeners
				addEventListener(DialogConstants.LOAD_START, loadStartHandler);
			}
		}

		override public function dispose():void
		{
			// Listeners
			removeEventListener(DialogConstants.LOAD_START, loadStartHandler);
			
			super.dispose();
		}

		override public function hide(isForce:Boolean = false):void
		{
			screenManager.hide(this, isForce);
		}
		
		// (All below: Processing preloader)
		
		override protected function onLoadComplete():void
		{
			checkLoadedAndPreloaderShown();
		}

		override protected function onShowComplete():void
		{
			super.onShowComplete();
			
			isScreenShown = true;
			checkShownAndPreloaderHidden();
		}

		override protected function hideStart():void
		{
			isScreenShown = false;
			
			super.hideStart();
		}

		override protected function onHideComplete():void
		{
			isScreenShown = false;

			super.onHideComplete();
		}

		private function checkLoadedAndPreloaderShown():void
		{
			if (isLoaded && (!preloaderDialog || preloaderDialog.isShown))
			{
				super.onLoadComplete();
				
				// Hide preloader
				if (preloaderDialogType)
				{
					dialogManager.hide(preloaderDialogType);
				}
			}
		}

		private function checkShownAndPreloaderHidden():void
		{
			if (isScreenShown && (!preloaderDialog || (!preloaderDialog.isShown && !preloaderDialog.isHiding)))
			{
				super.onShowComplete();

				if (preloaderDialog)
				{
					// Listeners
					preloaderDialog.removeEventListener(DialogConstants.SHOW_COMPLETE, preloaderDialog_showCompleteHandler);
					preloaderDialog.removeEventListener(DialogConstants.HIDE_COMPLETE, preloaderDialog_hideCompleteHandler);

					preloaderDialog = null;
				}
			}
		}

		// Event handlers

		private function loadStartHandler(event:Event):void
		{
			if (!preloaderDialogType)
			{
				return;
			}
			
			// Show preloader
			preloaderDialog = dialogManager.show(preloaderDialogType);
			if (!preloaderDialog)
			{
				log.error(Channel.SCREEN, this, "(loadStartHandler) Error! PreloaderDialog cannot be null! " +
					"May be it was enqueued to be shown later. In this case set higher displayLevel " +
					"in this preloader class. preloaderDialogType:", preloaderDialogType);
				return;
			}
			
			// Listeners
			preloaderDialog.addEventListener(DialogConstants.SHOW_COMPLETE, preloaderDialog_showCompleteHandler);
			preloaderDialog.addEventListener(DialogConstants.HIDE_COMPLETE, preloaderDialog_hideCompleteHandler);
		}

		private function preloaderDialog_showCompleteHandler(event:Event):void
		{
			checkLoadedAndPreloaderShown();
		}

		private function preloaderDialog_hideCompleteHandler(event:Event):void
		{
			checkShownAndPreloaderHidden();
		}
		
	}
}
