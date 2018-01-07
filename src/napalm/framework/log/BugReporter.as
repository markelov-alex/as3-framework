package napalm.framework.log
{
	import flash.display.LoaderInfo;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	
	import napalm.framework.net.URLRequester;
	import napalm.framework.utils.DateUtil;
	
	/**
	 * BugReporter.
	 * 
	 * Set getScreenShot in Main to avoid Starling classes in preloader: 
	 * BugReporter.getScreenShot = function():void {StarlingUtil.getScreenShotBase64(0.75, 0, 40);};
	 * @author alex.panoptik@gmail.com
	 */
	public class BugReporter
	{

		// Class constants
		
//		private static const REPORT_MIN_INTERVAL_MSEC:int = 6000;//2 * 60000;
//		private static const MAX_REPORT_COUNT_IN_INTERVAL:int = 2;
		
		// Class variables

		public static var reportURL:String;
		public static var isAttachLog:Boolean = true;
		public static var isAttachScreenShot:Boolean = false;
		public static var getScreenShot:Function;
		
		public static var isProduction:Boolean = true;
		public static var socialUserID:String;
		public static var socialNetwork:String;
		public static var appInfo:String;
		
		protected static var log:Log = Log.instance;
//		private static var lastReportTime:int = -100000000;
//		private static var reportInIntervalCount:int = 0;
		private static var errorReportedLookup:Dictionary = new Dictionary();
		
		// Class methods

		public static function listenUncaughtErrors(loaderInfo:LoaderInfo):void
		{
			log._log(Channel.LOG, BugReporter, "(listenUncaughtErrors)", "loaderInfo:", loaderInfo, 
					"url:", loaderInfo ? loaderInfo.url : "-", "loaderURL:", loaderInfo ? loaderInfo.loaderURL : "-");
			if (loaderInfo)
			{
				loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, 
						uncaughtErrorEvents_uncaughtErrorHandler);
			}
		}
		
		public static function unlistenUncaughtErrors(loaderInfo:LoaderInfo):void
		{
			log._log(Channel.LOG, BugReporter, "(unlistenUncaughtErrors)", "loaderInfo:", loaderInfo, 
					"url:", loaderInfo ? loaderInfo.url : "-", "loaderURL:", loaderInfo ? loaderInfo.loaderURL : "-");
			if (loaderInfo)
			{
				loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, 
						uncaughtErrorEvents_uncaughtErrorHandler);
			}
		}

		// Called from log.error() - use Log instead
		public static function reportError(info:String, error:Error):void
		{
			report(info, error, 1);
		}

		// Called from log.fatal() - use Log instead
		public static function reportFatal(info:String, error:Error):void
		{
			report(info, error, 2);
		}

		public static function reportBug(bugID:String, info:String = null):void
		{
			report("BUG: " + bugID + " " + info, null, 3);

			log._error(Channel.LOG, BugReporter, "BUG:", bugID, info);
		}

		public static function reportImpossible(bugID:String, info:String = null):void
		{
			report("IMPOSSIBLE: " + bugID + " " + info, null, 4);

			log._fatal(Channel.LOG, BugReporter, "IMPOSSIBLE:", bugID, info);
		}

		/**
		 * @param condition true to report
		 * @param message
		 */
		public static function assertReportBug(condition:Boolean, bugID:String, info:String = null):void
		{
			if (condition)
			{
				reportBug(bugID, info);
			}
		}

		/**
		 * @param condition true to report
		 * @param message
		 */
		public static function assertReportImpossible(condition:Boolean, bugID:String, info:String = null):void
		{
			if (condition)
			{
				reportImpossible(bugID, info);
			}
		}

		private static function getStackTrace(error:Error = null):String
		{
			var result:String = "";
			if (!Capabilities.isDebugger)
			{
				result = "(release-player-no-stack) Capabilities.isDebugger(f): " + Capabilities.isDebugger + "\n";
			}

			error ||= new Error();
			result += (error as Error).getStackTrace();
			return result;
		}

		/**
		 *
		 * @param info
		 * @param error (Error|UncaughtErrorEvent|IOError|SecurityError|...)
		 */
		private static function report(info:String, error:* = null, priority:int = 0):void
		{
			if (!reportURL)
			{
				log._warn(Channel.LOG, BugReporter, "Cannot send report! reportURL is not set. reportURL:", reportURL);
				return;
			}
			log._log(Channel.LOG, BugReporter, "(REPORT)", priority, info, "error:", error);
			
			log._log(Channel.LOG, BugReporter, log.getTotalInfo(), "\n", appInfo);

//			// Avoid DDoSing report server
//			if (!checkReportEnabled())
//			{
//				return;
//			}
			// Check reported only once
			if (errorReportedLookup[info + error])
			{
				log._warn(Channel.LOG, BugReporter, "Skip report. Such error was already reported.");
				return;
			}
			errorReportedLookup[info + error] = true;
			
			var errorText:String = DateUtil.getCurrentDateString(".") + "_" + DateUtil.getCurrentTimeString(":") + "\n" + 
					info + "\n\n" + error + "\n" + getStackTrace(error) + "\n\n" + 
					log.getTotalInfo() + "\n" + appInfo;

			if (!isProduction && ExternalInterface.available)
			{
				//TODO make function in JS
				// Show some error info on application page in browser for Dev version
				try
				{
					ExternalInterface.call("showError", escape(errorText));
				}
				catch (error:Error)
				{
					log._error(Channel.LOG, BugReporter, "ExternalInterface.showError error");
				}
			}

			log._log(Channel.LOG, BugReporter, " (errorReport) <getScreenShot>");
			makeRequest(errorText);
		}

		private static function makeRequest(errorText:String):void
		{
			var params:URLVariables = new URLVariables();
			params.user_id = socialUserID;
			params.network = (isProduction ? "prod_" : "dev_") + (socialNetwork || "no");
			params.error = errorText;
			if (isAttachLog)
			{
				params.log = log.getAllLog();
			}
			if (isAttachScreenShot && getScreenShot != null)
			{
				params.screen = getScreenShot();
			}
			
			var urlRequester:URLRequester = new URLRequester();
			urlRequester.name = "bugReporter";
			urlRequester.load(reportURL, onRequestComplete, params, true)
		}

//		private static function checkReportEnabled():Boolean
//		{
//			var lastReportInterval:int = getTimer() - lastReportTime;
//			if (lastReportInterval < REPORT_MIN_INTERVAL_MSEC)
//			{
//				reportInIntervalCount++;
//				if (reportInIntervalCount > MAX_REPORT_COUNT_IN_INTERVAL)
//				{
//					log.log(Channel.LOG, BugReporter, "(checkReportEnabled) <return-false> Too much reports in interval!",
//							"MIN-INTERVAL:", REPORT_MIN_INTERVAL_MSEC, "lastReportInterval:", lastReportInterval,
//							"MAX-COUNT:", MAX_REPORT_COUNT_IN_INTERVAL, "reportInIntervalCount:", reportInIntervalCount);
//					return false;
//				}
//			}
//
//			reportInIntervalCount = 0;
//			lastReportTime = getTimer();
//
//			return true;
//		}

		// Class event handlers

		private static function uncaughtErrorEvents_uncaughtErrorHandler(errorEvent:UncaughtErrorEvent):void
		{
			// (Prevent throwing)
			errorEvent.preventDefault();

			var error:* = errorEvent.error;
			log._error(Channel.LOG, BugReporter, "(uncaughtErrorEvents_uncaughtErrorHandler) errorEvent:", errorEvent, "error:", error, error is Error ? "stack: " + error.getStackTrace() : "");
			BugReporter.reportError("[BugReporter] uncaughtErrorEvents_uncaughtErrorHandler " + errorEvent, error);
		}

		private static function onRequestComplete(data:*):void
		{
		}
		
	}
}
