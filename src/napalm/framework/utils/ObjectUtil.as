package napalm.framework.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	/**
	 * ObjectUtil.
	 * 
	 * Utils for Object and Dictionary as well, so we don't need DictionaryUtil. 
	 * Some methods intended for all types of objects.
	 * @author alex.panoptik@gmail.com
	 */
	public class ObjectUtil
	{
		
		// Class constants
		// Class variables
		
		// Class methods

		// Classes
		
		public static function getClassName(object:*, isStringOrClassOnly:Boolean = false):String
		{
			var result:String = object as String;
			if (result)
			{
				return result;
			}
			
			if (isStringOrClassOnly)
			{
				object = object as Class;
			}
			result = object ? getQualifiedClassName(object).split("::")[1] : null;
			return result;
		}

//		/**
//		 * Created as "object ? getQualifiedClassName(object) : null" is oftenly used in logs, 
//		 * and "ObjectUtil.fullClassName(object)" looks much better.
//		 * 
//		 * @param object
//		 * @return
//		 */
//		public static function fullClassName(object:Object):String
//		{
//			return object ? getQualifiedClassName(object) : null;
//		}
		
		// Properties

		//was copyObject
		public static function duplicate(object:Object):Object
		{
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(object);
			byteArray.position = 0;
			return byteArray.readObject();
		}

		public static function copy(source:Object, target:Object = null, isDeep:Boolean = false):Object
		{
			if (!source)
			{
				return target;
			}

			target ||= target is Array ? [] : {};  //???||= target is Array ? [] : ??

			for (var property:String in source)
			{
				target[property] = !isDeep ? source[property] : copy(source[property]);
				//trace(ObjectUtil, "(copy)",property,source[property],target[property])
			}
			return target;
		}
		
		public static function copyByPropertyNames(source:Object, target:Object, propertyNameArray:Array = null, 
		                                           propertyAliasLookup:Object = null, isTargetDynamic:Boolean = false):void
		{
			if (!target || !source)
			{
				return;
			}
			if (!propertyNameArray)
			{
				copy(source, target);
				return;
			}

			for each (var name:String in propertyNameArray)
			{
				// Get sourceValue
				var alias:String = propertyAliasLookup ? propertyAliasLookup[name] : null;
				var sourceValue:* = source.hasOwnProperty(name) ? source[name] :
						(alias && source.hasOwnProperty(alias) ? source[alias] : undefined);
				if (sourceValue === undefined)
				{
					continue;
				}

				// Apply
				if (isTargetDynamic || target.hasOwnProperty(name))
				{
					target[name] = sourceValue;
					//trace("  set name:", name, "value:", sourceValue);
				}
				else if (alias && target.hasOwnProperty(alias))
				{
					target[alias] = sourceValue;
					//trace("  set alias:", alias, "value:", sourceValue);
				}
			}
		}

		//was empty()
		public static function checkEmpty(variable:*):Boolean
		{
//?new
//			if (!variable)
//			{
//				return true;
//			}
//?was
			if (variable == null)
			{
				return true;
			}
			else if (variable is String)
			{
				return variable == "";
			}
			else if (variable is Array)
			{
				return variable.length == 0;
			}
			else if (variable is Object)
			{
				return JSON.stringify(variable).length == 2;
			}
			return false;
		}

		/**
		 * Get property value array.
		 * 
		 * @param object
		 * @return
		 */
		public static function objectToArray(object:Object, propertyNameArray:Array = null):Array
		{
			if (!object)
			{
				return [];
			}

			var result:Array = [];
			if (propertyNameArray)
			{
				for each (var propertyName:Object in propertyNameArray)
				{
					result[result.length] = object[propertyName];
				}
			}
			else
			{
				for each (var item:Object in object)
				{
					result[result.length] = item;
				}
			}

			return result;
		}

		public static function getPropertyNameArray(object:Object):Array
		{
			if (!object)
			{
				return [];
			}

			var result:Array = [];
			for (var propertyName:String in object)
			{
				result[result.length] = propertyName;
			}

			return result;
		}

		public static function getValueArrayByPropertyNames(object:Object, propertyNameArray:Array):Array
		{
			if (!object)
			{
				return null;
			}
			if (!propertyNameArray)
			{
				return [];
			}

			var result:Array = [];
			for (var i:int = 0; i < propertyNameArray.length; i++)
			{
				var propertyName:String = propertyNameArray[i];
				result[i] = object[propertyName];
			}

			return result;
		}

		public static function setUpByArray(object:Object, propertyNameArray:Array, valueArray:Array):void
		{
			if (!object || !propertyNameArray || !valueArray)
			{
				return;
			}

			var length:int = Math.min(propertyNameArray.length, valueArray.length);
			for (var i:int = 0; i < length; i++)
			{
				var propertyName:String = propertyNameArray[i];
				object[propertyName] = valueArray[i];
			}
		}

		/**
		 * See also DisplayUtil.getChildByPath().
		 * 
		 * @param object
		 * @param path
		 * @return
		 */
		public static function getPropertyByPath(object:*, path:String):*
		{
			if (!object)
			{
				return null;
			}
			if (!path)
			{
				return object;
			}

			var splitPath:Array = path.split(".");
			var child:* = object;
			for (var i:int = 0; i < splitPath.length; i++)
			{
				if (!child || !child.hasOwnProperty(splitPath[i]))
				{
					return null;
				}
				
				child = child[splitPath[i]];
			}
			return child;
		}

		public static function setToComplexObject(object:Object, key1:String, key2:String, value:*):void
		{
			if (!object || !key1 || !key2)
			{
				return;
			}
			
			if (!object[key1])
			{
				object[key1] = {};
			}
			object[key1][key2] = value;
		}

		public static function getFromComplexObject(object:Object, key1:String, key2:String):*
		{
			if (!object || !key1 || !key2 || !object[key1])
			{
				return null;
			}

			return object[key1][key2];
		}

		/**
		 * target[propertyName].push(item);
		 * 
		 * @param target
		 * @param propertyName
		 * @param item
		 * @param isUnique
		 */
		// target = {} || new Dictionary();
		public static function pushToPropertyArray(target:Object, propertyName:*, item:*, isUnique:Boolean = false):void
		{
			if (!target)
			{
				return;
			}
			
			if (!target[propertyName])
			{
				target[propertyName] = [item];
				return;
			}
			
			var array:Array = target[propertyName];
			if (isUnique && array.indexOf(item) != -1)
			{
				return;
			}
			array[array.length] = item;
		}

		/**
		 * var index:int = target[propertyName]indexOf(item);
		 * target[propertyName].splice(index, 1);
		 * 
		 * @param target
		 * @param propertyName
		 * @param item
		 */
		// target = {} || new Dictionary();
		public static function removeFromPropertyArray(target:Object, propertyName:*, item:*):void
		{
			if (!target)
			{
				return;
			}
			
			if (!target[propertyName])
			{
				return;
			}
			
			var array:Array = target[propertyName];
			var index:int = array.indexOf(item);
			if (index != -1)
			{
				array.splice(index, 1);
			}
		}

		public static function deleteByValue(object:Object, valueToDelete:*, isStrict:Boolean = true):void
		{
			for (var key:String in object)
			{
				var valueItem:* = object[key];
				if (valueItem == valueToDelete)
				{
					if (isStrict && valueItem !== valueToDelete)
					{
						continue;
					}

					object[key] = undefined;
					delete object[key];
				}
			}
		}
		
		// To String

		// Use for logs
		public static function stringify(object:Object, maxDebugLength:int = -1):String
		{
			try
			{
				if (object is Dictionary)
				{
					object = copy(object, null, true);
				}
				
				var string:String = JSON.stringify(object);
				if (maxDebugLength > -1)
				{
					string = StringUtil.cutStringInMiddle(string, maxDebugLength);
				}
				return string;
			}
			catch (error:Error)
			{
				Log.error(Channel.UTIL, ObjectUtil, "Error while stringifying json in ObjectUtil.stringify()", error);
			}
			return String(object);
		}
		
	}
}
