package napalm.framework.core
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import napalm.framework.log.Log;
	
	/**
	 * BaseModel.
	 * 
	 * Base class for all models.
	 * @author alex.panoptik@gmail.com
	 */
	public class BaseModel// extends EventDispatcher
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables
		
		protected var log:Log;
		
		private var validationTimer:Timer = new Timer(100);

		// Properties

		// Constructor

		public function BaseModel()
		{
			log = Log.instance;
			
			// Listener
			validationTimer.addEventListener(TimerEvent.TIMER, validationTimer_timerHandler);
		}

		// Methods

//		public function initialize():void
//		{
//		    log = systemManager.log;
//		}

		public function dispose():void
		{
			validationTimer.stop();
			log = null;
		}
		
		protected final function invalidate():void
		{
			trace("temp (invalidate)",this)
			validationTimer.start();
		}
		
		// Override
		protected function validate():void
		{
			//trace("temp (validate)",this)
		}

		// Event handlers
		
		private function validationTimer_timerHandler(event:Event):void
		{
			validationTimer.stop();
			validate();
		}

	}
}
