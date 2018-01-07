package napalm.framework.dialog
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import napalm.framework.component.Container;
	import napalm.framework.dialog.flash.FDialog;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.ResizeManager;
	import napalm.framework.utils.DisplayUtil;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	
	//type="napalm.framework.dialog.DialogConstants"
	[Event(name="loadStart", type="starling.events.Event")]
	[Event(name="loadComplete", type="starling.events.Event")]
	[Event(name="showStart", type="starling.events.Event")]
	[Event(name="showComplete", type="starling.events.Event")]
	[Event(name="hideStart", type="starling.events.Event")]
	[Event(name="hideComplete", type="starling.events.Event")]
	
	/**
	 * DialogContainer.
	 * 
	 * Note: You can override DialogContainer like any other component 
	 * in your overridden Main.initializeManagers():
	 * 	componentManager.registerComponentType(DialogContainer, MyCustomDialogContainer);
	 * @author alex.panoptik@gmail.com
	 */
	public class DialogContainer extends Container
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables
		
		public var showModalTimeSec:Number = 0.3;
		public var hideModalTimeSec:Number = 0.05;

		private var isDialogShowing:Boolean = false;
		private var isDialogHiding:Boolean = false;
		
		private var layerArray:Array = [];
		private var layerFlArray:Array = [];
		private var dialogByTypeLookup:Dictionary = new Dictionary();
		
		private var displayLevelByDialogTypeLookup:Dictionary = new Dictionary();

		// Modal
		protected var modalSprite:starling.display.Sprite;
		protected var modalSpriteFl:flash.display.Sprite;
		private var isModalVisible:Boolean = false;
		private var isModalFlVisible:Boolean = false;
		private var modalTween:Tween;
		private var modalFlTween:Tween;
		
		private var containerToDisableWhenModal:starling.display.Sprite;
		private var containerToDisableWhenModalFl:flash.display.Sprite;
		
		// Properties

		// skinObject for Starling, and containerFl for Flash
		private var _containerFl:flash.display.Sprite;
		public function get containerFl():flash.display.Sprite
		{
			return _containerFl;
		}
		public function set containerFl(value:flash.display.Sprite):void
		{
			if (_containerFl === value)
			{
				return;
			}
			
			_containerFl = value;
		}

		// Constructor

		public function DialogContainer()
		{
			//trace(Channel.DIALOG, this, "-(constructor)");
		}

		// Methods

		override public function initialize(args:Array = null):void
		{
			super.initialize(args);
			log.info(Channel.DIALOG, this, "-(initialize) args:", args);

			resizeManager = systemManager.resizeManager;
		}

		override public function dispose():void
		{
			log.info(Channel.DIALOG, this, "-(dispose) displayContainer:", displayContainer);
			displayContainer.removeChildren();
			
			while (_containerFl && _containerFl.numChildren)
			{
				_containerFl.removeChildAt(0);
			}

			for (var i:int = 0; i < children.length; i++)
			{
				var dialog:Dialog = children[i];
				removeDialogEventListeners(dialog);
			}

			layerArray = [];
			layerFlArray = [];

			dialogByTypeLookup = new Dictionary();
			displayLevelByDialogTypeLookup = new Dictionary();
			
			super.dispose();

			resizeManager = null;
		}

		override protected function attachSkin():void
		{
			log.info(Channel.DIALOG, this, "-(attachSkin) <createModalSprites;onAppResize> skinObject:", skinObject);
			super.attachSkin();

			containerToDisableWhenModal = systemManager.screensLayer != skinObject ? systemManager.screensLayer : null;
			containerToDisableWhenModalFl = systemManager.screensLayerFl != containerFl ? systemManager.screensLayerFl : null;
			
			createModalSprites();
			
			onAppResize();

			// Listeners
			resizeManager.addEventListener(ResizeManager.RESIZE, onAppResize);
		}

		override protected function detachSkin():void
		{
			log.log(Channel.DIALOG, this, "-(detachSkin) skinObject:", skinObject);
			
			// Listeners
			resizeManager.removeEventListener(ResizeManager.RESIZE, onAppResize);

			if (modalSprite)
			{
				modalSprite.removeFromParent(true);
				modalSprite = null;
			}
			if (modalSpriteFl)
			{
				modalSpriteFl.parent.removeChild(modalSpriteFl);
				modalSpriteFl = null;
			}
			modalTween = null;
			modalFlTween = null;

			containerToDisableWhenModal = null;
			containerToDisableWhenModalFl = null;

			super.detachSkin();
		}

		public function show(dialogType:Class, args:Array = null, isForce:Boolean = false):Dialog
		{
			log.log(Channel.DIALOG, this, "-[DLG](show) <doShow> dialogType:", dialogType, "args:", args, "isForce:", isForce);
			
			var newDialog:Dialog;
			try
			{
				newDialog = doShow(dialogType, args, isForce)
			}
			catch (error:Error)
			{
				log.fatal(Channel.DIALOG, "Error while showing dialog!", "dialogType:", dialogType, "args:", args, "error:", error, error.getStackTrace());
			}
			
			return newDialog;
		}

		protected function doShow(dialogType:Class, args:Array = null, isForce:Boolean = false):Dialog
		{
			log.log(Channel.DIALOG, this, "-[DLG](doShow) <create-dialog?> dialogType:",dialogType, "args:", args, 
				"isDialogShowing:", isDialogShowing, "isDialogHiding:", isDialogHiding);
			if (!dialogType)// || isDialogShowing || isDialogHiding//for loadingdialog...
			{
				log.warn(Channel.DIALOG, this, "-[DLG] (doShow) <return null> dialogType, isDialogShowing, isDialogHiding:", 
					dialogType, isDialogShowing, isDialogHiding);
				return null;
			}
			
			// Get
			var dialog:Dialog = dialogByTypeLookup[dialogType] as Dialog;
			if (!dialog)
			{
				// Create
				dialog = createDialogComponent(dialogType);
				// Register
				dialogByTypeLookup[dialogType] = dialog;
			}
			
			if (!dialog)// || !dialog.displayObject)
			{
				log.warn(Channel.DIALOG, this, "-[DLG] (doShow) <return null> dialog:",dialog);//,dialog.displayObject:", dialog,dialog.displayObject);
				return null;
			}

			log.log(Channel.DIALOG, this, "-[DLG] (doShow) <add-dialog;dialog.doShow> dialog:", dialog);
			// Add to children
			addChild(dialog);
			addDialogEventListeners(dialog);
			// Listeners
			//?dialog.addEventListener(DialogConstants.DISPOSE, dialog_disposeHandler);

			// Do show (start showing)
			isDialogShowing = true;
			dialog.doShow(args, isForce);

			//+?onAppResize();

			return dialog;
		}
		
		/**
		 * 
		 * @param dialog (Class|Dialog)
		 */
		public function hide(dialog:*, isForce:Boolean = false):Dialog
		{
			log.log(Channel.DIALOG, this, "-[DLG](hide) dialog:", dialog, "isForce:", isForce,
				"isDialogShowing:", isDialogShowing, "isDialogHiding:", isDialogHiding);
			if (!dialog)
			{
				log.log(Channel.DIALOG, this, "-[DLG] (hide) <return> dialog:", dialog);
				return null;
			}
//			if (!isForce && (isDialogShowing || isDialogHiding))////for loadingdialog
//			{
//				log.log(Channel.DIALOG, this, "-[DLG] (hide) <return> isDialogShowing,isDialogHiding (f,f):", isDialogShowing, isDialogHiding);
//				return null;
//			}

			var dialogInst:Dialog = dialog as Dialog || dialogByTypeLookup[dialog] as Dialog;
			if (!dialogInst)
			{
				log.log(Channel.DIALOG, this, "-[DLG] (hide) <return> dialogInst:",dialogInst,"dialog:", dialog);
				return null;
			}
			
			log.log(Channel.DIALOG, this, "-[DLG] (hide) <dialog.doHide> dialogInst:", dialogInst, "dialog:", dialog);
			// Do hide (start hiding)
			isDialogHiding = true;
			dialogInst.doHide(isForce);
			return dialogInst;
		}

		public function getDisplayLevelByDialogType(dialogType:Class):int
		{
			if (displayLevelByDialogTypeLookup[dialogType] != undefined)
			{
				return displayLevelByDialogTypeLookup[dialogType];
			}
			var dialogInst:Dialog = componentManager.createComponent(dialogType) as Dialog;
			var displayLevel:int = dialogInst ? dialogInst.displayLevel : -1;
			displayLevelByDialogTypeLookup[dialogType] = displayLevel;
			return displayLevel;
		}

		protected function createDialogComponent(dialogType:Class):Dialog
		{
			var dialog:Dialog = componentManager.createComponent(dialogType) as Dialog;
			var isFlashLayer:Boolean = dialog is FDialog;
			var layer:Object = getLayer(dialog.displayLevel, isFlashLayer);
			log.info(Channel.DIALOG, this, "-[DLG](createDialogComponent) dialogType,dialog:",dialogType, dialog, "layer:", layer);
			dialog.initialize([systemManager, null, layer]);
			return dialog;
		}
		
		private function getLayer(displayLevel:int, isFlashLayer:Boolean = false):Object
		{
			var layerArray:Array = isFlashLayer ? this.layerFlArray : this.layerArray;
			displayLevel = Math.max(displayLevel, 0);
			// Check if exists
			if (layerArray[displayLevel])
			{
				return layerArray[displayLevel];
			}
			
			// Create all layers up to displayLevel
			var layerClass:Class = isFlashLayer ? flash.display.Sprite : starling.display.Sprite;
			for (var i:int = 0; i <= displayLevel; i++)
			{
				if (!layerArray[i])
				{
					var layer:Object = new layerClass();
					log.info(Channel.DIALOG, this, "-[DLG](getLayer) <create-layer> displayLevel,i:", displayLevel,i, "layer:", layer);
					layerArray[i] = layer;
					
					if (isFlashLayer)
					{
						containerFl.addChild(layer as flash.display.Sprite);
					}
					else
					{
						displayContainer.addChild(layer as starling.display.Sprite);
					}
				}
			}
			return layerArray[displayLevel];
		}
		
		private function addDialogEventListeners(dialog:Dialog):void
		{
			if (dialog)
			{
				//log.info(Channel.DIALOG, this, "-[DLG](addDialogEventListeners) dialog:", dialog);
				// Listeners
				dialog.addEventListener(DialogConstants.LOAD_START, dialog_loadStartHandler);
				dialog.addEventListener(DialogConstants.LOAD_COMPLETE, dialog_loadCompleteHandler);
				dialog.addEventListener(DialogConstants.SHOW_START, dialog_showStartHandler);
				dialog.addEventListener(DialogConstants.SHOW_COMPLETE, dialog_showCompleteHandler);
				dialog.addEventListener(DialogConstants.HIDE_START, dialog_hideStartHandler);
				dialog.addEventListener(DialogConstants.HIDE_COMPLETE, dialog_hideCompleteHandler);
			}
		}
		
		private function removeDialogEventListeners(dialog:Dialog):void
		{
			if (dialog)
			{
				//log.info(Channel.DIALOG, this, "-[DLG](removeDialogEventListeners) dialog:", dialog);
				// Listeners
				dialog.removeEventListener(DialogConstants.LOAD_START, dialog_loadStartHandler);
				dialog.removeEventListener(DialogConstants.LOAD_COMPLETE, dialog_loadCompleteHandler);
				dialog.removeEventListener(DialogConstants.SHOW_START, dialog_showStartHandler);
				dialog.removeEventListener(DialogConstants.SHOW_COMPLETE, dialog_showCompleteHandler);
				dialog.removeEventListener(DialogConstants.HIDE_START, dialog_hideStartHandler);
				dialog.removeEventListener(DialogConstants.HIDE_COMPLETE, dialog_hideCompleteHandler);
			}
		}
		
		private function createModalSprites():void
		{
			if (!modalSprite)
			{
				modalSprite = new starling.display.Sprite();
				modalSprite.visible = false;
				modalSprite.touchable = true;
				modalSprite.useHandCursor = false;
			}
			if (!modalSpriteFl)
			{
				modalSpriteFl = new flash.display.Sprite();
				modalSpriteFl.visible = false;
				modalSpriteFl.mouseEnabled = true;
				modalSpriteFl.useHandCursor = false;
			}
			log.info(Channel.DIALOG, this, "-[DLG](createModalSprites) <create-modal?> prev-modalSprite:", modalSprite, "modalSpriteFl:", modalSpriteFl);
		}
		
		private function updateModalView():void
		{
			log.log(Channel.DIALOG, this, "-[DLG](updateModalView) <create-new-modal-view> resizeManager.stageWidth/Height:", resizeManager.appWidth, resizeManager.appHeight);
			if (modalSprite)
			{
				var quad:Quad = new Quad(resizeManager.appWidth, resizeManager.appHeight);
				quad.color = 0x9c060e2d;
				quad.alpha = 0.5;
				
				modalSprite.removeChildren(0, -1, true);
				modalSprite.addChild(quad);
			}
			
			if (modalSpriteFl)
			{
				if (!modalSpriteFl.width)
				{
					DisplayUtil.drawRect(new Rectangle(0, 0, 100, 100), modalSpriteFl, 0xD3D3D3, 0, .3, 0);
				}
				modalSpriteFl.width = resizeManager.appWidth;
				modalSpriteFl.height = resizeManager.appHeight;
			}
		}
		
		//TODO! hide modal on dialog's hide start, not hide complete
		private function updateModalDisplay():void
		{
			// Find max modal level
			var maxModalDisplayLevel:int = -1;
			var maxModalDisplayLevelFl:int = -1;
			for (var i:int = 0; i < children.length; i++)
			{
				var dialog:Dialog = children[i];
				if (dialog && dialog.isModal && dialog.displayLevel > maxModalDisplayLevel)
				{
					if (dialog is FDialog)
					{
						maxModalDisplayLevelFl = dialog.displayLevel;
					}
					else
					{
						maxModalDisplayLevel = dialog.displayLevel;
					}
				}
			}
			
			// Update modalSprite
			updateModalSprite(displayContainer, modalSprite, isModalVisible, maxModalDisplayLevel);
			updateModalSprite(containerFl, modalSpriteFl, isModalFlVisible, maxModalDisplayLevelFl);

			isModalVisible = maxModalDisplayLevel >= 0;
			isModalFlVisible = maxModalDisplayLevelFl >= 0;
			
			var isShowAnyModalDialog:Boolean = maxModalDisplayLevel >= 0;
			var isShowAnyModalDialogFl:Boolean = maxModalDisplayLevel >= 0;
			if (containerToDisableWhenModal)
			{
				containerToDisableWhenModal.touchable = !isShowAnyModalDialog && !isShowAnyModalDialogFl;
			}
			if (containerToDisableWhenModalFl)
			{
				containerToDisableWhenModalFl.mouseChildren = !isShowAnyModalDialogFl;
			}
			
		//todo check modalSprite,Fl now == null
			log.log(Channel.DIALOG, this, "-[DLG](updateModalDisplay)", 
					"maxModalDisplayLevel:", maxModalDisplayLevel, "modal.visible:", modalSprite && modalSprite.visible, 
					"maxModalDisplayLevelFl:", maxModalDisplayLevelFl, "modalFl.visible:", modalSpriteFl && modalSpriteFl.visible,
					"children:", children);
			
		}

		private function updateModalSprite(container:Object, modalSprite:Object, 
		                                   isModalVisiblePrev:Boolean, maxModalDisplayLevel:int = -1):void
		{
			if (!container || !modalSprite)
			{
				return;
			}
			
			// Place modal under that layer (maxModalDisplayLevel)
			if (maxModalDisplayLevel >= 0)
			{
				var isFlashLayer:Boolean = modalSprite is DisplayObject;
				var layer:Object = getLayer(maxModalDisplayLevel, isFlashLayer);//layerArray[maxModalDisplayLevel];
				log.info(Channel.DIALOG, this, "-[DLG] (updateModalDisplay) layer.numChildren:", layer.numChildren,
						"prev-modal-index:", modalSprite.parent ? modalSprite.parent.getChildIndex(modalSprite) : "-",
						"layer-index:", container.getChildIndex(layer));
				if (layer.numChildren)
				{
					if (modalSprite.parent)
					{
						modalSprite.parent.removeChild(modalSprite);
					}
					var index:int = container.getChildIndex(layer);
					container.addChildAt(modalSprite, index);
				}
			}

			// Show/Hide modal if needed
			var isShowAnyModalDialog:Boolean = maxModalDisplayLevel >= 0;
			if (isShowAnyModalDialog != isModalVisiblePrev)
			{
				animateModal(modalSprite, isShowAnyModalDialog);
			}
		}

		private function animateModal(modalSprite:Object, isShow:Boolean):void
		{
			var modalTween:Tween = modalSprite == this.modalSprite ? modalTween : modalFlTween;
			
			// Dispose prev
			if (modalTween)
			{
				modalTween.onComplete = null;
				modalTween.advanceTime(showModalTimeSec + hideModalTimeSec);
				modalTween = null;
			}

			log.info(Channel.DIALOG, this, "-[DLG](animateModal) <tween> isShow:", isShow,"prev-modal.visible,alpha:",modalSprite.visible,modalSprite.alpha);
//-			if (Starling.juggler)
//			{
			// Prepare
			modalSprite.visible = true;
			modalSprite.alpha = isShow ? 0 : 1;
			
			// Tween
			var duration:Number = isShow ? showModalTimeSec : hideModalTimeSec;
			if (duration > 0)
			{
				modalTween = new Tween(modalSprite, duration);
				modalTween.animate("alpha", isShow ? 1 : 0);
				modalTween.onComplete = function():void
				{
					log.info(Channel.DIALOG, this, "-[DLG] (animateModal-modalTween.onComplete) isShow:", isShow,"prev-modal.visible,alpha:",modalSprite.visible,modalSprite.alpha);
					modalSprite.visible = isShow ? true : false;
					modalSprite.alpha = 1;
					modalTween = null;
				};
				
				Starling.juggler.add(modalTween);
			}
			else
			{
				modalSprite.visible = isShow ? true : false;
				modalSprite.alpha = 1;
			}
//-			}
//			else
//			{
//				modalSprite.visible = isShow ? true : false;
//				modalSprite.alpha = 1;
//			}
		}

		// Event handlers

		protected function onAppResize():void
		{
			log.log(Channel.DIALOG, this, "-[DLG](onAppResize) <updateModalView>");
			// Position
			//displayObject.x = resizeManager.appLeft;
			//displayObject.y = resizeManager.appTop;

			// Modal
			updateModalView();
		}

		protected function dialog_loadStartHandler(event:Event):void
		{
			log.info(Channel.DIALOG, this, "-[DLG](dialog_loadStartHandler) dialog:", event.data);
			
			// Redispatch
			dispatchEvent(event);
		}

		protected function dialog_loadCompleteHandler(event:Event):void
		{
			var dialog:Dialog = event.data as Dialog;

			log.info(Channel.DIALOG, this, "-[DLG](dialog_loadCompleteHandler) dialog:", dialog);
//-
//			// Add to display list
//			checkDialogReady(dialog);
			
			// Redispatch
			dispatchEvent(event);
		}

		protected function dialog_showStartHandler(event:Event):void
		{
			log.info(Channel.DIALOG, this, "-[DLG](dialog_showStartHandler) <updateModalDisplay> dialog:", event.data);

			// Modal
			updateModalDisplay();
			
			// Redispatch
			dispatchEvent(event);
		}

		protected function dialog_showCompleteHandler(event:Event):void
		{
			isDialogShowing = false;

			log.info(Channel.DIALOG, this, "-[DLG](dialog_showCompleteHandler) dialog:", event.data);

			// Redispatch
			dispatchEvent(event);
		}

		protected function dialog_hideStartHandler(event:Event):void
		{
			log.info(Channel.DIALOG, this, "-[DLG](dialog_hideStartHandler) dialog:", event.data);

			// Redispatch
			dispatchEvent(event);
		}

		protected function dialog_hideCompleteHandler(event:Event):void
		{
			var dialog:Dialog = event.data as Dialog;

			log.info(Channel.DIALOG, this, "-[DLG](dialog_hideCompleteHandler) <remove-dialog;updateModalDisplay> dialog:", dialog);

			isDialogShowing = false;
			isDialogHiding = false;
			
			// Remove from children
			removeChild(dialog);
			removeDialogEventListeners(dialog);
			
			// Redispatch
			dispatchEvent(event);

			// Modal (after dispatch!)
			updateModalDisplay();
		}

		//?protected function dialog_disposeHandler(event:Event):void
		//{
		//	var dialog:Dialog = event.data as Dialog;
		//	
		//	// Remove
		//	dialogByTypeLookup[dialog.componentType] as Dialog;
		//	// Listeners
		//	dialog.removeEventListener(DialogConstants.DISPOSE, dialog_disposeHandler);
		//	
		//	// Redispatch
		//	dispatchEvent(event);
		//}
		
	}
}
