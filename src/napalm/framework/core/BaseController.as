package napalm.framework.core
{
	import napalm.framework.log.Log;
	import napalm.framework.managers.SystemManager;
	
	/**
	 * BaseController.
	 * 
	 * Base class for all controllers.
	 * @author alex.panoptik@gmail.com
	 */
	public class BaseController// extends EventDispatcher
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		protected var systemManager:SystemManager;
		protected var log:Log;

		// Properties

		// Constructor

		public function BaseController()
		{
		}

		// Methods
		
//		public function initialize(systemManager:SystemManager):void
//		{
//			this.systemManager = systemManager;
//		    log = systemManager.log;
//		}
		
		public function dispose():void
		{
			systemManager = null;
			log = null;
		}

		// Event handlers

	}
}
