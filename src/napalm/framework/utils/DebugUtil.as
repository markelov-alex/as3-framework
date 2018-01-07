package napalm.framework.utils
{
	import flash.system.System;
	import flash.utils.getTimer;
	
	/**
	 * DebugUtil.
	 * 
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class DebugUtil
	{
		
		// Class constants
		
		// Class variables
		
		private static var memoryByKey:Object = {};
		private static var timeByKey:Object = {};
		
		// Class methods
		
		public static function getMemoryInfo():String
		{
			var memory:String = Number(System.totalMemory / 1024 / 1024).toFixed(2) + " MB";
			return "Memory: " + memory;
		}

		public static function getMemoryChange(key:String):int
		{
			var prevMemory:int = memoryByKey[key] || 0;
			var newMemory:int = System.totalMemory;
			memoryByKey[key] = newMemory;
			return newMemory - prevMemory;
		}

		public static function getMemoryChangeBytes(key:String):String
		{
			return getMemoryChange(key) + " B";
		}

		public static function getMemoryChangeKBytes(key:String, p:int = 3):String
		{
			return (getMemoryChange(key) / 1024).toFixed(p) + " KB";
		}

		public static function getMemoryChangeMBytes(key:String, p:int = 3):String
		{
			return (getMemoryChange(key) / 1024 / 1024).toFixed(p) + " MB";
		}

		/**
		 * Using:
		 * 	DebugUtil.getTime("some");
		 * 	//... code to be counted
		 * 	trace("code executed by " + DebugUtil.getTime("some") + " msec");
		 * 
		 * @param key
		 * @return time in msec since last getTime() with same key was called
		 */
		public static function getTimeChange(key:String):int
		{
			var prevTime:int = timeByKey[key] || 0;
			var newTime:int = getTimer();
			timeByKey[key] = newTime;
			return newTime - prevTime;
		}

		public static function getTimeChangeMsec(key:String):String
		{
			return getTimeChange(key) + " msec";
		}

		public static function getTimeChangeSec(key:String, p:int = 3):String
		{
			return (getTimeChange(key) / 1000).toFixed(p) + " sec";
		}
		
	}
}
