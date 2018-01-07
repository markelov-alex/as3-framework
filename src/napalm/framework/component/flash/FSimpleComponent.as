package napalm.framework.component.flash
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	
	import napalm.framework.component.SimpleComponent;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.DisplayUtil;
	
	/**
	 * FSimpleComponent.
	 * 
	 * Note: set all settings (component's public vars) before initialize()!
	 * Note: set skinObject after initialize()!
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class FSimpleComponent extends EventDispatcher
	{

		// Class constants
		// Class variables

		// Class methods

		// Variables
		
		protected var log:Log;

		// Properties

		private var _skinObject:Object;
		public final function get skinObject():Object
		{
			return _skinObject;
		}
		public function set skinObject(value:Object):void
		{
			if (_skinObject === value)
			{
				return;
			}

			if (_skinObject)
			{
				detachSkin();
			}

			_skinObject = value;

			if (_skinObject)
			{
				attachSkin();
			}
		}

		public function get displayObject():DisplayObject
		{
			return _skinObject as DisplayObject;
		}

		public function get displayContainer():DisplayObjectContainer
		{
			return _skinObject as DisplayObjectContainer;
		}

		public function get interactiveObject():InteractiveObject
		{
			return _skinObject as InteractiveObject;
		}

		public function get sprite():Sprite
		{
			return _skinObject as Sprite;
		}

		public function get movieClip():MovieClip
		{
			return _skinObject as MovieClip;
		}

		//-public function get movieClip():MovieClip
		//{
		//	return _skinObject as MovieClip;
		//}

		// Constructor

		public function FSimpleComponent()
		{
		}

		// Methods

		// Override
		public function initialize(args:Array = null):void
		{
			log = Log.instance;
		}

		// Override
		public function dispose():void
		{
			skinObject = null;
			log = null;
		}

		// Override
		// Note: when attachSkin() is called (set skinObject property) skinObject should be already added to stage!
		protected function attachSkin():void
		{
		}

		// Override
		protected function detachSkin():void
		{
		}

		/**
		 * Use to get any displayObject inside skinObject in any depth.
		 *
		 * @param path
		 * @return
		 */
		protected final function getSkinChildByPath(path:String):DisplayObject
		{
			var child:DisplayObject = DisplayUtil.getChildByPath(skinObject as DisplayObject, path) as DisplayObject;
			if (!child && SimpleComponent.isWarnOnNoChildSkinByPath)
			{
				log.warn(Channel.COMPONENT, this, "Cannot get child by path! skinObject:", skinObject, "path:", path);
			}
			return child;
		}

		// Event handlers

	}
}
