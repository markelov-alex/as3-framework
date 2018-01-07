package napalm.framework.managers
{
	import napalm.framework.log.Log;
	
	import starling.events.EventDispatcher;
	
	/**
	 * BaseManager.
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class BaseManager extends EventDispatcher
	{
		
		// Class constants
		
		// Class variables
		// Class methods
		
		// Variables
		
		protected var log:Log;
		
		// Properties
		
		private var _systemManager:SystemManager;
		protected function get systemManager():SystemManager
		{
			return _systemManager;
		}
		
		protected function get isInitialized():Boolean
		{
			return _systemManager != null;
		}
		
		// Constructor
		
		public function BaseManager()
		{
		}
		
		// Methods

		/**
		 * Called automatically from SystemManager.initialize().
		 * 
		 * @param systemManager
		 */
		// Override
		public function initialize(systemManager:SystemManager):void
		{
			if (isInitialized)
			{
				return;
			}
			
			_systemManager = systemManager;
			log = systemManager.log;
		}

		/**
		 * Called automatically from SystemManager.dispose().
		 */
		// Override
		public function dispose():void
		{
			if (!isInitialized)
			{
				return;
			}
			
			_systemManager = null;
			log = null;
		}
		
		// Event handlers
		
	}
}
