package napalm.framework.component
{
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	import napalm.framework.managers.ResizeManager;
	
	/**
	 * GUIComponentExt.
	 * 
	 * GUIComponent with:
	 * 1. recreating skin on orientation changed - portrait/landscape (auto rotating for mobile);
	 * 2. recreating skin on quality changed (HD/SD for web - now used only for Retina);
	 * @author alex.panoptik@gmail.com
	 */
	public class GUIComponentExt extends GUIComponent
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		protected var isRotatable:Boolean = true;

		protected var webSkinClassName:String;
		protected var mobilePortraitSkinClassName:String;
		protected var mobileLandscapeSkinClassName:String;

		// Properties

		/**
		 * Set webSkinClassName, mobilePortraitSkinClassName, mobileLandscapeSkinClassName 
		 * instead of overriding.
		 */
		override protected function get skinClassName():String
		{
			if (Device.isMobile && (mobilePortraitSkinClassName || mobileLandscapeSkinClassName))
			{
				return (resizeManager.isPortraitOrientation && mobilePortraitSkinClassName ? 
						mobilePortraitSkinClassName : mobileLandscapeSkinClassName);
			}
			return webSkinClassName;
		}

		private var _isRotating:Boolean = false;
		protected function get isRotating():Boolean
		{
			return _isRotating;
		}

		// Constructor

		public function GUIComponentExt()
		{
			// Set in subclasses:
			//webSkinClassName = "";
			//mobilePortraitSkinClassName = "";
			//mobileLandscapeSkinClassName = "";
			////isRotatable = false;
		}

		// Methods

		override public function initialize(args:Array = null):void
		{
			super.initialize(args);

			if (Device.isMobile && mobilePortraitSkinClassName && mobileLandscapeSkinClassName)
			{
				// Listeners
				resizeManager.addEventListener(ResizeManager.ORIENTATION_CHANGE, resizeManager_orientationChangeHandler);
			}
		}

		override public function dispose():void
		{
			if (Device.isMobile)
			{
				// Listeners
				resizeManager.removeEventListener(ResizeManager.ORIENTATION_CHANGE, resizeManager_orientationChangeHandler);
			}
			
			super.dispose();
		}

		override protected function attachSkin():void
		{
			super.attachSkin();
			
			_isRotating = false;
			log.info(Channel.COMPONENT, this, "(attachSkin) <isRotating=false>", "isRotating:", _isRotating);
			
			// Listeners
			resizeManager.addEventListener(ResizeManager.QUALITY_TYPE_CHANGE, resizeManager_qualityTypeChangeHandler);
		}

		override protected function detachSkin():void
		{
			// Listeners
			resizeManager.removeEventListener(ResizeManager.QUALITY_TYPE_CHANGE, resizeManager_qualityTypeChangeHandler);
			
			super.detachSkin();
		}

		protected function recreateSkin(isSimpleRecreate:Boolean = false):void
		{
			log.info(Channel.COMPONENT, this, "(recreateSkin) <disposeSkin;checkCreateSkin>");
			disposeSkin();
			checkCreateSkin();
		}

		// Event handlers

		private function resizeManager_orientationChangeHandler():void
		{
			var isRotationAvailable:Boolean = Device.isMobile && mobilePortraitSkinClassName && 
					mobileLandscapeSkinClassName && mobilePortraitSkinClassName != mobileLandscapeSkinClassName;
			log.info(Channel.COMPONENT, this, "(resizeManager_orientationChangeHandler)", "skinObject:", skinObject, 
					"isRotating:", _isRotating, "isRotatable:", isRotatable, "isRotationAvailable:", isRotationAvailable, 
					"mobilePortraitSkinClassName:", mobilePortraitSkinClassName, 
					"mobileLandscapeSkinClassName:", mobileLandscapeSkinClassName);
			if ((skinObject && isRotatable && isRotationAvailable) || isRotating)
			{
				_isRotating = true;
				log.info(Channel.COMPONENT, this, "(resizeManager_orientationChangeHandler) <isRotating=true>", "isRotating:", _isRotating);
				// (isSimpleRecreate=false for GameScreen orientation change)
				recreateSkin();
				log.info(Channel.COMPONENT, this, " (resizeManager_orientationChangeHandler) after");
			}
		}

		private function resizeManager_qualityTypeChangeHandler():void
		{
			recreateSkin();
		}

	}
}
