package napalm.framework.dialog
{
	import dragonBones.animation.Animation;
	import dragonBones.events.AnimationEvent;
	
	import napalm.framework.component.GUIComponentExt;
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.AudioManager;
	
	import starling.core.Starling;
	
	/**
	 * Dialog.
	 *
	 * Does:
	 * 1. load assets;
	 * 2. create GUISkin;
	 * 3. show/hide animation;
	 * 4. scale and position on resize.
	 * In subclasses:
	 * 5. create/get models and controllers;
	 * 6. create components, initialize them with models and controllers.
	 *
	 * Dialog creates skinObject be itself on doShow() and disposes
	 * it after doHide().
	 *
	 * Note: LOAD_START and LOAD_COMPLETE may not be dispatched is assets already loaded;
	 *         HIDE_START may not be dispatched if hide is forced (isForce=true);
	 *         all other events are dispatching always.
	 * @author alex.panoptik@gmail.com
	 */
	public class Dialog extends GUIComponentExt
	{

		// Class constants
		// Class variables

		// Class methods

		// In subclasses (for convenience):
		//public static function show(myparam:Boolean, myparam2:Number):void
		//{
		//	SystemManager.getInstance.dialogManager.show(MyDialog, [myparam, myparam2]);
		//}
		//public static function hide(isForce:Boolean):void
		//{
		//	SystemManager.getInstance.dialogManager.hide(MyDialog, isForce);
		//}

		// Variables

		// (Set in subclasses' constructors)
		protected var isDisposeSkinOnHide:Boolean = true;
		// Set false for only important dialogs like CashDialog or ShopDialog
		protected var isDisposeAssetsOnHide:Boolean = true;
		//?protected var isDisposeDialogOnHide:Boolean = false;
		protected var isCenter:Boolean = true;

		// Skeleton show/hide animation
		protected var showAnimationName:String = "ACTION";
		protected var hideAnimationName:String = "HIDE";
		// Tween show/hide animation
		protected var isShowTweenEnabled:Boolean = true;
		protected var isHideTweenEnabled:Boolean = true;
		// function(displayObject:DisplayObject, onComplete:Function):void
		protected var animateShowByTweenFun:Function;
		protected var animateHideByTweenFun:Function;

		// References
		//protected var resourceManager:ResourceManager;
		//protected var dialogManager:DialogManager;
		protected var audioManager:AudioManager;

		protected var argsArray:Array;
		private var isForceShow:Boolean;
		private var prevSkinClassName:String;

		protected var webAssetPackNameLow:String;
		protected var webAdditionalPackNamesCommon:Array = [];
		protected var webAdditionalPackNamesLow:Array = [];
		protected var webAdditionalPackNamesHigh:Array = [];
		protected var postLoadPackNamesCommon:Array = [];
		protected var isStartWithLowQuality:Boolean = false;
		
		private var isSkinCreatedAtLeastOnce:Boolean = false;
		private var isRecreating:Boolean = false;
		private var loadingSkinClassName:String;

		// Properties

//-		override protected function get skinClassName():String
//		{
//			if (Device.isMobile)
//			{
//				return super.skinClassName;
//			}
////--			return (isStartWithLowQuality && !isSkinCreatedAtLeastOnce ? webSkinClassNameLow : webSkinClassName) || webSkinClassName;
////-			return isStartingLowQuality && webAssetPackNameLow ? webAssetPackNameLow : webSkinClassName;
//			return webSkinClassName;
//		}

		/**
		 * Level on which dialog will be placed. Only one dialog per level allowed.
		 * Return -1 to place on 0-th level, but under all items on that level.
		 * 
		 * Usually returns:
		 *    0 for regular dialogs,
		 *    1 for important top level dialogs (CashDialog, ShopDialog, ErrorDialog, InfoDialog, etc),
		 *   -1 for screens (to place under another screen on show).
		 */
		public function get displayLevel():int
		{
			return 0;
		}

		/**
		 * Will be checked when pressing Android's "Back" button, for example.
		 */
		// Override
		public function get isCloseable():Boolean
		{
			return true;
		}

		/**
		 * true - for dialogs (we can dispose dialog immediately after dialog was hidden),
		 * false - for screens (we should wait while next screen is loaded
		 *        before we could dispose previous screen).
		 */
		// Override
		protected function get isHideOnHideComplete():Boolean
		{
			return true;
		}

		// Override
		//?internal function get isDisposeOnHideComplete():Boolean
		//{
		//	return false;
		//}

		/**
		 * Each assetPack corresponds to appropriate AssetManager in ResourceManager.
		 */
		// Override
		protected function get assetPackName():String
		{
			if (!Device.isMobile && isStartWithLowQuality && webAssetPackNameLow)
			{
				return webAssetPackNameLow;
			}
			var value:String = skinClassName ? skinClassName.split(".")[0] : skinClassName;
			return value;
		}

		/**
		 * Use for some items, common assets, etc. Both String and Class types allowed.
		 * Example: return ["StuffItemSkinMobile", InventoryStuffItemSkinMobile];
		 */
		// Override
		protected function get additionalPackNames():Array
		{
//-			return null;
			var result:Array = webAdditionalPackNamesCommon || [];
			if (isStartingLowQuality && webAdditionalPackNamesLow)
			{
				result = result.concat(webAdditionalPackNamesLow);
			}
			else if (webAdditionalPackNamesHigh)
			{
				result = result.concat(webAdditionalPackNamesHigh);
			}
			return result;
		}

		/**
		 * Use for some items, common assets, etc. Both String and Class types allowed.
		 * Example: return ["GameFieldAnimations", "SpecialEffects"];
		 */
		// Override
		protected function get postLoadPackNames():Array
		{
			if (!isStartingLowQuality)
			{
				return postLoadPackNamesCommon;
			}
			
			var highQualityAssetPackNames:Array = webAdditionalPackNamesLow ? webAdditionalPackNamesHigh || [] : [];
			if (webAssetPackNameLow)
			{
				highQualityAssetPackNames = highQualityAssetPackNames.concat(webSkinClassName);
			}
			return (postLoadPackNamesCommon || []).concat(highQualityAssetPackNames);
		}

		protected final function get isStartingLowQuality():Boolean
		{
			return isStartWithLowQuality && !isSkinCreatedAtLeastOnce;
		}

		public function get isModal():Boolean
		{
			return true;
		}

		public function get isLoading():Boolean
		{
			return assetManager && assetManager.isLoading;
		}

		public function get isLoaded():Boolean
		{
			return assetManager && assetManager.isLoaded;
		}

		public function get isShowReady():Boolean
		{
			return isLoaded && skinObject;
		}

		private var _isShowing:Boolean = false;
		public function get isShowing():Boolean
		{
			return _isShowing;
		}

		private var _isShown:Boolean = false;
		public function get isShown():Boolean
		{
			return _isShown;
		}

		private var _isHiding:Boolean = false;
		public function get isHiding():Boolean
		{
			return _isHiding;
		}

		// Constructor

		public function Dialog()
		{
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

//			log.info(Channel.DIALOG, this, "--(constructor) displayLevel:", displayLevel, "assetPackName:", assetPackName,
//				"skinClassName:", skinClassName, "isHideOnHideComplete:", isHideOnHideComplete);
		}

		// Methods

		/**
		 * @param args    @see GUIComponent
		 */
		override public function initialize(args:Array = null):void
		{
			super.initialize(args);

			log.info(Channel.DIALOG, this, "--[DLG] (initialize) args:", args, "skinContainer:", skinContainer, "assetManager:", assetManager);

			//resourceManager = systemManager.resourceManager;
			//dialogManager = systemManager.dialogManager;
			audioManager = systemManager.audioManager;
			trace("###initialize audioManager",this,audioManager)

			if (animateShowByTweenFun == null)
			{
				animateShowByTweenFun = dialogManager.defaultAnimateShowByTweenFun;
			}
			if (animateHideByTweenFun == null)
			{
				animateHideByTweenFun = dialogManager.defaultAnimateHideByTweenFun;
			}
			
			//(for loading dialog)
			assetManager = resourceManager.getAssetManagerByPackName(assetPackName, additionalPackNames, postLoadPackNames);
		}

		override public function dispose():void
		{
			log.log(Channel.DIALOG, this, "--[DLG](dispose) assetManager:", assetManager);

			// Dispatch
			//?dispatchEventWith(DialogConstants.DISPOSE, false, this);

			disposeAssets();

			//resourceManager = null;
			//dialogManager = null;
			//resizeManager = null;
			audioManager = null;

			assetManager = null;

			super.dispose();
		}

		// Override to create other components (panels) and set their skinObject
		override protected function attachSkin():void
		{
			super.attachSkin();
			
			log.info(Channel.DIALOG, this, "--[DLG](attachSkin) skinObject:", skinObject, "skinClassName:", skinClassName);
		trace("###attachSkin audioManager",this,audioManager)
			audioManager.addAssetManager(assetManager);
		}

		// Override to dispose created components and their skinObject
		override protected function detachSkin():void
		{
			log.info(Channel.DIALOG, this, "--[DLG](detachSkin) skinObject:", skinObject);
			audioManager.removeAssetManager(assetManager);
			
			super.detachSkin();
		}

		override protected function checkCreateSkin():Boolean
		{
			// Needed if device rotated while loading and skinClassName changed
			if (loadingSkinClassName && loadingSkinClassName != skinClassName)
			{
				// (reload assetmanager)
				log.log(Channel.DIALOG, this, "(checkCreateSkin) loadingSkinClassName!=skinClassName. Maybe device was rotated while loading. " +
						"<recreateSkin;return-false>", "loadingSkinClassName:", loadingSkinClassName, "skinClassName:", skinClassName);
				recreateSkin();
				return false;
			}
			
			var result:Boolean = super.checkCreateSkin();
			if (result)
			{
				prevSkinClassName = skinClassName;
				isSkinCreatedAtLeastOnce = true;
			}
			if (result && displayLevel < 0 && guiSkin && skinContainer)
			{
				skinContainer.addChildAt(guiSkin, 0);
			}
			log.log(Channel.DIALOG, this, "--[DLG](checkCreateSkin)", "result:", result, "guiSkin:", guiSkin, 
					"displayLevel:", displayLevel, "skinContainer:", skinContainer, 
					"skinClassName:", skinClassName, "new-prevSkinClassName:", prevSkinClassName);//, new Error().getStackTrace()

			return result;
		}

		protected function disposeAssets():void
		{
			if (!assetManager)
			{
				return;
			}
			
			log.info(Channel.DIALOG, this, "--[DLG](disposeAssets) resourceManager:", resourceManager, "assetManager:", assetManager, 
					"assetManager.name:", assetManager.name, "(current-assetPackName:", assetPackName + ")");
			if (resourceManager)
			{
				resourceManager.disposeAssetManagerByPackName(assetManager.name);
			}
			assetManager = null;
		}

		// Show/Hide

		public function hide(isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "--[DLG](hide) isForce:", isForce, "isHiding:", _isHiding);
			if (!_isHiding)
			{
				dialogManager.hide(this, isForce);
			}
		}

		internal function doShow(args:Array, isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "--[DLG](doShow) args:", args, "isLoaded(t):", isLoaded, "isShowing(f):", isShowing, 
					"isShown(f):", isShown, "assetManager:", assetManager);
			// Use paramArray in subclasses
			argsArray = args;
			isForceShow = isForce;
			
			if (_isShown || _isShowing)
			{
				moveSkinOnTop();
				return;
			}

			_isShowing = true;

			if (!assetManager)
			{
				assetManager = resourceManager.getAssetManagerByPackName(assetPackName, additionalPackNames, postLoadPackNames);
			}

			if (!isLoaded)
			{
				load();
			}
			else
			{
				// Create skin
				checkCreateSkin();
				
				showStart();
			}
		}

		internal function doHide(isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "--[DLG](doHide) isForce:", isForce, "isHiding(f):", isHiding, "isShowing(f):", isShowing, "isShown(t):", isShown);
			if (_isHiding)// || _isShowing || !_isShown
			{
				return;
			}

			if (_isShowing)
			{
				onShowCompleteCallback(true);
			}

			if (!isForce)
			{
				hideStart();
			}
			else
			{
				onHideCompleteCallback(null, isForce);
			}
		}

		// Move on top of a layer
		protected function moveSkinOnTop():void
		{
			if (skinContainer && displayObject)
			{
				skinContainer.addChild(displayObject);
			}
		}

		protected function load():void
		{
			log.log(Channel.DIALOG, this, "--[DLG](load) assetManager:", assetManager, "isLoaded:", isLoaded);
			//(needed as it's set to null in disposeAssets())
			if (!assetManager || isLoaded)
			{
				return;
			}
			
			if (!isRecreating)
			{
				log.info(Channel.DIALOG, this, "--[DLG] (load) <dialog_dispatch-LOAD_START;assetManager.load>");
				// Dispatch
				dispatchEventWith(DialogConstants.LOAD_START, false, this);
			}

			loadingSkinClassName = skinClassName;
			assetManager.load(onLoadCompleteCallback);
		}

		protected function onLoadCompleteCallback():void
		{
			log.log(Channel.DIALOG, this, "--[DLG](onLoadCompleteCallback) <checkCreateSkin;dialog_dispatch-LOAD_COMPLETE;showStart?> isShowing:", _isShowing);
			// Create skin
			// Note: create skin before LOAD_COMPLETE dispatched to hide loading dialog after skin created
			checkCreateSkin();

			onLoadComplete();

			if (!isRecreating)
			{
				// Dispatch
				dispatchEventWith(DialogConstants.LOAD_COMPLETE, false, this);
			}
			
			if (_isShowing)
			{
				showStart();
			}
		}

		// Override
		protected function onPostLoadComplete():void
		{
			log.log(Channel.DIALOG, this, "(onPostLoadComplete)",webAssetPackNameLow, "&&", webSkinClassName, "||", webAdditionalPackNamesLow, "&&", webAdditionalPackNamesHigh);
			// Recreate skin if low-graph was created and high-quality assets have been post-loaded
			if ((webAssetPackNameLow && webSkinClassName) || 
					(webAdditionalPackNamesLow && webAdditionalPackNamesLow.length && 
							webAdditionalPackNamesHigh && webAdditionalPackNamesHigh.length))
			{
				log.info(Channel.DIALOG, this, " (onPostLoadComplete) <recreateSkin>");
				recreateSkin(true);
			}
		}
//- (Low and high quality assets have same names, so low assets will be replaced by high assets 
//   automatically, hence we don't need to remove low assets manually)
//		override protected function disposeSkin():void
//		{
//			super.disposeSkin();
//			
//			// (Needed for first launch when recreating skin after high-quality assets loaded)
//			disposeLowAssets();
//		}
//
//		private function disposeLowAssets():void
//		{
//			log.info(Channel.DIALOG, this, " (disposeLowAssets) <assetManager.removeObject;removeTextureAtlas>",
//					"webSkinClassNameLow:", webAssetPackNameLow, "webAdditionalPackNamesLow:",
//					webAdditionalPackNamesLow, "(webAdditionalPackNamesHigh:", webAdditionalPackNamesHigh + ")");
//			if (webAssetPackNameLow && webSkinClassName)
//			{
//				assetManager.removeObject(webAssetPackNameLow);
//				assetManager.removeTextureAtlas(webAssetPackNameLow, true);
//			}
//
//			// (Don't remove low assets if there are no high assets to be loaded)
//			if (webAdditionalPackNamesLow && webAdditionalPackNamesLow.length && 
//					webAdditionalPackNamesHigh && webAdditionalPackNamesHigh.length)
//			{
//				for each (var webAdditionalPackName:String in webAdditionalPackNamesLow)
//				{
//					assetManager.removeObject(webAdditionalPackName);
//					assetManager.removeTextureAtlas(webAdditionalPackName, true);
//				}
//			}
//		}

		// Override
		protected function onLoadComplete():void
		{
		}

		protected function showStart():void
		{
			if (!skinObject)
			{
				log.error(Channel.DIALOG, this, "--[DLG](showStart) <onHideCompleteCallback;return> Dialog has no skinObject! skinObject:", skinObject);
				onHideCompleteCallback();
				return;
			}

			if (displayObject)
			{
				log.log(Channel.DIALOG, this, "--[DLG](showStart) <visible=true,touchable=false;dialog_dispatch-SHOW_START;animateShow> " +
						"displayObject:", displayObject);
				// (Note: _isShowing = true; - is in doShow())
				displayObject.visible = true;
				displayObject.touchable = false;
			}

			// Dispatch
			dispatchEventWith(DialogConstants.SHOW_START, false, this);

			if (isCenter)
			{
				centerDialog();
			}
			
			// Animate
			animateShow();
		}
		
		// Called always
		protected function onShowCompleteCallback(event:* = null):void
		{
			log.log(Channel.DIALOG, this, "--[DLG](onShowCompleteCallback) <touchable=true;dialog_dispatch-SHOW_COMPLETE> prev-isShowing:",
					isShowing, "prev-isShown:", isShown, "guiArmature:", guiArmature, "event:", event);
			// Animation
			if (guiArmature)
			{
				// Listeners
				guiArmature.removeEventListener(AnimationEvent.COMPLETE, onShowComplete);
			}
			if (Starling.juggler)
			{
				Starling.juggler.removeTweens(displayObject);
			}

			// Result
			if (displayObject)
			{
				displayObject.touchable = true;
			}
			_isShowing = false;
			_isShown = true;
			
			onShowComplete();

			// Dispatch
			dispatchEventWith(DialogConstants.SHOW_COMPLETE, false, this);
			
			// (Fixing bug on rotating device while loading)
			if (event !== true)
			{
				log.info(Channel.DIALOG, this, "--[DLG] (onShowCompleteCallback) <isRecreating=false>", 
						"prev-isRecreating:", isRecreating);
				isRecreating = false;
			}

			// Assets post loading
			if (assetManager)
			{
				assetManager.postLoad(onPostLoadComplete);
			}
		}

		// Override
		protected function onShowComplete():void
		{
		}

		// May be omitted when hiding (if no animation or forced)
		protected function hideStart():void
		{
			log.log(Channel.DIALOG, this, "--[DLG](hideStart) <touchable=false;dialog_dispatch-HIDE_START;animateHide> " +
					"prev-isHiding:", _isHiding, "prev-isShown:", _isShown);
			if (displayObject)
			{
				displayObject.touchable = false;
			}
			_isHiding = true;
			_isShown = false;

			if (!isRecreating)
			{
				// Dispatch
				dispatchEventWith(DialogConstants.HIDE_START, false, this);
			}

			// Animate
			animateHide();
		}

		// Called always
		protected function onHideCompleteCallback(event:* = null, isForce:Boolean = false):void
		{
			log.log(Channel.DIALOG, this, "--[DLG](onHideCompleteCallback) <doHidden?> isHideOnHideComplete:", isHideOnHideComplete, 
					"isForce:", isForce, "isHiding:", _isHiding, "isShown:", _isShown, "guiArmature:", guiArmature);
			// Animation
			if (guiArmature)
			{
				// Listeners
				guiArmature.removeEventListener(AnimationEvent.COMPLETE, onHideCompleteCallback);
			}

			// true - for dialogs, false - for screens
			if (isHideOnHideComplete || isForce)
			{
				doHidden();
			}

			// Result
			//was- if (_isShown || _isHiding)
			{
				_isShowing = false;
				_isHiding = false;
				_isShown = false;

				if (!isRecreating)
				{
					log.log(Channel.DIALOG, this, "--[DLG](onHideCompleteCallback) <dialog_dispatch-HIDE_COMPLETE>");
					// Dispatch
					// (Note: should be after removeFromParent)
					dispatchEventWith(DialogConstants.HIDE_COMPLETE, false, this);
				}
			}
		}

		// Override
		protected function onHideComplete():void
		{
		}

		internal function doHidden():void
		{
			log.log(Channel.DIALOG, this, "--[DLG](doHidden) <visible,touchable=false;disposeSkin/Assets?> " +
					"isDisposeSkinOnHide:", isDisposeSkinOnHide, "isDisposeAssetsOnHide:", isDisposeAssetsOnHide);
			if (displayObject)
			{
				displayObject.visible = false;
				displayObject.touchable = false;
			}

			// Dispose
			// (true by default)
			if (isDisposeSkinOnHide)
			{
				disposeSkin();

				// (true by default)
				if (isDisposeAssetsOnHide)
				{
					disposeAssets();
				}
			}

			//?if (isDisposeDialogOnHide)
			//{
			//	dispose();
			//}
		}

		// (Override)
		protected function animateShow():void
		{
			var animation:Animation = guiArmature ? guiArmature.animation : null;
			log.log(Channel.DIALOG, this, "--[DLG](animateShow) guiArmature,animation,hasAnimation:", guiArmature, animation,
					animation && animation.hasAnimation(showAnimationName), "showAnimationName:", showAnimationName,
					"animateShowByTweenFun:", animateShowByTweenFun != null);
			if (!isForceShow && animation && animation.hasAnimation(showAnimationName))
			{
				log.log(Channel.DIALOG, this, "--[DLG] (animateShow) <animation.gotoAndPlay>");
				// Listeners
				guiArmature.addEventListener(AnimationEvent.COMPLETE, onShowCompleteCallback);
				animation.gotoAndPlay(showAnimationName, 0);
			}
			else if (!isForceShow && isShowTweenEnabled && animateShowByTweenFun != null)
			{
				log.log(Channel.DIALOG, this, "--[DLG] (animateShow) <tween>");
				animateShowByTweenFun(skinObject, onShowCompleteCallback);
			}
			else
			{
				onShowCompleteCallback();
			}
		}

		// (Override)
		protected function animateHide():void
		{
			var animation:Animation = guiArmature ? guiArmature.animation : null;
			log.log(Channel.DIALOG, this, "--[DLG](animateHide) guiArmature,animation,hasAnimation:", guiArmature, animation,
					animation && animation.hasAnimation(hideAnimationName), "hideAnimationName:", hideAnimationName,
					"animateHideByTweenFun:", animateHideByTweenFun != null);
			if (animation && animation.hasAnimation(hideAnimationName))
			{
				log.log(Channel.DIALOG, this, "--[DLG] (animateHide) <animation.gotoAndPlay>");
				// Listeners
				guiArmature.addEventListener(AnimationEvent.COMPLETE, onHideCompleteCallback);
				animation.gotoAndPlay(hideAnimationName, 0);
			}
			else if (isHideTweenEnabled && animateHideByTweenFun != null)
			{
				log.log(Channel.DIALOG, this, "--[DLG] (animateHide) <tween>");
				animateHideByTweenFun(skinObject, onHideCompleteCallback);
			}
			else
			{
				onHideCompleteCallback();
			}
		}

		// Override
		override protected function onAppResize():void
		{
			super.onAppResize();

			log.info(Channel.DIALOG, this, "(onAppResize)", skinObject, "isCenter:", isCenter, "skinObject.scaleX,Y:",
					skinObject ? (skinObject.scaleX + "," + skinObject.scaleY) : "-");
			if (isCenter)
			{
				centerDialog();
			}
		}

		protected function centerDialog():void
		{
			if (displayObject && resizeManager)
			{
				// Note: All dialogs exporting with center in top left corner of dialog
				displayObject.x = int((resizeManager.appWidth - displayObject.width) / 2);
				displayObject.y = int((resizeManager.appHeight - displayObject.height) / 2);
				log.info(Channel.DIALOG, this, "(centerDialog) isCenter:", isCenter,
						"displayObject.x,y:", displayObject.x, displayObject.y,
						"displayObject.scaleX,Y:", displayObject.scaleX, displayObject.scaleY,
						"displayObject.width,height:", displayObject.width, displayObject.height,
						"resizeManager.appWidth,Height:", resizeManager.appWidth, resizeManager.appHeight);
			}
		}
		
		// Event handlers
		
	}
}
