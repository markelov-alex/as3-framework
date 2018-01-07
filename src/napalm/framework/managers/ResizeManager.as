package napalm.framework.managers
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	
	import starling.core.Starling;
	
	[Event(name="resize", type="starling.events.Event")]
	[Event(name="fullScreenChange", type="starling.events.Event")]
	[Event(name="orientationChange", type="starling.events.Event")]
	[Event(name="qualityTypeChange", type="starling.events.Event")]

	/**
	 * ResizeManager.
	 *
	 * Listen for RESIZE and use properties (appWidth/Height, appScaleX/Y)
	 * to make your GUI adaptive.
	 *
	 * Use appWidth/Height instead of stageWidth/Height - these params are
	 * unequal if multiple app instances loaded.
	 * @author alex.panoptik@gmail.com
	 */
	public class ResizeManager extends BaseManager
	{

		// Class constants

		public static const RESIZE:String = "resize";
		public static const FULL_SCREEN_CHANGE:String = "fullScreenChange";
		public static const ORIENTATION_CHANGE:String = "orientationChange";
		public static const QUALITY_TYPE_CHANGE:String = "qualityTypeChange";

		// Class variables

		// Class properties

		// Class methods

//		public static function convertFontSize(size:Number):Number
//		{
//			switch (Device.DPI)
//			{
//				case 160:
//					return size * 1.6;
//				case 240:
//					return size * 1.3;
//				case 320:
//					return size * 0.9;
//				case 480:
//					return size * 0.7;
//				case 640:
//					return size * 0.6;
//			}
//			// For DPI Over 640
//			return size * 0.5;
//		}

		// Variables

		// (Set in your overridden Main.initializeManagers)
		//public var ;

		private var stage:Stage;
		private var starlingArray:Array;

		private var explicitAppWidth:int = -1;
		private var explicitAppHeight:int = -1;
		private var prevAppWidth:int;
		private var prevAppHeight:int;
		private var prevQualityType:String;

		// Properties

//		private var _isFitAppToStage:Boolean = true;
//		public function get isFitAppToStage():Boolean
//		{
//			return _isFitAppToStage;
//		}
//		
//		public function set isFitAppToStage(value:Boolean):void
//		{
//			if (_isFitAppToStage === value)
//			{
//				return;
//			}
//			
//			_isFitAppToStage = value;
//			
//			update();
//		}

		private var _isFullScreen:Boolean = false;
		public function get isFullScreen():Boolean
		{
			return _isFullScreen;
		}

		public function set isFullScreen(value:Boolean):void
		{
			if (_isFullScreen == value)
			{
				return;
			}

			_isFullScreen = value;

			log.log(Channel.RESIZE, this, "(set-isFullScreen) prev:", isFullScreen, "new:", value);
			stage.displayState = value ? StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
			// (Don't dispatch, wait for update())
		}

		public function get isFullScreenAvailable():Boolean
		{
			return stage ? stage.allowsFullScreen : false;//TODO add device restrictions
		}

		private var _isPortraitOrientation:Boolean = false;
		public function get isPortraitOrientation():Boolean
		{
			return _isPortraitOrientation;
		}

		public function get appQualityCoeff():Number
		{
			return Device.qualityCoeff;
			//todo?
//			if (isFixedQualityCoeff)
//			{
//				return _qualityCoeff;
//			}
//
//			return Math.min(appWidth, appHeight) <= Device.APP_SD_HEIGHT ? Device.SD_QUALITY_COEFF : Device.HD_QUALITY_COEFF;
		}

		private var _initialHDWidth:Number;
		public function get initialHDWidth():Number
		{
			return _initialHDWidth;
		}

		private var _initialHDHeight:Number;
		public function get initialHDHeight():Number
		{
			return _initialHDHeight;
		}

		/**
		 * Initial app size the graphics was prepared for.
		 * For each user's screen graphics will be scaled to appWidth/Height by appScale.
		 */
		private var _initialAppWidth:int;
		public function get initialAppWidth():int
		{
			return _initialAppWidth;
		}

		private var _initialAppHeight:int;
		public function get initialAppHeight():int
		{
			return _initialAppHeight;
		}

		private var _stageWidth:int;
		/**
		 * Use appWidth in your app.
		 */
		public function get stageWidth():int
		{
			return _stageWidth;
		}

		private var _stageHeight:int;
		/**
		 * Use appHeight in your app.
		 */
		public function get stageHeight():int
		{
			return _stageHeight;
		}

		/**
		 * appWidth/Height size of visible application area.
		 * By default same as stageWidth/Height (if only one application loaded by the launcher).
		 */
		private var _appWidth:int;
		public function get appWidth():int
		{
			return _appWidth;
		}

		private var _appHeight:int;
		public function get appHeight():int
		{
			return _appHeight;
		}

//?-		private var _appLeft:int;
//		public function get appLeft():int
//		{
//			return int((_stageWidth - _initialAppWidth) / 2);
//			//return _initialAppLeft;//todo with invalidation
//		}
//
//		private var _appTop:int;
//		public function get appTop():int
//		{
//			return int((_stageHeight - _initialAppHeight) / 2);
//			//return _initialAppTop;
//		}

		private var _appScaleX:Number = 1;
		public function get appScaleX():Number
		{
			return _appScaleX;
		}

		private var _appScaleY:Number = 1;
		public function get appScaleY():Number
		{
			return _appScaleY;
		}

		private var _appScale:Number = 1;
		/**
		 * Scale to fit application GUI to current app size.
		 * It's min of appScaleX and appScaleY.
		 */
		public function get appScale():Number
		{
			return _appScale;
		}

		// Constructor

		public function ResizeManager()
		{
		}

		// Methods

		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);
			log.log(Channel.RESIZE, this, "(initialize) <update,listen-RESIZE> stageWidth/Height(0,0):", stageWidth, stageHeight, "appWidth/Height(0,0):", initialAppWidth, initialAppHeight, "isFullScreen:", isFullScreen, "appQualityCoeff:", appQualityCoeff);

			stage = systemManager.stage;
			starlingArray = systemManager.starlingArray;

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			setInitialHDAssetsSize(Device.INITIAL_HD_WIDTH, Device.INITIAL_HD_HEIGHT);

			update();

			// Listeners
			stage.addEventListener(Event.RESIZE, stage_resizeHandler);
			stage.addEventListener(Event.FULLSCREEN, stage_fullscreenHandler);
		}

		override public function dispose():void
		{
			log.log(Channel.RESIZE, this, "(dispose) stage,starlingArray:", stage, starlingArray);

			// Listeners
			stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			stage.removeEventListener(Event.FULLSCREEN, stage_fullscreenHandler);

			stage = null;
			starlingArray = null;

			//explicitAppWidth = -1;
			//explicitAppHeight = -1;
			//prevAppWidth = 0;
			//prevAppHeight = 0;
			//prevQualityType = null;

			//_initialHDWidth = 0;
			//_initialHDHeight = 0;
			//_initialAppWidth = 0;
			//_initialAppHeight = 0;
			//_stageWidth = 0;
			//_stageHeight = 0;
			//_appWidth = 0;
			//_appHeight = 0;
			//_appScaleX = 1;
			//_appScaleY = 1;
			//_appScale = 1;

			super.dispose();
		}

		public function setInitialHDAssetsSize(initialHDWidth:Number, initialHDHeight:Number):void
		{
			_initialHDWidth = initialHDWidth;
			_initialHDHeight = initialHDHeight;

			_initialAppWidth = initialHDWidth * appQualityCoeff;
			_initialAppHeight = initialHDHeight * appQualityCoeff;

			update();
		}

		/**
		 * Use to resize multiple app instances.
		 * Set isFitAppSizeToStage=false to enable.
		 *
		 * @param appWidth set -1 to fit stage.stageWidth
		 * @param appHeight set -1 to fit stage.stageHeight
		 */
		public function setAppSize(appWidth:int, appHeight:int):void
		{
//			if (isFitAppToStage)
//			{
//				return;
//			}
//
//			prevAppWidth = _appWidth;
//			prevAppHeight = _appHeight;
//
//			_appWidth = appWidth;
//			_appHeight = appHeight;
//			
//			update();

			explicitAppWidth = appWidth;
			explicitAppHeight = appHeight;

			update();
		}

		public function toggleFullScreen():void
		{
			log.log(Channel.RESIZE, this, "(toggleFullScreen) prev-isFullScreen:", isFullScreen);
			isFullScreen = !isFullScreen;
		}

		private function update():void
		{
			// Update stageWidth/Height, appScale
			if (Device.isMobile)
			{
				_stageWidth = stage.fullScreenWidth;
				_stageHeight = stage.fullScreenHeight;
			}
			else
			{
				_stageWidth = stage.stageWidth;
				_stageHeight = stage.stageHeight;
			}

//			if (isFitAppToStage)
//			{
//				prevAppWidth = _appWidth;
//				prevAppHeight = _appHeight;
//
//				_appWidth = _stageWidth;
//				_appHeight = _stageHeight;
//			}
			prevAppWidth = _appWidth;
			prevAppHeight = _appHeight;
			_appWidth = explicitAppWidth > -1 ? explicitAppWidth : _stageWidth;
			_appHeight = explicitAppHeight > -1 ? explicitAppHeight : _stageHeight;

			var isPortraitModePrev:Boolean = _isPortraitOrientation;
			_isPortraitOrientation = _stageWidth < _stageHeight;//?appW/H
			var isOrientationChanged:Boolean = isPortraitModePrev != _isPortraitOrientation;

			var isQualityTypeChanged:Boolean = prevQualityType != Device.qualityType;
			prevQualityType = Device.qualityType;

			if (Device.isMobile && _isPortraitOrientation)
			{
				// Вписываем по ширине
				// Для мобилных устройств в разных ориентациях меняем местами ширину и высоту 
				_appScaleX = _appWidth / _initialAppHeight;
				_appScaleY = _appHeight / _initialAppWidth;
			}
			else
			{
				// Вписываем по высоте
				_appScaleX = _appWidth / _initialAppWidth;
				_appScaleY = _appHeight / _initialAppHeight;
			}
			_appScale = Math.min(_appScaleX, _appScaleY);

			// Update Starling
			for each (var starling:Starling in starlingArray)
			{
				starling.stage.stageWidth = _appWidth;
				starling.stage.stageHeight = _appHeight;
				var viewPortRect:Rectangle = new Rectangle(0, 0, _appWidth, _appHeight);
				starling.viewPort = viewPortRect;
			}

//			starling.root.scaleX = _appScale;
//			starling.root.scaleY = _appScale;

//?--
//			GUIConstructor.updateAppScale(appWidth, appHeight, appScaleX, appScaleY, appQualityCoeff);

			isFullScreen = stage.displayState == StageDisplayState.FULL_SCREEN;

			log.log(Channel.RESIZE, this, "(update) <dispatch-RESIZE?> appWidth/Height:", _appWidth, _appHeight, "stageWidth/Height:", _stageWidth, _stageHeight, "initialAppWidth/Height:", _initialAppWidth, _initialAppHeight, "isFullScreen:", isFullScreen, "appQualityCoeff:", appQualityCoeff, "Device.qualityCoeff:", Device.qualityCoeff);
			//log.info(Channel.RESIZE, this, " (update) appLeft/Top:",appLeft,appTop);
			log.info(Channel.RESIZE, this, " (update) initialHDWidth/Height:", initialHDWidth, initialHDHeight);
			log.info(Channel.RESIZE, this, " (update) prevAppWidth/Height:", prevAppWidth, prevAppHeight, "explicitAppWidth/Height:", explicitAppWidth, explicitAppHeight);
			log.info(Channel.RESIZE, this, " (update) stage.stageWidth/Height:", stage.stageWidth, stage.stageHeight, "stage.fullScreenWidth/Height:", stage.fullScreenWidth, stage.fullScreenHeight);
			log.info(Channel.RESIZE, this, " (update) starling.stage.stageWidth/Height:", starling ? starling.stage.stageWidth + " " + starling.stage.stageHeight : "-");
			log.info(Channel.RESIZE, this, " (update) appScale:", _appScale, "appScaleX,appScaleY:", _appScaleX, _appScaleY);

			if (isOrientationChanged)
			{
				log.info(Channel.RESIZE, this, "(update) <checkOrientationChange>", "isPortraitOrientation:", isPortraitOrientation);
				// Dispatch
				dispatchEventWith(ORIENTATION_CHANGE);
			}

			if (isQualityTypeChanged)
			{
				log.log(Channel.RESIZE, this, "(update) <dispatch-QUALITY_TYPE_CHANGE>", "Device.qualityType:", Device.qualityType);
				// Dispatch
				dispatchEventWith(QUALITY_TYPE_CHANGE);
			}

			if (prevAppWidth != _appWidth || prevAppHeight != _appHeight)
			{
				// Dispatch
				dispatchEventWith(RESIZE);
			}
		}

		// Event handlers

		private function stage_resizeHandler(event:Event):void
		{
			if (Device.isMobile)
			{
				// (Dispatch after timeout: on orientation change on mobile device 
				// sometimes error appears - Context3D is missing on texture creation)
				log.info(Channel.RESIZE, this, "(stage_resizeHandler) <setTimeout-update>");
				setTimeout(update, 70);
			}
			else
			{
				log.info(Channel.RESIZE, this, "(stage_resizeHandler) <update>");
				update();
			}
		}

		private function stage_fullscreenHandler(event:Event):void
		{
			log.info(Channel.RESIZE, this, "(stage_fullscreenHandler)");
			// Dispatch
			dispatchEventWith(FULL_SCREEN_CHANGE);
		}

	}
}
