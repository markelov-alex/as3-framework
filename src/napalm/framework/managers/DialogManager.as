package napalm.framework.managers
{
	import flash.geom.Point;
	
	import napalm.framework.dialog.Dialog;
	import napalm.framework.dialog.DialogConstants;
	import napalm.framework.dialog.DialogContainer;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.ArrayUtil;
	import napalm.framework.utils.ObjectUtil;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.events.Event;
	
	[Event(name="stackStart", type="starling.events.Event")]
	[Event(name="stackComplete", type="starling.events.Event")]
	[Event(name="loadStart", type="starling.events.Event")]
	[Event(name="loadComplete", type="starling.events.Event")]
	[Event(name="showStart", type="starling.events.Event")]
	[Event(name="showComplete", type="starling.events.Event")]
	[Event(name="hideStart", type="starling.events.Event")]
	[Event(name="hideComplete", type="starling.events.Event")]
	
	/**
	 * DialogManager.
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class DialogManager extends BaseManager
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods

		public static function animateShowByTween(skinObject:Object, onShowComplete:Function, resizeManager:ResizeManager,
												  showTweenDirection:Point, showTweenTimeSec:Number = 0.5, 
												  showTweenTransition:String = Transitions.EASE_IN_OUT_BACK, log:Log = null):void
		{
			log ||= Log.instance;
			log.info(Channel.DIALOG, "--[DLG](animateShowByTween)",
					"showTweenTimeSec:", showTweenTimeSec, "showTweenTransition:", showTweenTransition);
			var tween:Tween = new Tween(skinObject, showTweenTimeSec, showTweenTransition);
			if (showTweenDirection.x)
			{
				var destinationX:int = skinObject.x;
				skinObject.x = (showTweenDirection.x > 0 ? 1 : -1) * -resizeManager.appWidth;
				tween.animate("x", destinationX);
			}
			if (showTweenDirection.y)
			{
				var destinationY:int = skinObject.y;
				skinObject.y = (showTweenDirection.y > 0 ? 1 : -1) * -resizeManager.appHeight;
				tween.animate("y", destinationY);
			}
			tween.onComplete = onShowComplete;
			Starling.juggler.add(tween);
		}

		public static function animateHideByTween(skinObject:Object, onHideComplete:Function, resizeManager:ResizeManager,
												  hideTweenDirection:Point, hideTweenTimeSec:Number = 0.5,
												  hideTweenTransition:String = Transitions.EASE_IN_OUT_BACK, log:Log = null):void
		{
			log ||= Log.instance;
			log.info(Channel.DIALOG, "--[DLG](animateHideByTween)",
					"hideTweenTimeSec:", hideTweenTimeSec, "hideTweenTransition:", hideTweenTransition);

			var tween:Tween = new Tween(skinObject, hideTweenTimeSec, hideTweenTransition);
			if (hideTweenDirection.x)
			{
				tween.animate("x", hideTweenDirection.x > 0 ? resizeManager.appWidth + skinObject.width : - skinObject.width);
			}
			if (hideTweenDirection.y)
			{
				tween.animate("y", hideTweenDirection.y > 0 ? resizeManager.appHeight + skinObject.height : - skinObject.height);
			}
			tween.onComplete = onHideComplete;
			Starling.juggler.add(tween);
		}
		
		// Variables

		// (Set in your overridden Main.initializeManagers)
		public var loadingDialogType:Class;
		
		// For defaultShow/HideTweenAnimation
		public var defaultAnimateShowByTweenFun:Function = defaultAnimateShowByTween;
		public var defaultAnimateHideByTweenFun:Function = defaultAnimateHideByTween;
		public var showTweenDirection:Point = new Point(0, 1);
		public var hideTweenDirection:Point = new Point(0, -1);
		public var showTweenTimeSec:Number = 0.5;
		public var hideTweenTimeSec:Number = 0.5;
		public var showTweenTransition:String = Transitions.EASE_IN_OUT_BACK;
		public var hideTweenTransition:String = Transitions.EASE_IN_OUT_BACK;
		
		//private var componentManager:ComponentManager;
		private var dialogContainer:DialogContainer;
		
		// Current dialogs
		private var dialogArrayByDisplayLevel:Array = [];
		
		// Queue
		private var dialogTypeQueue:Array = [];
		private var dialogObjectQueue:Array = [];
		
		// Counts
		private var loadingDialogCount:int = 0;
		private var displayingDialogCount:int = 0;
		
		// Properties
		
		private var _currentDialog:Dialog;
		public function get currentDialog():Dialog
		{
			return _currentDialog;
		}

		private var _previousDialog:Dialog;
//		public function get previousDialog():Dialog
//		{
//			return _previousDialog;
//		}

		private var _showedDialogTypeArray:Array = [];
		public function get showedDialogTypeArray():Array
		{
			return _showedDialogTypeArray;
		}
		
		// Constructor
		
		public function DialogManager()
		{
		}
		
		// Methods
		
		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);

			log.log(Channel.DIALOG, this, "[DLG](initialize) dialogContainer:",dialogContainer);
			
			var componentManager:ComponentManager = systemManager.componentManager;
			
			dialogContainer = componentManager.createComponent(DialogContainer) as DialogContainer;
			dialogContainer.initialize([systemManager]);
			dialogContainer.containerFl = systemManager.dialogsLayerFl;
			dialogContainer.skinObject = systemManager.dialogsLayer;
			
			// Listeners
			dialogContainer.addEventListener(DialogConstants.LOAD_START, dialogContainer_loadStartHandler);
			dialogContainer.addEventListener(DialogConstants.LOAD_COMPLETE, dialogContainer_loadCompleteHandler);
			dialogContainer.addEventListener(DialogConstants.SHOW_START, dialogContainer_showStartHandler);
			dialogContainer.addEventListener(DialogConstants.SHOW_COMPLETE, dialogContainer_showCompleteHandler);
			dialogContainer.addEventListener(DialogConstants.HIDE_START, dialogContainer_hideStartHandler);
			dialogContainer.addEventListener(DialogConstants.HIDE_COMPLETE, dialogContainer_hideCompleteHandler);
		}
		
		override public function dispose():void
		{
			log.log(Channel.DIALOG, this, "[DLG](dispose) dialogContainer:",dialogContainer,
					"loadingDialogCount,displayingDialogCount:",loadingDialogCount,displayingDialogCount);

			// Listeners
			dialogContainer.removeEventListener(DialogConstants.LOAD_START, dialogContainer_loadStartHandler);
			dialogContainer.removeEventListener(DialogConstants.LOAD_COMPLETE, dialogContainer_loadCompleteHandler);
			dialogContainer.removeEventListener(DialogConstants.SHOW_START, dialogContainer_showStartHandler);
			dialogContainer.removeEventListener(DialogConstants.SHOW_COMPLETE, dialogContainer_showCompleteHandler);
			dialogContainer.removeEventListener(DialogConstants.HIDE_START, dialogContainer_hideStartHandler);
			dialogContainer.removeEventListener(DialogConstants.HIDE_COMPLETE, dialogContainer_hideCompleteHandler);
			
//			dialogClassArray = [];

			dialogContainer.dispose();
			
			//componentManager = null;
			dialogContainer = null;
			_currentDialog = null;
			_previousDialog = null;

			loadingDialogCount = 0;
			displayingDialogCount = 0;
			
			super.dispose();
		}
		
		public function show(dialogType:Class, args:Array = null):Dialog
		{
			log.log(Channel.DIALOG, "[NXT]  -SHOW-DIAChannel.DIALOG-", dialogType);
			log.log(Channel.DIALOG, this, "[DLG][NXT](SHOW) dialogType:", dialogType, "args:",args, 
					"showedDialogTypeArray:", _showedDialogTypeArray);
			if (!dialogType || _showedDialogTypeArray.indexOf(dialogType) != -1)
			{
				return null;
			}
			
			var displayLevel:int = dialogContainer.getDisplayLevelByDialogType(dialogType);
			if (displayLevel < 0)
			{
				log.warn(Channel.DIALOG, this, "[DLG] (show) <return> displayLevel<0 displayLevel:", displayLevel, 
						"dialogType:",dialogType);
				return null;
			}
			
			// Check is some showed on this displayLevel
			var dialogArray:Array = dialogArrayByDisplayLevel[displayLevel] as Array;
			var isDisplayLevelEmpty:Boolean = !dialogArray || !dialogArray.length;
			var isTopperDialogDisplayed:Boolean = _currentDialog && _currentDialog.displayLevel >= displayLevel;
			if (!isDisplayLevelEmpty || isTopperDialogDisplayed)
			{
				log.info(Channel.DIALOG, this, "[DLG]  (show) <enqueueAsLast>", isDisplayLevelEmpty, 
						"||", isTopperDialogDisplayed, "dialogType:", dialogType,"displayLevel:", displayLevel, 
						"-> dialogArray:", dialogArray, "currentDialog:", _currentDialog, 
						".displayLevel:", _currentDialog && _currentDialog.displayLevel);
				// Note: will do nothing if such dialogType is already added to queue
				enqueueAsLast(dialogType, args);
			}
			else
			{
				log.info(Channel.DIALOG, this, "[DLG]  (show) <dialogContainer.show> prev-previousDialog:", 
						_previousDialog, "prev-currentDialog:", _currentDialog,"displayLevel:", displayLevel, 
						"dialogType:", dialogType, "prev-showedDialogTypeArray:", _showedDialogTypeArray);
				var newDialog:Dialog = dialogContainer.show(dialogType, args);
				log.info(Channel.DIALOG, this, "[DLG][NXT]   (show) newDialog:",newDialog);
				
				if (newDialog)
				{
					// Add
					_showedDialogTypeArray[_showedDialogTypeArray.length] = dialogType;
					if (!dialogArray)
					{
						dialogArray = [];
						dialogArrayByDisplayLevel[displayLevel] = dialogArray;
					}
					dialogArray[dialogArray.length] = newDialog;
					log.log(Channel.DIALOG, this, "[DLG]    (show) added <updateCurrentDialog>", 
							"displayLevel:", displayLevel, "-> dialogArray:", dialogArray, 
							"showedDialogTypeArray:", _showedDialogTypeArray);
					
					// currentDialog
					updateCurrentDialog();
					
					return newDialog;
				}
				else
				{
					return checkNextFromQueue();
				}
			}
			
			return null;
		}
		
		/**
		 *
		 * @param dialog (Class|Dialog)
		 */
		public function hide(dialog:*, isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "[DLG](HIDE) dialog:", dialog, "isForce:", isForce);
			dialogContainer.hide(dialog, isForce);
		}

		public function hideAll(isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "TODO  [DLG](HIDE-ALL)", "isForce:", isForce);
			for each (var showedDialogType:Class in _showedDialogTypeArray)
			{
				hide(showedDialogType);
			}
		}

		public function enqueueAsLast(dialogType:Class, args:Array = null):void
		{
			log.log(Channel.DIALOG, this, "[DLG](enqueueAsLast) dialogType:", dialogType, "args:", args, 
					"dialogTypeQueue:", dialogTypeQueue);
			if (!dialogType)
			{
				return;
			}
			
			// Check in queue
			if (dialogTypeQueue.indexOf(dialogType) != -1)
			{
				log.warn(Channel.DIALOG, this, "[DLG] (enqueueAsLast) <return> Already in queue! " +
						"dialogType:", dialogType);
				return;
			}
			
			log.log(Channel.DIALOG, this, "[DLG] (enqueueAsLast) enqueue to the end of queue dialogType:", dialogType, 
					"args:", args, "before-queue_length:", dialogTypeQueue.length);
			
			// Add
			var dialogObject:Object = {dialogType: dialogType, args: args};
			dialogTypeQueue[dialogTypeQueue.length] = dialogType;
			dialogObjectQueue[dialogObjectQueue.length] = dialogObject;
		}

		public function stackAsFirst(dialogType:Class, args:Array = null):void
		{
			log.log(Channel.DIALOG, this, "[DLG](stackAsFirst) dialogType:", dialogType, 
					"args:", args, "dialogTypeQueue:", dialogTypeQueue);
			if (!dialogType)
			{
				return;
			}
			
			var dialogObject:Object;
			// Check in queue
			if (dialogTypeQueue.indexOf(dialogType) != -1)
			{
				// Remove
				ArrayUtil.removeItem(dialogTypeQueue, dialogType);
				dialogObject = ArrayUtil.removeItemByProperty(dialogObjectQueue, "dialogType", dialogType);
				log.log(Channel.DIALOG, this, "[DLG] (stackAsFirst) replace to the beginning of queue dialogType:",
						dialogObject.dialogType,"args:",dialogObject.args,"before-queue_length:",dialogTypeQueue.length);
			}
			else
			{
				// Create
				dialogObject = {"dialogType": dialogType, "args": args};
				log.log(Channel.DIALOG, this, "[DLG] (stackAsFirst) enqueue to the beginning of queue dialogType:",
						dialogObject.dialogType,"args:",dialogObject.args,"before-queue_length:",dialogTypeQueue.length);
			}

			// Add
			dialogTypeQueue.unshift(dialogType);
			dialogObjectQueue.unshift(dialogObject);
			log.info(Channel.DIALOG, this, "[DLG]  (stackAsFirst) dialogObjectQueue.length:", dialogObjectQueue.length, 
					"dialogObjectQueue:", ObjectUtil.stringify(dialogObjectQueue));
		}

		public function checkInQueue(dialogType:Class):Boolean
		{
			return dialogTypeQueue.indexOf(dialogType) != -1;
		}

		public function checkShowing(dialogType:Class):Boolean
		{
			return dialogTypeQueue.indexOf(dialogType) != -1 || _showedDialogTypeArray.indexOf(dialogType) != -1;
		}

		private function checkNextFromQueue():Dialog
		{
			log.log(Channel.DIALOG, this, "[DLG][NXT](checkNextFromQueue)", "currentDialog:", _currentDialog, 
					"dialogObjectQueue.length:", dialogObjectQueue.length);
			if (!_currentDialog && dialogObjectQueue.length > 0)
			{
				// Remove from queue
				var dialogObject:Object = dialogObjectQueue.shift();
				var dialogType:Class = dialogObject.dialogType;
				var args:Array = dialogObject.args;
				ArrayUtil.removeItem(dialogTypeQueue, dialogType);

				// Show
				log.log(Channel.DIALOG, this, "[DLG][NXT] (checkNextFromQueue) <show> dialogObjectQueue.length:",
						dialogObjectQueue.length, "dialogType:", dialogType, "args:",args);
				return show(dialogType, args);
			}
			
			return null;
		}

		private function updateCurrentDialog():void
		{
			// Find the first dialog with the highest displayLevel
			var topDialog:Dialog = null;
			for (var displayLevel:int = dialogArrayByDisplayLevel.length - 1; displayLevel >= 0; displayLevel--)
			{
				var dialogArray:Array = dialogArrayByDisplayLevel[displayLevel];
				if (dialogArray && dialogArray.length)
				{
					topDialog = dialogArray[dialogArray.length - 1] as Dialog;
					if (topDialog)
					{
						break;
					}
				}
			}

			// Check DIAChannel.DIALOGS_START
			var wasAnyCurrentDialog:Boolean = _currentDialog != null;
			if (!wasAnyCurrentDialog && topDialog)
			{
				log.log(Channel.DIALOG, this, "[DLG] (updateCurrentDialog) <dialog_dispatch-DIAChannel.DIALOGS_START>", "wasAnyCurrentDialog(f):", 
						wasAnyCurrentDialog, "topDialog:", topDialog, "currentDialog(null):",_currentDialog);
				// Dispatch
				dispatchEventWith(DialogConstants.DIALOGS_START);
			}

			// Set dialog with the highest displayLevel as current
			if (topDialog != _currentDialog)
			{
				_previousDialog = _currentDialog;
				_currentDialog = topDialog;
				log.log(Channel.DIALOG, this, "[DLG][NXT]  (updateCurrentDialog) currentDialog:",_currentDialog, "previousDialog:", _previousDialog);
			}

			// Check DIAChannel.DIALOGS_COMPLETE
			if (wasAnyCurrentDialog && !_currentDialog)
			{
				log.log(Channel.DIALOG, this, "[DLG]   (updateCurrentDialog) <dialog_dispatch-DIAChannel.DIALOGS_COMPLETE> wasAnyCurrentDialog(t):", 
						wasAnyCurrentDialog, "currentDialog(null):",_currentDialog);
				// Dispatch
				dispatchEventWith(DialogConstants.DIALOGS_COMPLETE);
			}
		}

		private function defaultAnimateShowByTween(skinObject:Object, onShowComplete:Function):void
		{
			log.info(Channel.DIALOG, this, "--[DLG](defaultAnimateShowByTween)",
					"showTweenTimeSec:", showTweenTimeSec, "showTweenTransition:", showTweenTransition);

			var resizeManager:ResizeManager = systemManager.resizeManager;
			animateShowByTween(skinObject, onShowComplete, resizeManager, showTweenDirection, showTweenTimeSec, showTweenTransition, log);
		}

		private function defaultAnimateHideByTween(skinObject:Object, onHideComplete:Function):void
		{
			log.info(Channel.DIALOG, this, "--[DLG](defaultAnimateHideByTween)",
					"hideTweenTimeSec:", hideTweenTimeSec, "hideTweenTransition:", hideTweenTransition);

			var resizeManager:ResizeManager = systemManager.resizeManager;
			animateHideByTween(skinObject, onHideComplete, resizeManager, hideTweenDirection, hideTweenTimeSec, hideTweenTransition, log);
		}
		
		// Event handlers
		
		private function dialogContainer_loadStartHandler(event:Event):void
		{
			loadingDialogCount++;
			log.info(Channel.DIALOG, this, "[DLG](dialogContainer_loadStartHandler) <show-loadingdialog?> " +
					"loadingDialogType:", loadingDialogType, "loadingDialogCount(1):", loadingDialogCount);
			if (loadingDialogType && loadingDialogCount == 1)
			{
				show(loadingDialogType);
			}

			// Redispatch
			dispatchEvent(event);
		}
		
		private function dialogContainer_loadCompleteHandler(event:Event):void
		{
			loadingDialogCount--;
			log.info(Channel.DIALOG, this, "[DLG](dialogContainer_loadCompleteHandler) <hide-loadingdialog?> " +
					"loadingDialogType:", loadingDialogType, "loadingDialogCount(0):", loadingDialogCount);
			if (loadingDialogType && loadingDialogCount == 0)
			{
				hide(loadingDialogType);
			}

			// Redispatch
			dispatchEvent(event);
		}
		
		private function dialogContainer_showStartHandler(event:Event):void
		{
			displayingDialogCount++;
			log.info(Channel.DIALOG, this, "[DLG](dialogContainer_showStartHandler) " +
					"displayingDialogCount:",displayingDialogCount);
			
			// Redispatch
			dispatchEvent(event);
		}
		
		private function dialogContainer_showCompleteHandler(event:Event):void
		{
			log.info(Channel.DIALOG, this, "[DLG](dialogContainer_showCompleteHandler)");
			
			// Redispatch
			dispatchEvent(event);
		}
		
		private function dialogContainer_hideStartHandler(event:Event):void
		{
			log.info(Channel.DIALOG, this, "[DLG](dialogContainer_hideStartHandler)");
			
			// Redispatch
			dispatchEvent(event);
		}
		
		private function dialogContainer_hideCompleteHandler(event:Event):void
		{
			var dialog:Dialog = event.data as Dialog;
			
			// Remove
			if (dialog)
			{
				var dialogArray:Array = dialogArrayByDisplayLevel[dialog.displayLevel] as Array;
				ArrayUtil.removeItem(dialogArray, dialog);
				ArrayUtil.removeItem(_showedDialogTypeArray, dialog.componentType);
			}

			displayingDialogCount--;
			log.info(Channel.DIALOG, this, "[DLG][NXT](dialogContainer_hideCompleteHandler) <checkNextFromQueue>", 
					"displayingDialogCount:", displayingDialogCount, "dialog:", dialog, "prev-currentDialog:", _currentDialog, 
					"displayLevel:", dialog.displayLevel, "-> dialogArray:", dialogArray, 
					"showedDialogTypeArray:", _showedDialogTypeArray);

			// currentDialog
			updateCurrentDialog();
			
			checkNextFromQueue();
			
			// Redispatch
			dispatchEvent(event);
		}
		
	}
}
