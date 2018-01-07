package napalm.framework.utils
{
	import com.adobe.images.JPGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Stage;
	import starling.filters.BlurFilter;
	import starling.filters.ColorMatrixFilter;
	import starling.textures.Texture;
	
	/**
	 * StarlingUtil.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class StarlingUtil
	{

		// Class constants
		// Class variables

		// Class methods

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
		
		/**
		 * Align pivot with changing displayObject's position,
		 * so visually we don't see any changes.
		 *
		 * @param displayObject
		 * @param hAlign see HAlign
		 * @param vAlign see VAlign
		 */
		public static function alignPivot(displayObject:DisplayObject, hAlign:String = "center", vAlign:String = "center"):void
		{
			var prevPivotX:Number = displayObject.pivotX;
			var prevPivotY:Number = displayObject.pivotY;

			// Align pivot
			displayObject.alignPivot(hAlign, vAlign);

			// Fix position
			displayObject.x += (displayObject.pivotX - prevPivotX) * displayObject.scaleX;
			displayObject.y += (displayObject.pivotY - prevPivotY) * displayObject.scaleY;
		}

		/**
		 * Set pivot to specified coordinates with changing displayObject's position,
		 * so visually we don't see any changes.
		 *
		 * @param displayObject
		 * @param pivotX
		 * @param pivotY
		 */
		public static function setPivot(displayObject:DisplayObject, pivotX:Number, pivotY:Number):void
		{
			var prevPivotX:Number = displayObject.pivotX;
			var prevPivotY:Number = displayObject.pivotY;

			// Set pivot
			displayObject.pivotX = pivotX;
			displayObject.pivotY = pivotY;

			// Fix position
			displayObject.x += (pivotX - prevPivotX) * displayObject.scaleX;
			displayObject.y += (pivotY - prevPivotY) * displayObject.scaleY;
		}

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

		// ScreenShot
		
		public static function getScreenShot(starling:Starling = null, scale:Number = 1):BitmapData
		{
			var result:BitmapData;
			try
			{
				starling ||= Starling.current;
				if (!starling)
				{
					return null;
				}

				// Draw Starling
				var stageWidth:int = starling.nativeStage.stageWidth;
				var stageHeight:int = starling.nativeStage.stageHeight;

				var renderSupport:RenderSupport = new RenderSupport();
				RenderSupport.clear();
				renderSupport.setProjectionMatrix(0, 0, stageWidth, stageHeight);
				starling.root.render(renderSupport, 1.0);
				renderSupport.finishQuadBatch();

				var bitmapData:BitmapData = new BitmapData(stageWidth, stageHeight, false);

				Starling.context.drawToBitmapData(bitmapData);

				result = new BitmapData(stageWidth * scale, stageHeight * scale, false);
				result.draw(new Bitmap(bitmapData), new Matrix(scale, 0, 0, scale));
				bitmapData.dispose();

				// Draw Flash
				result.draw(starling.nativeStage);
			}
			catch (error:Error)
			{
				Log.error(Channel.UTIL, "[StarlingScreenShotSource] Error taking ScreenShot", error);
			}
			return result;
		}

		public static function getScreenShotBase64(starling:Starling = null, scale:Number = 1, blur:int = 0, quality:int = 80):String
		{
			var bitmapData:BitmapData = getScreenShot(starling, scale);

			if (blur)
			{
				bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), new flash.filters.BlurFilter(blur, blur, 1));
			}

			var jpgEncoder:JPGEncoder = new JPGEncoder(quality);
			var byteArray:ByteArray = jpgEncoder.encode(bitmapData);
			var dataString:String = Base64Fast.encode(byteArray);

			bitmapData.dispose();
			byteArray.clear();

			return dataString;
		}

		public static function getBitmapData(sprite:DisplayObject = null):BitmapData
		{
			if (!sprite)
			{
				sprite = Starling.current.root;
			}

			var resultRect:Rectangle = new Rectangle();
			sprite.getBounds(sprite, resultRect);

			var context:Context3D = Starling.context;
			var contentScaleFactor:Number = Starling.contentScaleFactor;

			var nativeWidth:Number = sprite.stage.stageWidth * contentScaleFactor;//was Starling.current.
			var nativeHeight:Number = sprite.stage.stageHeight * contentScaleFactor;//was Starling.current.

			var renderSupport:RenderSupport = new RenderSupport();
			RenderSupport.clear();
			renderSupport.setProjectionMatrix(0, 0, nativeWidth / contentScaleFactor, nativeHeight / contentScaleFactor);
			renderSupport.applyBlendMode(true);

			if (sprite.parent)
			{
				renderSupport.transformMatrix(sprite.parent);
			}
			renderSupport.pushMatrix();
			renderSupport.blendMode = sprite.blendMode;
			renderSupport.transformMatrix(sprite);
			sprite.render(renderSupport, 1.0);
			renderSupport.popMatrix();
			renderSupport.finishQuadBatch();

			var bitmapData:BitmapData = new BitmapData(nativeWidth, nativeHeight, true, 0x00000000);
			context.drawToBitmapData(bitmapData);

			var result:BitmapData = new BitmapData(nativeWidth, nativeHeight, true, 0);
			var cropArea:Rectangle = new Rectangle(0, 0, nativeWidth, nativeHeight); //(Config.SCREEN_WIDTH - sprite.width) / 2, 0, sprite.width, sprite.height);
			result.draw(bitmapData, null, null, null, cropArea, true);

			return result;
		}

//?		public static function copyToBitmap(disp:DisplayObject, scale:Number = 1.0):BitmapData
//		{
//			var rc:Rectangle = new Rectangle();
//			disp.getBounds(disp, rc);
//
//			var stage:Stage = Starling.current.stage;
//			var rs:RenderSupport = new RenderSupport();
//
//			rs.clear();
//			rs.scaleMatrix(scale, scale);
//			rs.setOrthographicProjection(0, 0, stage.stageWidth, stage.stageHeight);
//			rs.translateMatrix(-rc.x, -rc.y); // move to 0,0
//			disp.render(rs, 1.0);
//			rs.finishQuadBatch();
//
//			var outBmp:BitmapData = new BitmapData(rc.width * scale, rc.height * scale, true);
//			Starling.context.drawToBitmapData(outBmp);
//
//			return outBmp;
//		}

		// Children

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

//		public static function makeAllContainersTouchable(displayContainer:DisplayObjectContainer):void
//		{
//			if (!displayContainer)
//			{
//				return;
//			}
//
//			displayContainer.touchable = true;
//
//			var numChildren:int = displayContainer.numChildren;
//			for (var i:int = 0; i < numChildren; i++)
//			{
//				var childContainer:DisplayObjectContainer = displayContainer.getChildAt(i) as DisplayObjectContainer;
//				if (childContainer)
//				{
//					makeAllContainersTouchable(childContainer);
//				}
//			}
//		}
		
		// Filter

		public static function applyGreyFilter(displayObject:DisplayObject):void
		{
			if (!displayObject)
			{
				return;
			}

			var filter:ColorMatrixFilter = new ColorMatrixFilter();
			filter.adjustSaturation(-1);
			displayObject.filter = filter;
		}

		public static function applyGlowFilter(displayObject:DisplayObject, color:int = 0x78bb98):void
		{
			if (!displayObject)
			{
				return;
			}

			var filter:starling.filters.BlurFilter = starling.filters.BlurFilter.createGlow(color, 1, 5, 1);
			filter.blurX = 10;
			filter.blurY = 10;
			displayObject.filter = filter;
		}
		
		// Debug

		public static function traceParentsVisible(target:DisplayObject):String
		{
			var result:String = "";
			var delim:String = " > ";
			var isTotalVisible:Boolean = target && target.stage;
			while (target)
			{
				result += target + ":" + target.visible + ":" + target.alpha.toFixed(2) + delim;
				if (!target.visible || target.alpha < 0.1)
				{
					isTotalVisible = false;
				}

				target = target.parent;
			}
			result += target ? "stage:" + target.stage : "null";
			result += " isTotalVisible:" + isTotalVisible;
			return result;
		}

		public static function traceVisible(object:DisplayObject):String
		{
			return "stg:" + object.stage + " v:" + object.visible + " a:" + object.alpha +
					" w:" + object.width + " h:" + object.height + " x:" + object.x + " y:" + object.y;
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
					result += (i == 0 ? "" : ", ") +  traceChildren(container.getChildAt(i), callback);
				}
			}
			var callbackResult:String = callback != null ? " {" + callback(object) + "}" : "";
			return "[\"" + (object.name || object) + callbackResult + "\"" + (result ? " ch: " + result + "" : "") + "]";
		}
		
		// Draw

		public static function drawCircle():Image
		{
			var sprite:flash.display.Sprite = new flash.display.Sprite();
			var color:uint = 0xFF0000;//Math.random() * 0xFFFFFF;
			var radius:uint = 20;

			sprite.graphics.beginFill(color);
			sprite.graphics.drawCircle(radius, radius, radius);
			sprite.graphics.endFill();

			var bitmapData:BitmapData = new BitmapData(radius * 2, radius * 2, true, 0x00000000);
			bitmapData.draw(sprite);

			var texture:Texture = Texture.fromBitmapData(bitmapData);
			var image:Image = new Image(texture);
			image.alignPivot();
			return image;
		}

		public static function drawRect(rect:Rectangle):Image
		{
			if (!rect)
			{
				return null;
			}

			var sprite:flash.display.Sprite = new flash.display.Sprite();
			var color:uint = 0xFF0000;//Math.random() * 0xFFFFFF;
			var radius:uint = 20;

//			sprite.graphics.beginFill(color);
			sprite.graphics.lineStyle(2, color);
			sprite.graphics.drawRect(0, 0, rect.width, rect.height);
//			sprite.graphics.endFill();

			var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
			bitmapData.draw(sprite);

			var texture:Texture = Texture.fromBitmapData(bitmapData);
			var image:Image = new Image(texture);
			image.x = rect.x;
			image.y = rect.y;
			return image;
		}

	}
}
