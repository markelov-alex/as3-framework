package napalm.framework.core
{
	import com.junkbyte.console.Cc;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.Security;
	
	import napalm.framework.config.Device;
	import napalm.framework.log.BugReporter;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.preloader.SimplePreloader;
	
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.Event;
	
	/**
	 * SimpleApplication.
	 * 
	 * Base class of your Main class for using without framework.
	 * Application initialization processed here.
	 *
	 * Initialization steps:
	 * 1. Wait for added to stage.
	 * 2. Init Starling (wait for ROOT_CREATED).
	 * 3. Start application!
	 * @author alex.panoptik@gmail.com
	 */
	public class SimpleApplication extends flash.display.Sprite implements IAppContainer
	{

		// Class constants

		// (Preventing ambigiuos references to starling and flash classes and collision with "starling" var)
		private static const ROOT_CREATED:String = starling.events.Event.ROOT_CREATED;
		private static const starling_display_Sprite:Class = starling.display.Sprite;
		
		// Class variables
		// Class methods

		// Variables

		protected var isStarlingEnabled:Boolean = true;

		protected var isListenResize:Boolean = true;
		protected var explicitAppWidth:int = -1;
		protected var explicitAppHeight:int = -1;

		protected var log:Log = Log.instance;
		protected var starling:Starling;

		//(make protected if needed?)
		protected var starlingRootClass:Class = starling_display_Sprite;
		protected var starlingViewPort:Rectangle = new Rectangle(0, 0, 1000, 1000);//??
		protected var starlingStage3D:Stage3D;

		// Properties

		// Important! Hide all Stage3D layers with Main application to avoid clicking through mobile preloader!
		override public function set visible(value:Boolean):void
		{
			super.visible = value;

			if (starlingRoot)
			{
				starlingRoot.visible = value;
			}
			log.info(Channel.APPLICATION, this, "(set-visible)", "visible:", visible, "starlingRoot:", starlingRoot);
		}

		private var _starlingRoot:DisplayObjectContainer;
		public function get starlingRoot():DisplayObjectContainer
		{
			return _starlingRoot;
		}

		/**
		 * Define frameRate only here!
		 */
		private var _frameRate:int = 60;
		protected function get frameRate():int
		{
			return _frameRate;
		}

		protected function set frameRate(value:int):void
		{
			_frameRate = value;

			if (stage)
			{
				stage.frameRate = value;
			}
		}

		protected function get appWidth():int
		{
			return explicitAppWidth > -1 || !stage ? explicitAppWidth : stage.stageWidth;
		}

		protected function get appHeight():int
		{
			return explicitAppHeight > -1 || !stage ? explicitAppHeight : stage.stageHeight;
		}

		// Constructor

		public function SimpleApplication()
		{
			//todo change password for production!!!
			Cc.startOnStage(this, "`");
			Cc.displayRoller
			log.setConsole(Cc);
			setUpDefaultLogChannels();
			
			log.log(Channel.APPLICATION, "\n-Create-Main-");
			log.log(Channel.APPLICATION, this, "(constructor) stage:", stage);
			if (stage)
			{
				init();
			}
			else
			{
				// Listeners
				addEventListener(flash.events.Event.ADDED_TO_STAGE, addedToStageHandler);
			}
			
			// In subclass:
			//isStarlingEnabled = false;
		}

		// Methods

		private function init():void
		{
			
			Device.initialize(stage, CONFIG::mobile);
			BugReporter.listenUncaughtErrors(loaderInfo);
			//todo
			//BugReporter.getScreenShot = function ():void
			//{
			//	//flash
			//};

			log.log(Channel.APPLICATION, this, log.getTotalInfo(loaderInfo));
			log.log(Channel.APPLICATION, this, "[starlingVersion]", "v." + Starling.VERSION);
			log.log(Channel.APPLICATION, this, "");

			log.log(Channel.APPLICATION, this, "[START-STEP-1] Init Main");
			log.log(Channel.APPLICATION, this, "(init) <initStarling>");

			if (!Device.isMobile)
			{
				try
				{
					//any domain can change our content
					Security.allowDomain("*");
					Security.allowInsecureDomain("*");
				}
				catch (error:Error)
				{
					log.error(Channel.APPLICATION, this, "(init) Security.allow(Insecure)Domain error:", error);
				}
			}

//			CONFIG::web
//			{
//				Cc.config.commandLineAllowed = true;
//			}

			stage.frameRate = frameRate;
			
			updateSize();
			// Listeners
			if (isListenResize)
			{
				stage.addEventListener(flash.events.Event.RESIZE, stage_resizeHandler);
			}

			log.log(Channel.APPLICATION, this, "[START-STEP-2] Init Starling isStarlingEnabled:", isStarlingEnabled);

			// Always enabled for using Starling.juggler
			if (isStarlingEnabled || true)
			{
				starlingStage3D = stage.stage3Ds[0];
				initStarling();
			}
			else
			{
				startApplication();
			}
		}

		public function dispose():void
		{
			// Listeners
			if (stage)
			{
				stage.removeEventListener(flash.events.Event.RESIZE, stage_resizeHandler);
			}
			
			if (starling)
			{
				starling.dispose();
			}
			starling = null;
			log = null;

			//(make protected if needed?)
			//starlingRootClass = null;
			//starlingViewPort = null;//??
			starlingStage3D = null;

			BugReporter.unlistenUncaughtErrors(loaderInfo);
		}

		public function setAppSize(appWidth:int, appHeight:int):void
		{
			this.explicitAppWidth = appWidth;
			this.explicitAppHeight = appHeight;
			
			updateSize();
		}
		
		// Set up logs in one place
		protected function setUpDefaultLogChannels():void
		{
			//log.setLogChannelPriority(Channel., Log.LOG_PRIORITY);
			//log.setConsoleChannelPriority(Channel., Log.LOG_PRIORITY);
		}

		protected function initStarling():void
		{
			//starlingStage3D = stage.stage3Ds[1];

			log.log(Channel.APPLICATION, this, "(initStarling) <new-Starling> stage:", stage, "starlingRootClass:", starlingRootClass, 
					"starlingViewPort:", starlingViewPort, "starlingStage3D:", starlingStage3D);
			//? stageWidth, stageHeight
			//(Note: viewPort can be arbitrary. Appropriate values will be set in ResizeManager)
			starling = new Starling(starlingRootClass, stage, starlingViewPort, starlingStage3D, "auto", "baseline");//--stageWidth, stageHeight), null, "auto", "baseline");//
			starling.simulateMultitouch = false;
			starling.enableErrorChecking = !true;
			//starling.shareContext = true;
			starling.stage.color = 0xDCFEE4;

			// Listeners
			starling.addEventListener(ROOT_CREATED, starling_rootCreatedHandler);
		}

		// Override
		protected function startApplication():void
		{
			log.log(Channel.APPLICATION, this, "(startApplication) <starling.start> starling:", starling);
			// Start Starling
			if (starling)
			{
				starling.start();
			}
		}

		// Override
		protected function applicationLaunched():void
		{
			log.log(Channel.APPLICATION, this, "(applicationStarted) <dispatch-APPLICATION_READY>");
			// Hide preloader
			// Dispatch
			dispatchEvent(new flash.events.Event(SimplePreloader.APPLICATION_READY));
			
			// (If log instance is different than in preloader)
			log.log(Channel.APPLICATION, this, "--------------- Initialization Log Complete ---------------");
			log.captureInitializationLog();
		}

		// Override
		protected function updateSize():void
		{
		}

		// Event handlers

		private function addedToStageHandler(event:flash.events.Event):void
		{
			log.log(Channel.APPLICATION, this, "(addedToStageHandler) <init>");
			// Listeners
			if (hasEventListener(flash.events.Event.ADDED_TO_STAGE))
			{
				removeEventListener(flash.events.Event.ADDED_TO_STAGE, addedToStageHandler);
			}

			init();
		}

		private function starling_rootCreatedHandler(event:starling.events.Event):void
		{
			log.log(Channel.APPLICATION, this, "(starling_rootCreatedHandler) <initFramework>");
			_starlingRoot = starling.root as DisplayObjectContainer;
			_starlingRoot.visible = visible;

			// Listeners
			starling.removeEventListener(ROOT_CREATED, starling_rootCreatedHandler);

			startApplication();
		}

		private function stage_resizeHandler(event:flash.events.Event):void
		{
			updateSize();
		}
		
	}
}
