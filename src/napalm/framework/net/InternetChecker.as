package napalm.framework.net
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.URLUtil;
	
	CONFIG::mobile
	{
		import air.net.URLMonitor;
	}

	/**
	 * InternetChecker.
	 * 
	 * Set pingURL before using!
	 * 
	 * Use:
	 *    Check internet by InternetChecker.isInternetAvailable whenever you need.
	 *    If IO error - call InternetChecker.checkInternetConnection(), INTERNET_AVAILABLE_CHANGE
	 *    will be dispatched to show/hide no-internet-connection-dialog.
	 *    After internet connection was lost checker pings for internet every 3 seconds.
	 * @author alex.panoptik@gmail.com
	 */
	public class InternetChecker
	{

		// Class constants

		// Events
		public static const INTERNET_AVAILABLE_CHANGE:String = "internetAvailableChange";
//		public static const CHECK_INTERNET_COMPLETE:String = "checkInternetComplete";

		private static const CHECK_INTERNET_INTERVAL:int = 3000;
		private static const POLL_INTERVAL:int = 5000;
		
		// Class variables

		public static var pingURL:String;
		
		protected static var log:Log = Log.instance;
		private static var eventDispatcher:EventDispatcher = new EventDispatcher();
		private static var offlineTimer:Timer = new Timer(CHECK_INTERNET_INTERVAL);
		private static var urlRequester:URLRequester = new URLRequester();
		CONFIG::mobile
		{
			private static var urlMonitor:URLMonitor;
		}
		
		private static var isInitialized:Boolean = false;
		private static var isCheckingInternet:Boolean = false;

		private static var time:int;

		// Class properties

		private static var _isInternetAvailable:Boolean = true;
		public static function get isInternetAvailable():Boolean
		{
			return _isInternetAvailable;
		}

		private static function setInternetAvailable(value:Boolean):void
		{
			if (_isInternetAvailable == value)
			{
				return;
			}

			_isInternetAvailable = value;
			log.log(Channel.NET_CHECKER, InternetChecker, "(setInternetAvailable)", "isInternetAvailable:", _isInternetAvailable);

			// Start/stop pinging server for internet
			if (_isInternetAvailable)
			{
				offlineTimer.stop();
			}
			else if (!Device.isMobile)
			{
				offlineTimer.start();
			}

			// Dispatch
			eventDispatcher.dispatchEvent(new Event(INTERNET_AVAILABLE_CHANGE));
		}

		private static function get defaultPingURL():String
		{
			var defaultURLArray:Array = ["http://www.yahoo.com/", "http://ya.ru/", "http://www.facebook.com/", 
				"http://twitter.com/", "http://en.wikipedia.org/", "http://adobe.com/"];
			var url:String = defaultURLArray[int(Math.random() * defaultURLArray.length)];
			return url;
		}

		// Class methods

		public static function addEventListener(type:String, listener:Function):void
		{
			eventDispatcher.addEventListener(type, listener);
		}

		public static function removeEventListener(type:String, listener:Function):void
		{
			eventDispatcher.removeEventListener(type, listener);
		}

		public static function hasEventListener(type:String):Boolean
		{
			return eventDispatcher.hasEventListener(type);
		}

		private static function checkInitialized():Boolean
		{
			if (isInitialized)
			{
				return isInitialized;
			}

			log.log(Channel.NET_CHECKER, InternetChecker, "(initialize)");
			// Listeners
			offlineTimer.addEventListener(TimerEvent.TIMER, timer_timerHandler);

			CONFIG::mobile
			{
				if (pingURL)
				{
					urlMonitor = new URLMonitor(new URLRequest(pingURL));
					// Listeners
					urlMonitor.addEventListener(StatusEvent.STATUS, urlMonitor_statusHandler);
					urlMonitor.pollInterval = POLL_INTERVAL;
					urlMonitor.start();
				}
				else
				{
					return isInitialized;
				}
			}

			isInitialized = true;
			return isInitialized;
		}

		/**
		 * Make request to check is internet available.
		 *
		 * Returns result immediately for mobile, and previous value for web.
		 * For web listen for INTERNET_AVAILABLE_CHANGE and use isInternetAvailable property.
		 * (For web checkInternetConnection() is same as isInternetAvailable, but updates status.)
		 *
		 * @return
		 */
		public static function checkInternetConnection():Boolean
		{
			if (!checkInitialized())
			{
				return true;
			}

			if (Device.isMobile)
			{
				return isInternetAvailable;
			}

			log.info(Channel.NET_CHECKER, InternetChecker, "(checkInternetConnection) <sendCheckInternetRequest>", "prev-isCheckingInternet:", isCheckingInternet, "isInternetAvailable:", isInternetAvailable);
			// (Note: When offline request is sending by offlineTimer every few seconds)
			if (isInternetAvailable)
			{
				sendCheckInternetRequest();
			}

			return isInternetAvailable;
			//return true;//was//return false;//was
		}

		private static function sendCheckInternetRequest():void
		{
			//trace(InternetChecker,"(sendCheckInternetRequest) isCheckingInternet:",isCheckingInternet,getTimer() - time);
			if (!isCheckingInternet)// && getTimer() - time > 3000
			{
				if (!pingURL)
				{
					log.warn(Channel.NET_CHECKER, InternetChecker, "pingURL for InternetChecker is not set! pingURL:", pingURL);
				}
				
				var url:String = URLUtil.forceCacheFor(pingURL || defaultPingURL);
				isCheckingInternet = true;

				log.info(Channel.NET_CHECKER, InternetChecker, " (sendCheckInternetRequest) <requester-load>", 
						getTimer() - time, "msec", "url:", url, "isCheckingInternet:", isCheckingInternet);
				time = getTimer();
				urlRequester.name = "internetChecker";
				urlRequester.load(url, checkInternetURLRequester_onComplete);
			}
		}

		// Class event handlers

		private static function checkInternetURLRequester_onComplete(data:Object):void
		{
			isCheckingInternet = false;
			log.info(Channel.NET_CHECKER, InternetChecker, "(checkInternetURLRequester_onComplete)", "isCheckingInternet:", isCheckingInternet);

			var isRequestError:Boolean = data is Event || data is Error;
			setInternetAvailable(!isRequestError);

			// Dispatch
//			eventDispatcher.dispatchEventWith(CHECK_INTERNET_COMPLETE);
		}

		private static function timer_timerHandler(event:Event):void
		{
			log.info(Channel.NET_CHECKER, InternetChecker, "(timer_timerHandler)", "isCheckingInternet:", isCheckingInternet);
			sendCheckInternetRequest();
		}

		private static function urlMonitor_statusHandler(event:Event):void
		{
			log.info(Channel.NET_CHECKER, InternetChecker, "(urlMonitor_statusHandler)");
			CONFIG::mobile
			{
				setInternetAvailable(urlMonitor.available);
			}
		}

	}
}
