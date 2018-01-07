package napalm.framework.utils
{

	/**
	 * MathUtil.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class MathUtil
	{

		// Class constants

		// rad = RAD_2_DEG * deg
		public static const RAD_2_DEG:Number = 180 / Math.PI;
		// deg = DEG_2_RAD * rad
		public static const DEG_2_RAD:Number = Math.PI / 180;

		public static const DOUBLE_PI:Number = Math.PI * 2;

		// Class variables

		// Class methods
		
		/**
		 * getRandomIn(3) returns 0 or 1 of 2
		 *
		 * @param end excluded
		 * @return
		 */
		public static function getRandom(end:Number):int
		{
			if (end <= 0)
			{
				return end;
			}
			return Math.floor(Math.random() * end);
		}
		
		/**
		 * getRandomIn(2, 4) returns 2 or 3
		 * was getRandom(min:Number, max:Number):int
		 * 
		 * @param start included
		 * @param end excluded
		 * @return
		 */
		public static function getRandomIn(start:Number, end:Number):int
		{
			if (end == start)
			{
				return end;
			}
			//??Math.round?
			return Math.floor(Math.random() * (end - start) + start);
		}

		[Inline]
		public static function clamp(value:Number, min:Number, max:Number):Number
		{
			return value >= min ? (value <= max ? value : max) : min;
		}

		public static function round(value:Number, accuracy:int):Number
		{
			if (accuracy < 0)
			{
				accuracy = -accuracy;
			}
			var accur:int = Math.pow(10, accuracy);
			return Math.round(value * accur) / accur;
		}

	}
}
