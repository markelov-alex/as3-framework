package napalm.framework.component
{
	import napalm.framework.display.GUIUtil;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.EventDispatcher;
	
	/**
	 * SimpleComponent.
	 * 
	 * Note: set all settings (component's public vars) before initialize()!
	 * Note: set skinObject after initialize()!
	 * 
	 * Base component class for using without framework.
	 * @author alex.panoptik@gmail.com
	 */
	public class SimpleComponent extends EventDispatcher
	{

		// Class constants
		// Class variables
		
		public static var isWarnOnNoChildSkinByPath:Boolean = false;
		
		// Class methods

		// Variables
		
		public var data:*;
		
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

		public function get sprite():Sprite
		{
			return _skinObject as Sprite;
		}

		//-public function get movieClip():MovieClip
		//{
		//	return _skinObject as MovieClip;
		//}

		// Constructor

		public function SimpleComponent()
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
			data = null;
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
		protected function getSkinChildByPath(path:String):DisplayObject
		{
			var child:DisplayObject = GUIUtil.getChildByPath(skinObject, path) as DisplayObject;
			if (!child && isWarnOnNoChildSkinByPath)
			{
				log.warn(Channel.COMPONENT, this, "Cannot get child by path! skinObject:", skinObject, "path:", path);
			}
			return child;
		}

		// Event handlers

	}
}
