package napalm.framework.config
{
	import flash.net.SharedObject;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	/**
	 * Preferences.
	 * 
	 * Wrapper for SharedObject to be used as user's preferences storage.
	 * 
	 * You can use static methods if you are sure that you will use only one app instance. 
	 * For multiple apps loading create own Preferences for each app (like SystemManager does).
	 * @author alex.panoptik@gmail.com
	 */
	public class Preferences
	{

		// Class constants
		
		// Class variables
		
		protected static var log:Log;
		private static var preferences:Preferences;
		
		// Class methods

		/**
		 * Set unique appUserProfileCode for current user and application to avoid 
		 * preferences collisions between multiple users or applications(?).
		 * 
		 * @param appUserProfileCode
		 */
		public static function initialize(appUserProfileCode:String):void
		{
			log = Log.instance;
			if (!preferences)
			{
				preferences = new Preferences(appUserProfileCode, true);
			}
		}

		public static function clear():void
		{
			if (!preferences)
			{
				log.log(Channel.CONFIG, Preferences, "(clear) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}
			
			preferences.clear();
			log = null;
		}

		public static function getSetting(name:String):*
		{
			if (!preferences)
			{
				log.log(Channel.CONFIG, Preferences, "(getSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}
			
			return preferences.getSetting(name);
		}

		public static function setSetting(name:String, value:*):void
		{
			if (!preferences)
			{
				log.log(Channel.CONFIG, Preferences, "(setSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}
			
			preferences.setSetting(name, value);
		}

		public static function deleteSetting(name:String):void
		{
			if (!preferences)
			{
				log.log(Channel.CONFIG, Preferences, "(deleteSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}
			
			preferences.deleteSetting(name);
		}
		
		// Variables
		
		protected var log:Log;
		private var sharedObject:SharedObject;
		
		// Properties
		
		// Constructor
		
		/**
		 * 
		 * @param appUserProfileCode should be unique for application and user to avoid using same preferences in 
		 *                              same application but from different user account
		 * @param isCommonForDomain if true preferences would be common for appUserProfileCode across current domain
		 */
		public function Preferences(appUserProfileCode:String = null, isCommonForDomain:Boolean = false)
		{
			initialize(appUserProfileCode, isCommonForDomain);
		}
		
		// Methods

		/**
		 * Set unique appUserProfileCode for current user and application to avoid
		 * preferences collisions between multiple users or applications(?).
		 *
		 * @param appUserProfileCode
		 */
		public function initialize(appUserProfileCode:String, isCommonForDomain:Boolean = false):void
		{
			log = Log.instance;
			if (!sharedObject && appUserProfileCode)
			{
				try
				{
					sharedObject = SharedObject.getLocal(appUserProfileCode, "/");//isCommonForDomain ? "/" : "/" + appUserProfileCode);
				}
				catch (error:Error)
				{
					log.fatal("Error:", error);
				}
			}
		}

		public function clear():void
		{
			if (!sharedObject)
			{
				log.log(Channel.CONFIG, this, "(clear) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}

			sharedObject.clear();
			
			log = null;
		}

		public function getSetting(name:String):*
		{
			if (!sharedObject)
			{
				log.log(Channel.CONFIG, this, "(getSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}

			return sharedObject.data[name];
		}

		public function setSetting(name:String, value:*):void
		{
			if (!sharedObject)
			{
				log.log(Channel.CONFIG, this, "(setSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}

			sharedObject.data[name] = value;
			sharedObject.flush();
		}

		public function deleteSetting(name:String):void
		{
			if (!sharedObject)
			{
				log.log(Channel.CONFIG, this, "(deleteSetting) Preferences not initialized yet! Wait for AppConfig.initialize().");
				return;
			}

			if (sharedObject.data.hasOwnProperty(name))
			{
				delete sharedObject.data[name];
				sharedObject.flush();
			}
		}
		
		// Event handlers
		
	}
}
