package napalm.framework.utils
{

	/**
	 * ArrayUtil.
	 * 
	 * Utils for Array and Vector.
	 * (Any method could be transformed for Vector: array:Array -> array:*)
	 * @author alex.panoptik@gmail.com
	 */
	public class ArrayUtil
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods

		// Create
		
		public static function toArray(object:Object):Array
		{
			if (!object)
			{
				return null;
			}

			if (object is Array)
			{
				return object as Array;
			}

			var result:Array = [];

			for each (var item:* in object)
			{
				result[result.length] = item;
			}

			return result;
		}

		// ["a", null, 5] -> [0, 1, 2]
		public static function createIndexArray(array:Array):Array
		{
			if (!array)
			{
				return null;
			}

			var result:Array = [];
			var length:int = array.length;
			for (var i:int = 0; i < length; i++)
			{
				result[i] = i;
			}
			return result;
		}

		//was skipNulls
		public static function excludeNulls(array:Array):Array
		{
			if (!array)
			{
				return array;
			}

			var result:Array = [];

			for (var i:int = 0; i < array.length; i++)
			{
				if (array[i] !== null)
				{
					result[result.length] = array[i];
				}
			}

			return result;
		}

		public static function excludedEmpty(array:Array):Array
		{
			if (!array)
			{
				return array;
			}

			var result:Array = [];
//--			for (var i:int = array.length - 1; i >= 0; i--)
			for (var i:int = 0; i < array.length; i++)
			{
				if (array[i])
				{
					result[result.length] = array[i];
				}
			}

			return result;
		}

		// Manipulate

		/**
		 * Shuffle array without creating a copy.
		 *
		 * @param array
		 * @param iterationCount
		 */
		public static function shuffled(array:Array, iterationCount:int = 1):void
		{
			for (var i:int = 0; i < iterationCount; i++)
			{
				var length:int = array.length;

				for (var j:int = 0; j < array.length; j++)
				{
					var index1:int = Math.random() * length;
					var index2:int = Math.random() * length;
					var temp:* = array[index1];
					array[index1] = array[index2];
					array[index2] = temp;
				}
			}
		}

		// Add/Remove

		public static function pushUnique(array:Array, item:*):void
		{
			if (!array)
			{
				return;
			}

			var index:int = array.indexOf(item);
			if (index == -1)
			{
				array[array.length] = item;
			}
		}

		public static function removeItemByProperty(array:Array, propertyName:String, value:*, isStrict:Boolean = false):*
		{
			if (!array || !propertyName)
			{
				return null;
			}

			for (var i:int = array.length - 1; i >= 0; i--)
			{
				var data:Object = array[i];

				if (!data || !data.hasOwnProperty(propertyName))
				{
					continue;
				}

				var property:* = data[propertyName];

				if ((!isStrict && property == value) || (isStrict && property === value))
				{
					var result:* = array[i];
					array.splice(i, 1);
					return result;
				}
			}

			return null;
		}

		public static function removeItem(array:Array, item:*):int
		{
			if (!array)
			{
				return -1;
			}

			var index:int = array.indexOf(item);
			if (index != -1)
			{
				array.splice(index, 1);
			}
			return index;
		}
		
		// Get
		
		/**
		 * @param source (Array|Vector)
		 */
		public static function getSubArrayByPropertyName(source:*, propertyName:String):Array
		{
			if (!source || !propertyName)
			{
				return [];
			}

			var result:Array = [];

			for (var i:int = 0; i < source.length; i++)
			{
				var object:Object = source[i];
				result[result.length] = object && object.hasOwnProperty(propertyName) ? object[propertyName] : null;
			}
			return result;
		}

		// getItemByProperty[{a: 2, b: 1}, {a: 3, b: 5}], "a", 2) => {a: 2, b: 1}
		// getItemByProperty[{a: 2, b: 1}, {a: 3, b: 5}], "a", 4) => null
		public static function getItemByProperty(array:Array, propertyName:String, propertyValue:*):*
		{
			if (!array || !propertyName)
			{
				return [];
			}

			for (var i:int = 0; i < array.length; i++)
			{
				var object:Object = array[i];
				if (object && object.hasOwnProperty(propertyName) && object[propertyName] == propertyValue)
				{
					return object;
				}
			}
			return null;
		}

//		public static function getIndexByProperty(array:Array, propertyName:String, value:*, isStrict:Boolean = false):int
//		{
//			if (!array || !propertyName)
//			{
//				return -1;
//			}
//
//			for (var i:int = 0; i < array.length; i++)
//			{
//				var data:Object = array[i];
//
//				if (!data || !data.hasOwnProperty(propertyName))
//				{
//					continue;
//				}
//
//				var property:* = data[propertyName];
//
//				if ((!isStrict && property == value) || (isStrict && property === value))
//				{
//					return i;
//				}
//			}
//
//			return -1;
//		}

		public static function getNearestNullIndex(array:Array, startIndex:int = 0):int
		{
			if (!array)
			{
				return -1;
			}

			if (startIndex < 0)
			{
				startIndex = 0;
			}

			var length:int = array.length;

			for (var i:int = startIndex, j:int = i; i < length || j >= 0; i++, j--)
			{
				if (i < length && array[i] == null)
				{
					return i;
				}
				else if (j >= 0 && array[j] == null)
				{
					return j;
				}
			}

			return -1;
		}

		public static function notNullItemsCount(array:Array):int
		{
			if (!array)
			{
				return 0;
			}

			var result:int = 0;

			for (var i:int = 0; i < array.length; i++)
			{
				if (array[i] != null)
				{
					result++;
				}
			}

			return result;
		}

		public static function checkEqual(array1:Array, array2:Array, isStrictMode:Boolean = false):Boolean
		{
			if (!array1 && !array2)
			{
				return true;
			}
			if (!array1 || !array2 || array1.length != array2.length)
			{
				return false;
			}

			var length:int = array1.length;
			for (var i:int = 0; i < length; i++)
			{
				if ((!isStrictMode && array1[i] != array2[i]) || (isStrictMode && array1[i] !== array2[i]))
				{
					return false;
				}
			}
			return true;
		}

	}
}
