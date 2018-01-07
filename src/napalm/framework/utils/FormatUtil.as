package napalm.framework.utils
{

	/**
	 * FormatUtil.
	 * 
	 * Format strings, money, other strings to display in text fields.
	 * @author alex.panoptik@gmail.com
	 */
	public class FormatUtil
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods

		/**
		 * fitMinLengthWithZeros(3, 2); -> "03"
		 * 
		 * @param number	(int|Number|String)
		 * @param minLength
		 * @return
		 */
		public static function fitMinLengthWithZeros(number:*, minLength:int):String
		{
			var result:String = String(number);
			while (result.length < minLength)
			{
				result = "0" + result;
			}
			return result;
		}
		
	}
}
