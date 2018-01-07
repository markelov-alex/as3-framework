package napalm.framework.utils
{

	/**
	 * StringUtil.
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class StringUtil
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods

		public static function fitToMinLength(string:String, minLength:int = 30, isAlignLeft:Boolean = true):String
		{
			var spacesString:String = "";
			var spacesCount:int = string ? minLength - string.length : 0;
			for (var i:int = 0; i < spacesCount; i++)
			{
				spacesString += " ";
			}
			
			if (isAlignLeft)
			{
				string += spacesString;
			}
			else
			{
				string = spacesString + string;
			}
			return string;
		}
		
		//сокращает длинные слова, добавляет "..." (оченьдлинноеслово>оченьдли...)
		//was limitStringLength
		public static function cutStringAtEnd(string:String, maxLength:int):String
		{
			if (string.length > maxLength)
			{
				string = string.substr(0, maxLength - 3) + "...";
				// "-3" is for "..."
			}
			return string;
		}
		
		//was limitDebugString
		public static function cutStringInMiddle(string:String, maxLength:int):String
		{
			if (!string)
			{
				return string;
			}

			var length:int = string.length;
			if (length > maxLength)
			{
				var countAfter:int = 100;
				var countBefore:int = Math.max(countAfter, maxLength - 100 - countAfter);
				var countSliced:int = length - countBefore - countAfter;
				string = string.substr(0, countBefore) + " ..(" + countSliced + ").. " + string.substr(length - countAfter, countAfter);
			}
			return string;
		}

		/**
		 * StringUtil.substitute("{0}+{1}={2}", 5, 7, 12);// "5+7=12"
		 */
		public static function substitute(string:String, ...replaces):String
		{
			if (!string || !replaces || !replaces.length)
			{
				return string;
			}

			// Replace all of the parameters in the msg string.
			var replaceCount:int = replaces.length;
			var replaceArray:Array = replaces as Array;
			if (replaceCount == 1 && replaces[0] is Array)
			{
				replaceArray = replaces[0] as Array;
				replaceCount = replaceArray.length;
			}

			for (var i:int = 0; i < replaceCount; i++)
			{
				string = string.replace(new RegExp("\\{" + i + "\\}", "g"), replaceArray[i]);
			}

			return string;
		}

		public static function substituteByLookup(string:String, replacesLookup:Object):String
		{
			if (!string || !replacesLookup || string.indexOf("{") == -1)
			{
				return string;
			}

			// Replace all of the parameters in the msg string.
			for (var key:String in replacesLookup)
			{
				while (string.indexOf("{" + key + "}") != -1)
				{
					string = string.replace("{" + key + "}", replacesLookup[key]);
				}
			}

			return string;
		}

		public static function getSuffix(string:String, delim:String = "_"):String
		{
			if (!string)
			{
				return string;
			}
			
			var partArray:Array = string.split(delim);
			return partArray[partArray.length - 1];
		}

		/**
		 * breakString("abcdefghijk", 2) => ["ab","cd","ef","gh","ij","k"]
		 * breakString("abcdefghijk", 0) => ["abcdefghijk"]
		 * breakString("abcdefghijk", 30) => ["abcdefghijk"]
		 */
		public static function breakStringApart(value:String, partLength:int = 1):Array
		{
			if (!value)
			{
				return [];
			}
			if (partLength <= 0)
			{
				return [value];
			}

			var result:Array = [];
			var index:int = 0;
			var i:int = 0;
			while (index < value.length)
			{
				var item:String = value.substr(index, partLength);
				result[i] = item;

				index += partLength;
				i++;
			}
			return result;
		}

	}
}
