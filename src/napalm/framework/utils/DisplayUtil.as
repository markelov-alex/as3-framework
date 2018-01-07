package napalm.framework.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * DisplayUtil.
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class DisplayUtil
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods
		
		// MovieClip
		
		public static function stopAll(container:DisplayObjectContainer):void
		{
			if (!container)
			{
				return;
			}
			
			var movieClip:MovieClip = container as MovieClip;
			if (movieClip)
			{
				movieClip.stop();
			}

			for (var i:int = 0; i < container.numChildren; i++)
			{
				var displayContainer:DisplayObjectContainer = container.getChildAt(i) as DisplayObjectContainer;
				if (displayContainer)
				{
					stopAll(displayContainer);
				}
			}
		}
		
		// Size

		public static function fitTo(source:DisplayObject, target:DisplayObject, 
		                             isKeepRatio:Boolean = true, isFitMaxSide:Boolean = true):void
		{
			if (!source || !target)
			{
				return;
			}

			var stage:Stage = target as Stage;
			var targetWidth:Number = stage ? stage.stageWidth : target.width;
			var targetHeight:Number = stage ? stage.stageHeight : target.height;
			
			fitToSize(source, targetWidth, targetHeight, isKeepRatio, isFitMaxSide);
		}

		public static function fitToSize(source:DisplayObject, targetWidth:Number, targetHeight:Number,
		                             isKeepRatio:Boolean = true, isFitMaxSide:Boolean = true):void
		{
			if (!source)
			{
				return;
			}
			
			if (isKeepRatio)
			{
				source.scaleX = source.scaleY = 1;
				var isWidthOutOfTarget:Boolean = targetHeight / source.height > targetWidth / source.width;
				if (!isFitMaxSide)
				{
					isWidthOutOfTarget = !isWidthOutOfTarget;
				}
				if (isWidthOutOfTarget)
				{
					source.width = targetWidth;
					source.scaleY = source.scaleX;
				}
				else
				{
					source.height = targetHeight;
					source.scaleX = source.scaleY;
				}
			}
			else
			{
				source.width = targetWidth;
				source.height = targetHeight;
			}
		}

		// Pivot

		public static function getCenter(source:DisplayObject, isLocal:Boolean = false, isLocalScale:Boolean = true):Point
		{
			if (!source)
			{
				return null;
			}

			var rect:Rectangle = source.getBounds(isLocal ? source : source.parent);
			var result:Point = new Point(rect.left + rect.width / 2, rect.top + rect.height / 2);
			if (isLocal && isLocalScale)
			{
				result.x *= source.scaleX;
				result.y *= source.scaleY;
			}
			return result;
		}

		// Children

		/**
		 * See also ObjectUtil.getPropertyByPath()
		 *
		 * @param object
		 * @param path
		 * @return
		 */
		public static function getChildByPath(container:DisplayObject, path:String):DisplayObject
		{
			if (!container)
			{
				return null;
			}
			if (!path)
			{
				return container;
			}

			var splitPath:Array = path.split(".");
			var length:int = splitPath.length;

			var child:DisplayObject = container;
			for (var i:int = 0; i < length; i++)
			{
				var childContainer:DisplayObjectContainer = child as DisplayObjectContainer;
				child = childContainer ? childContainer.getChildByName(splitPath[i]) : null;
				if (!child)
				{
					return null; //Throw error
				}
			}
			return child;
		}

		public static function getChildrenArray(container:DisplayObjectContainer):Array
		{
			if (!container)
			{
				return [];
			}

			var result:Array = [];
			var numChildren:int = container.numChildren;
			for (var i:int = 0; i < numChildren; i++)
			{
				result[i] = container.getChildAt(i);
			}
			return result;

		}

		public static function getChildByNameContaining(container:DisplayObjectContainer, namePart:String,
		                                                startChild:DisplayObject = null, useClassName:Boolean = false,
		                                                isCaseSensitive:Boolean = false):DisplayObject
		{
			if (!container || !container.numChildren || !namePart)
			{
				return null;
			}

			var result:DisplayObject = null;
			var numChildren:int = container.numChildren;
			var startIndex:int = startChild ? container.getChildIndex(startChild) : -1;
			for (var i:int = startIndex == -1 ? 0 : startIndex + 1; i < numChildren; i++)//; trace("i < numChildren", i < numChildren), i < numChildren; i++)//
			{
				var child:DisplayObject = container.getChildAt(i);
				var childName:String = child.name;
				var childClassName:String = useClassName ? getQualifiedClassName(child) : "";

				if (!isCaseSensitive)
				{
					namePart = namePart.toLowerCase();
					childName = childName.toLowerCase();
					childClassName = childClassName.toLowerCase();
				}

				if (childName.indexOf(namePart) != -1 || (useClassName && childClassName.indexOf(namePart) != -1))
				{
					result = child;
					break;
				}
			}

			return result;
		}

		public static function getChildrenByNameContaining(container:DisplayObjectContainer, namePart:String,
		                                                   useClassName:Boolean = false, isCaseSensitive:Boolean = false):Array
		{
			if (!container || !container.numChildren || !namePart)
			{
				return [];
			}

			var result:Array = [];
			var resultItem:DisplayObject = null;
			while (resultItem = getChildByNameContaining(container, namePart, resultItem, useClassName, isCaseSensitive))
			{
				result[result.length] = resultItem;
			}

			return result;
		}

		/**
		 * Remove all children from "container" and add them into "container.parent".
		 * Visually nothing is changed (visual position and order will be saved).
		 */
		public static function moveAllChildrenToParent(container:DisplayObjectContainer, isReverseResult:Boolean = true):Array
		{
			if (!container)
			{
				return null;
			}

			var numChildren:int = container.numChildren;
			var parent:DisplayObjectContainer = container.parent;

			if (!numChildren || !parent)
			{
				return [];
			}

			var result:Array = [];
			var index:int = parent.getChildIndex(container);
			for (var i:int = numChildren - 1; i >= 0; i--)
			{
				var child:DisplayObject = container.getChildAt(i);

				// Move
				parent.addChildAt(child, index + 1);

				// Keep same visual
				child.x += container.x;
				child.y += container.y;
				//?+
				child.width *= container.scaleX;//child.scaleX???
				child.height *= container.scaleY;

				//-doChild.rotation += container.rotation;

				// result
				result[result.length] = child;
			}

			if (!isReverseResult)
			{
				result.reverse();
			}

			return result;
		}
		
		// Debug

		public static function traceVisible(object:DisplayObject):String
		{
			return "stg:" + object.stage + " v:" + object.visible + " a:" + object.alpha + 
					" w:" + object.width + " h:" + object.height;
		}

		public static function traceChildren(object:DisplayObject, callback:Function = null):String
		{
			if (!object)
			{
				return "";
			}
			var result:String = "";
			var container:DisplayObjectContainer = object as DisplayObjectContainer;
			if (container)
			{
				var numChildren:int = container.numChildren;
				for (var i:int = 0; i < numChildren; i++)
				{
					result += (i == 0 ? "" : ", ") +  traceChildren(container.getChildAt(i));
				}
			}
			var callbackResult:String = callback != null ? " " + callback(object) : "";
			return "[\"" + object.name + callbackResult + "\"" + (result ? ": " + result + "" : "") + "]";
		}

		public static function drawCircle(radius:Number = 20, target:Sprite = null,
		                                    colorFill:int = -1, colorLine:int = -1):Sprite
		{
			target ||= new Sprite();

			var graphics:Graphics = target.graphics;
			if (colorFill != -1)
			{
				graphics.beginFill(colorFill >= 0 ? colorFill : 0xFF0000);
			}
			graphics.lineStyle(2, colorLine >= 0 ? colorLine : 0x000000);
			graphics.drawCircle(0, 0, radius);//(radius, radius, radius);
			graphics.endFill();
			return target;
		}

		public static function drawRect(rect:Rectangle, target:Sprite = null, colorFill:int = -1,
		                                colorLine:int = -1, alphaFill:Number = 1, line:int = 2):Sprite
		                                
		{
			if (!rect)
			{
				return null;
			}

			target ||= new Sprite();

			var graphics:Graphics = target.graphics;
			if (colorFill != -1)
			{
				graphics.beginFill(colorFill >= 0 ? colorFill : 0x6699ff, alphaFill);
			}
			if (line > 0)
			{
				graphics.lineStyle(line, colorLine >= 0 ? colorLine : 0x000000);
			}
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
			return target;
		}
		
	}
}
