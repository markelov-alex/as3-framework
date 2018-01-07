package napalm.framework.dialog.flash
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import napalm.framework.dialog.Dialog;
	import napalm.framework.log.Channel;
	import napalm.framework.utils.DisplayUtil;
	
	/**
	 * FDialog.
	 *
	 * Note: if you wish to use starling and flash dialogs in one application, 
	 * FDialog.displayIndex should always be increased by some not big constant, 
	 * for example, 5, as flash dialogs always placed on top of starling's ones. 
	 * It's needed to treat them properly in DialogManager (for queueing).
	 */
	public class FDialog extends Dialog
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables
		
		protected var skinContainerFl:Sprite;
		private var isSkinCreatedHere:Boolean = false;

		// Properties

		override final protected function get assetPackName():String
		{
			return null;
		}

		override final protected function get additionalPackNames():Array
		{
			return null;
		}

		override final protected function get postLoadPackNames():Array
		{
			return null;
		}

		override public function get isLoading():Boolean
		{
			return false;
		}

		// Supposed that all Flash skins are included/embedded into current SWF
		override public function get isLoaded():Boolean
		{
			return true;
		}

		public function get displayObjectFl():DisplayObject
		{
			return skinObject as DisplayObject;
		}

		public function get displayContainerFl():DisplayObjectContainer
		{
			return skinObject as DisplayObjectContainer;
		}

		public function get interactiveObjectFl():InteractiveObject
		{
			return skinObject as InteractiveObject;
		}

		public function get spriteFl():Sprite
		{
			return skinObject as Sprite;
		}

		public function get movieClipFl():MovieClip
		{
			return skinObject as MovieClip;
		}

		// Constructor

		public function FDialog()
		{
			// (Don't change)
			isDisposeSkinOnHide = true;
			
			// Set in subclasses (@see also GUIComponent):
			///isDisposeSkinOnHide = false;
			///isDisposeAssetsOnHide = false;
			//showAnimationName = "ACTION";
			//hideAnimationName = "HIDE";
			//showTweenAnimationFun = defaultAnimateShowByTween;
			//hideTweenAnimationFun = defaultAnimateHideByTween;
			//showTweenTimeSec = 0.5;
			//hideTweenTimeSec = 0.5;
			//showTweenTransition = Transitions.EASE_IN_OUT_BACK;
			//hideTweenTransition = Transitions.EASE_IN_OUT_BACK;
		}

		// Methods

		override public function initialize(args:Array = null):void
		{
			super.initialize(args);

			skinContainerFl = args[2] as Sprite;
		}

		override public function dispose():void
		{
			skinContainerFl = null;
			
			super.dispose();
		}

//		// Override to create other components (panels) and set their skinObject
//		override protected function attachSkin():void
//		{
//			super.attachSkin();
//
//		}
//
//		// Override to dispose created components and their skinObject
//		override protected function detachSkin():void
//		{
//
//			super.detachSkin();
//		}

		override protected function checkCreateSkin():Boolean
		{
			log.info(Channel.DIALOG, this, "(checkCreateSkin)", "skinObject:", this.skinObject, 
					"this.skinClassName:", skinClassName, "skinContainerFl:", skinContainerFl);
			if (!isLoaded || this.skinObject || !skinClassName)
			{
				return false;
			}

			// Create skin
			var skinClass:Class = resourceManager.getDefinition(skinClassName);
			if (!skinClass)
			{
				log.warn(Channel.DIALOG, this, "(checkCreateSkin) No flash display class in resourceManager.getDefinition() with ", 
						"skinClassName:", skinClassName, "skinClass:", skinClass);
				return false;
			}
			
			var skinObjectFl:DisplayObject = new skinClass() as DisplayObject;
			if (skinObjectFl)
			{
				isSkinCreatedHere = true;
				if (skinContainerFl)
				{
					if (displayLevel < 0)//?
					{
						skinContainerFl.addChildAt(skinObjectFl, 0);
					}
					else
					{
						skinContainerFl.addChild(skinObjectFl);
					}
				}
			}
			this.skinObject = skinObjectFl;

			log.info(Channel.DIALOG, this, " (checkCreateSkin) skinClassName:", skinClassName, "skinObjectFl:", skinObjectFl, 
					"isFluid:", isFluidScaleMode, "isScale:", isScale);

			return Boolean(skinObjectFl);
		}

		override protected function disposeSkin():void
		{
			var displayObjectFl:DisplayObject = this.displayObjectFl;
			log.info(Channel.DIALOG, this, "(disposeSkin) displayObjectFl:", displayObjectFl);
			if (displayObjectFl)
			{
				skinObject = null;
				
				var movieClipFl:MovieClip = displayObjectFl as MovieClip;
				if (movieClipFl)
				{
					movieClipFl.stop();
				}
				if (isSkinCreatedHere && displayObjectFl.parent)
				{
					displayObjectFl.parent.removeChild(displayObjectFl);
					isSkinCreatedHere = false;
				}
			}
		}

		// Show/Hide

		override protected function moveSkinOnTop():void
		{
			// Move on top of a layer
			if (skinContainerFl && displayObjectFl)
			{
				skinContainerFl.addChild(displayObjectFl);
			}
		}

		override protected function showStart():void
		{
			// (Note: _isShowing = true; - is in doShow())
			if (displayObjectFl)
			{
				displayObjectFl.visible = true;
			}
			if (interactiveObjectFl)
			{
				interactiveObjectFl.mouseEnabled = false;
			}
			//?
//			if (spriteFl)
//			{
//				spriteFl.mouseChildren = false;
//			}

			super.showStart();
		}

		// Called always
		override protected function onShowCompleteCallback(event:* = null):void
		{
			if (interactiveObjectFl)
			{
				interactiveObjectFl.mouseEnabled = true;
			}
			//?
//			if (spriteFl)
//			{
//				spriteFl.mouseChildren = true;
//			}
			
			super.onShowCompleteCallback(event);
		}

		// May be omitted when hiding (if no animation or forced)
		override protected function hideStart():void
		{
			if (interactiveObjectFl)
			{
				interactiveObjectFl.mouseEnabled = false;
			}
			//?
//			if (spriteFl)
//			{
//				spriteFl.mouseChildren = false;
//			}
			
			super.hideStart();
		}

		// Override
		override protected function onAppResize():void
		{
			//...
			//try
			displayObjectFl.scaleX = resizeManager.appScaleX;
			displayObjectFl.scaleY = resizeManager.appScaleY;

			super.onAppResize();
		}

		override protected function centerDialog():void
		{
			if (displayObjectFl && resizeManager)
			{
				// Note: All dialogs exporting with center in top left corner of dialog
				displayObjectFl.x = int((resizeManager.appWidth - displayObjectFl.width) / 2);
				displayObjectFl.y = int((resizeManager.appHeight - displayObjectFl.height) / 2);
				log.info(Channel.DIALOG, this, "(centerDialog) isCenter:", isCenter,
						"displayObjectFl.x,y:", displayObjectFl.x, displayObjectFl.y,
						"displayObjectFl.scaleX,Y:", displayObjectFl.scaleX, displayObjectFl.scaleY,
						"displayObjectFl.width,height:", displayObjectFl.width, displayObjectFl.height,
						"resizeManager.appWidth,Height:", resizeManager.appWidth, resizeManager.appHeight);
			}
		}

		protected final function getSkinChildFlByPath(path:String):DisplayObject
		{
			return DisplayUtil.getChildByPath(displayObjectFl, path);
		}

		// Event handlers

	}
}
