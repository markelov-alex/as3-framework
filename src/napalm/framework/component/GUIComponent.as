package napalm.framework.component
{
	import dragonBones.Armature;
	
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	
	import napalm.framework.display.GUIConstructor;
	import napalm.framework.display.GUISkin;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.ResizeManager;
	
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	
	/**
	 * GUIComponent.
	 *
	 * Creates skinObject automatically on initialize using skinClassName.
	 * @author alex.panoptik@gmail.com
	 */
	public class GUIComponent extends Component
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		protected var guiConstructor:GUIConstructor;

		// (Set in subclasses' constructors)
		protected var isFluidScaleMode:Boolean = false;
		protected var isScale:Boolean = true;
		/**
		 * Artist should draw dialogs for 2048x1568 resolution. But when they
		 * mistake and draw for higher resolution (e.g. for width 2200), some
		 * parts of dialog is out of screen. To scale down such dialogs set
		 * isScaleDownToFitApp=true.
		 */
		protected var isScaleDownToFitApp:Boolean = false;
		protected var isCreateBySkeleton:Boolean = false;
		protected var isConvertSkeletonData:Boolean = true;
		protected var isBuildAllArmatures:Boolean = false;

		// References
		protected var skinContainer:Sprite;

		protected var guiArmature:Armature;

		private var isSkinCreatedHere:Boolean = false;

		// Properties

		// Override
		/**
		 * Return "LobbyScreen" to create GUISkin from "LobbyScreen.png", "LobbyScreen.xml", "LobbyScreen.json"
		 *
		 * Return "CommonElements.MailItem" to create GUISkin from "CommonElements.png", "CommonElements.xml",
		 * "CommonElements.json", where "MailItem" is one of children in "CommonElements.json".
		 */
		protected function get skinClassName():String
		{
			return getQualifiedClassName(this).split("::")[1];
		}

		protected function get guiSkin():GUISkin
		{
			return skinObject as GUISkin;
		}

		// Constructor

		public function GUIComponent()
		{
			// Set in subclasses:
			//isFluidScaleMode = true;
			//isScale = false;
			//isScaleDownToFitApp = true;
			//isCreateBySkeleton = true;
			//isConvertSkeletonData = false;
			//isBuildAllArmatures = true;
		}

		// Methods

		/**
		 * @param args[0]    systemManager:SystemManager
		 * @param args[1]    assetManager:AssetManager || assetManagerName (assetPackName):String
		 * @param args[2]    skinContainer:Sprite
		 */
		override public function initialize(args:Array = null):void
		{
			super.initialize(args);
			
			log.info(Channel.COMPONENT, this, "(initialize) args:", args);
			
			skinContainer = args[2] as Sprite;

			guiConstructor = systemManager.guiConstructor;

			// Try to create skin 
			// (timeout needed to complete component's initialization before skinObject created (mostly for Flash skins))
			setTimeout(checkCreateSkin, 20);
		}

		override public function dispose():void
		{
			log.info(Channel.COMPONENT, this, "(dispose) skinContainer:", skinContainer, "assetManager:", assetManager);

			disposeSkin();

			skinContainer = null;
			guiConstructor = null;

			super.dispose();
		}

		override protected function attachSkin():void
		{
			super.attachSkin();

			onAppResize();
			
			// Listeners
			resizeManager.addEventListener(ResizeManager.RESIZE, onAppResize);
		}

		override protected function detachSkin():void
		{
			// Listeners
			resizeManager.removeEventListener(ResizeManager.RESIZE, onAppResize);

			super.detachSkin();
		}

		override protected final function getSkinChildByPath(path:String):DisplayObject
		{
			var result:DisplayObject = guiSkin ? guiSkin.getChildByPath(path) : null;
			return result || super.getSkinChildByPath(path);
		}

		protected function checkCreateSkin():Boolean
		{
			var isLoaded:Boolean = assetManager && assetManager.isLoaded;
			var skinClassName:String = this.skinClassName;
			log.info(Channel.COMPONENT, this, "(checkCreateSkin) assetManager:", assetManager, ".isLoaded:", isLoaded, 
					"skinObject:", skinObject, "this.skinClassName:", skinClassName, "skinContainer:", skinContainer);
			if (!isLoaded || skinObject || !skinClassName)
			{
				return false;
			}

			// Create skin
			var guiSkin:GUISkin = guiConstructor.createAndConstructGUISkin(assetManager, skinClassName, 
														isFluidScaleMode, isScale, isScaleDownToFitApp, 
														isCreateBySkeleton, isConvertSkeletonData, isBuildAllArmatures);
			if (guiSkin)
			{
				isSkinCreatedHere = true;
			}
			if (guiSkin && skinContainer)
			{
				skinContainer.addChild(guiSkin);
			}
			skinObject = guiSkin;

			guiArmature = isCreateBySkeleton && guiSkin ? guiSkin.armature : null;
			log.info(Channel.COMPONENT, this, " (checkCreateSkin) skinClassName:", skinClassName, "guiSkin:", guiSkin, 
					"guiArmature:", guiArmature, "isBySkeleton:", isCreateBySkeleton, "isFluid:", isFluidScaleMode, 
					"isConvertSkeleton:", isConvertSkeletonData, "isScale:", isScale);

			return guiSkin != null;
		}

		protected function disposeSkin():void
		{
			var displayObject:DisplayObject = this.displayObject;
			log.info(Channel.COMPONENT, this, "(disposeSkin) displayObject,guiArmature:", displayObject, guiArmature);
			if (displayObject)
			{
				skinObject = null;

				if (isSkinCreatedHere)
				{
					displayObject.removeFromParent(true);
					isSkinCreatedHere = false;
				}
			}

			guiArmature = null;
		}

		// Override
		protected function onAppResize():void
		{
			guiConstructor.updateGUISkinOnAppResize(guiSkin);
		}

		// Event handlers

	}
}
