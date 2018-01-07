package napalm.framework.utils
{

	/**
	 * FunctionUtil.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class FunctionUtil
	{

		// Class constants
		// Class variables
		
		// Class methods

		/**
		 * Prevents arguments count mismatching.
		 * 
		 * @param callback
		 * @param args
		 * @return
		 */
		public static function call(callback:Function, args:Array = null):*
		{
			if (callback == null)
			{
				return null;
			}
			
			if (args && callback.length < args.length)
			{
				args.length = callback.length;
			}
			
			return callback.apply(null, args);
		}

	}
}
