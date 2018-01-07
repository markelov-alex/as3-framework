package napalm.framework.log
{
	import flash.display.LoaderInfo;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.getTimer;
	
	import napalm.framework.config.Preferences;
	import napalm.framework.utils.DateUtil;
	import napalm.framework.utils.ObjectUtil;
	import napalm.framework.utils.StringUtil;
	
	/**
	 * log.
	 * 
	 * todo fix doc
	 * todo make console commands to set up system
	 * Initialization of console:
	 * 	// At very start:
	 * 	log.console = Cc;
	 * 	// On added to stage:
	 * 	Cc.startOnStage(this, "```");
	 * 	// That's all. Press ``` to show console
	 * 
	 * Created to provide common interface for log class
	 * (console not yet implemented, but it will be easy to do that later).
	 * 
	 * Channels: "g.field.model", "g.field.panel", "g.field.gempanel", "l.map.model", "l.map.location"
	 * 
	 * Use:
	 *  info()  for debug logs (turned off in release build),
	 *  log()   for release logs,
	 *  warn()  if something is wrong, but acceptable,
	 *  error() if something is wrong, but it should be right,
	 *  fatal() for try-catch.
	 * 
	 * Using:
	 *  public static const LOG:String = "framework.dialog.dialog";
	 *  ...
	 *    log.log(LOG, this, "(constructor) &lt;some;visible=false;return-false&gt; skinClassName:", skinClassName,
	 * "alpha:", skin.alpha);
	 *
	 * Here:
	 *    LOG - is channel,
	 *    this - subchannel (reference to instance where log was called from),
	 *    "(constructor)" - method name where log was called from,
	 *    "&lt;some&gt;" - some actions which will be called after log (for example, "some(); skinObject.visible =
	 * false; return false;"),
	 * 
	 * Config logs in your Main:
	 *    //log.defaultLogPriority = log.INFO_PRIORITY;// show all logs for all channels
	 *    log.setChannelPriority(Dialog.LOG, log.INFO_PRIORITY);// show all logs for Dialog's "framework.dialog.dialog"
	 * channel
	 * 
	 * You can use VizzyTracer tool to be able to filter traces by channel or any other string.
	 * 
	 * Note: Don't use JSON.stringify() in logs to avoid unexpected errors. Use ObjectUtil.stringify()!
	 * 		 Use log.stringify() to cut big strings to be logged carefully.
	 * @author alex.panoptik@gmail.com
	 */
	public class Log
	{

		// Class constants

		public static const DEFAULT_PRIORITY:int = 0;
		public static const ALL_PRIORITY:int = 1;// info, log, warn, error, fatal
		public static const INFO_PRIORITY:int = 1;// info, log, warn, error, fatal
		public static const LOG_PRIORITY:int = 2;// log, warn, error, fatal
		public static const WARN_PRIORITY:int = 3;// warn, error, fatal
		public static const ERROR_PRIORITY:int = 4;// error, fatal
		public static const FATAL_PRIORITY:int = 5;// fatal
		public static const NONE_PRIORITY:int = 6;

		//todo refactor
		public static const isLogFullData:Boolean = !CONFIG::mobile;
		// (For profiling memory leaks)
		private static const isEnabledAll:Boolean = true;
		
		private static const prefixByPriority:Array = ["", "[INF]", "[LOG]", "[WARN]!", "[ERROR]!!!", "[FATAL_ERROR]!!!!!!"];
		private static const consolePriorityByLogPriority:Object = {};
		consolePriorityByLogPriority[INFO_PRIORITY] = 1;//Console.LOG;
		consolePriorityByLogPriority[LOG_PRIORITY] = 3;//Console.INFO;
		consolePriorityByLogPriority[WARN_PRIORITY] = 8;//Console.WARN;
		consolePriorityByLogPriority[ERROR_PRIORITY] = 9;//Console.ERROR;
		consolePriorityByLogPriority[FATAL_PRIORITY] = 10;//Console.FATAL;

		// Class variables
		
		private static var preferences:Preferences;
		
		// Class properties
		
		private static var _instance:Log = new Log("default");
		public static function get instance():Log
		{
			return _instance;
		}

		public static function get appTimeInfo():String
		{
			return "Current time: " + new Date() + " From start: " + getTimer() + " msec";
		}

		public static function get capabilitiesInfo():String
		{
			return "CAPABILITIES OS: " + Capabilities.os + " CPU: " + Capabilities.cpuArchitecture +
					" FP version: " + Capabilities.version + " manufacturer: " + Capabilities.manufacturer +
					" resolution@dpi: " + Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY +
					"@" + Capabilities.screenDPI;
		}

		public static function get browserInfo():String
		{
			if (ExternalInterface.available)
			{
				var jsCodeString:String = "'BROWSER navigator.appCodeName: \"' + navigator.appCodeName + " +
						"'\" appName: \"' + navigator.appName + " +
						"'\" platform: \"' + navigator.platform + " +
						"'\" appVersion: \"' + navigator.appVersion + " +
						"'\" userAgent: \"' + navigator.userAgent + " +
						"'\" language: \"' + navigator.language + " +
						"'\" cookieEnabled: \"' + navigator.cookieEnabled + " +
						"'\" onLine: \"' + navigator.onLine + " +
						"'\"'";
				var jsFunctionString:String = "function () { return " + jsCodeString + "; }";
				return ExternalInterface.call(jsFunctionString);
			}
			return null;
		}
		
		public static function getTotalInfo(loaderInfo:LoaderInfo = null):String
		{
			return _instance.getTotalInfo(loaderInfo);
		}

		/**
		 * Used as prefix for each log line.
		 */
		private static function get timeStamp():String
		{
			return DateUtil.getCurrentFullTimeString() + " »";
		}
		
		// Class methods
		
		public static function _info(channel:String, ...args):void
		{
			_instance._info(channel, args);
		}
		
		public static function _log(channel:String, ...args):void
		{
			_instance._log(channel, args);
		}
		
		public static function _warn(channel:String, ...args):void
		{
			_instance._warn(channel, args);
		}
		
		public static function _error(channel:String, ...args):void
		{
			_instance._error(channel, args);
		}
		
		public static function _fatal(channel:String, ...args):void
		{
			_instance._fatal(channel, args);
		}
		
		public static function info(channel:String, ...args):void
		{
			_instance.info(channel, args);
		}
		
		public static function log(channel:String, ...args):void
		{
			_instance.log(channel, args);
		}
		
		public static function warn(channel:String, ...args):void
		{
			_instance.warn(channel, args);
		}
		
		public static function error(channel:String, ...args):void
		{
			_instance.error(channel, args);
		}
		
		public static function fatal(channel:String, ...args):void
		{
			_instance.fatal(channel, args);
		}
		
		public static function getAllLog():void
		{
			_instance.getAllLog();
		}
		
		public static function checkChannelEnabled(channel:String, priority:int = LOG_PRIORITY):Boolean
		{
			return instance.checkChannelEnabled(channel, priority);
		}
		
		// Utility
		
		public static function stringify(object:Object):String
		{
			return ObjectUtil.stringify(object, Log.isLogFullData ? -1 : 400)
		}
		
		public static function toString(object:*):String
		{
			if (object is Class)
			{
				return ObjectUtil.getClassName(object);
			}
			if (object is Number)
			{
				return String(object.toFixed(3));
			}
			return String(object);
		}
		
		// Variables
		
		// (Settings)
		public var isEnabled:Boolean = true;
		public var isTraceEnabled:Boolean = true;
		public var isConsoleEnabled:Boolean = true;
		//-public var isVerboseAssetManager:Boolean = false;//?- replace with channel if possible
		public var defaultLogPriority:int = LOG_PRIORITY;
		public var defaultConsolePriority:int = LOG_PRIORITY;//WARN_PRIORITY;
		public var reportBugPriority:int = ERROR_PRIORITY;
		
		public var isShowChannel:Boolean = true;
		public var isOmitObjectAsSubChannel:Boolean = true;
		public var minChannelLength:int = 15;//36;
		public var minSubChannelLength:int = 26;
		
		// (References)
		public var onTrace:Function;
//		CONFIG::mobile
//		{
//			public var mobileLogWriter:*;
//			public var logSender:*;
//		}
		// (Set log.console = com.junkbyte.console.Cc;)
		private var console:Object;
		
		private var id:String;
		
		private var logPriorityByChannelLookup:Object = {};
		private var consolePriorityByChannelLookup:Object = {};
		//-private var blockPriorityByChannelLookup:Dictionary = new Dictionary();
		
		// All the log contained here
		private var firstLogLine:LogLine;
		private var lastLogLine:LogLine;
		
		// Properties
		
		private var _initializationLog:String;
		// Is set on captureInitializationLog() call
		public function get initializationLog():String
		{
			return _initializationLog || _instance.initializationLog;
		}
		
		public function get logInfo():String
		{
			return "defaultLogPriority: " + defaultLogPriority + " isShowChannel: " + isShowChannel + //" isVerboseAssetManager: " + isVerboseAssetManager +
					" isOmitObjectAsSubChannel: " + isOmitObjectAsSubChannel + " minChannelLength: " + minChannelLength +
					" minSubChannelLength: " + minSubChannelLength;
		}
		
		public function get logChannelInfo():String
		{
			var result:String = "log: ";
			var coma:String = "";
			for (var channel:String in logPriorityByChannelLookup)
			{
				result += coma + channel + ":" + logPriorityByChannelLookup[channel];
				coma ||= ", ";
			}
			
			result += "\n console: ";
			coma = "";
			for (channel in logPriorityByChannelLookup)
			{
				result += coma + channel + ":" + logPriorityByChannelLookup[channel];
				coma ||= ", ";
			}

//was-			for (var channel:String in logPriorityByChannelLookup)
//			{
//				var blockPriority:String = blockPriorityByChannelLookup[channel] || "-";
//				result += channel + "(" + logPriorityByChannelLookup[channel] + "," + blockPriority + ") ";
//			}
//			for (channel in blockPriorityByChannelLookup)
//			{
//				if (logPriorityByChannelLookup[channel] == undefined)
//				{
//					result += channel + "(-," + blockPriorityByChannelLookup[channel] + ") ";
//				}
//			}
			return result;
		}
		
		/**
		 * Get all user's environment info for logging.
		 *
		 * @param loaderInfo
		 * @return
		 */
		public function getTotalInfo(loaderInfo:LoaderInfo = null):String
		{
			return 	"\n[appTimeInfo] " + appTimeInfo + "\n"
					"[capabilitiesInfo] " + capabilitiesInfo + "\n" +
					"[browserInfo] " + browserInfo + "\n" +
					"[logInfo] " + logInfo + "\n" +
					"[logChannelInfo] " + logChannelInfo + "\n" +
					(loaderInfo ? "[swf-url] " + loaderInfo.url + "\n" : "");
		}
		
		// Constructor
		
		public function Log(id:*)
		{
			this.id = String(id);
			
			firstLogLine = new LogLine("", null);
			lastLogLine = firstLogLine;
			
			// Note: We cannot loadPreferences() from here because preferences use Log.instance itself
			
			if (instance)
			{
				log(Channel.LOG, "(CREATE NEW LOG STREAM) All new messages will go there. id:", id)
			}
		}
		
		// Methods
		
		public function loadPreferences():void
		{
			if (!preferences)
			{
				// Preferences would be same for same file regardless of user account it was launched from
				preferences = new Preferences("log_preferences");
			}
			
			// Load
			log(Channel.LOG, "(loadPreferences)", logChannelInfo);
			logPriorityByChannelLookup = preferences.getSetting(id + ".logPriorityByChannelLookup") || 
					logPriorityByChannelLookup;
			consolePriorityByChannelLookup = preferences.getSetting(id + ".consolePriorityByChannelLookup") || 
					consolePriorityByChannelLookup;
			
			log(Channel.LOG, "(loadPreferences)", logChannelInfo);
		}
		
		// (Don't set Cc at start because Log is used in Preloader)
		public function setConsole(console:Object):void
		{
			if (this.console || !console)
			{
				return;
			}
			
			this.console = console;
			
			// Add previous log
			console.log(firstLogLine.getLogFromThis());
			
			addConsoleCommands();
			
			info(Channel.LOG, "test info")
			warn(Channel.LOG, "test warn")
			error(Channel.LOG, "test error")
			fatal(Channel.LOG, "test fatal")
		}
		
		// Set 1-6 priority to show only messages with higher priority
		public function setLogChannelPriority(channel:String, priority:int):void
		{
			log(Channel.LOG, "(setLogChannelPriority)", "channel:", channel, "priority:", priority)
			logPriorityByChannelLookup[channel] = priority;
			// Save
			preferences.setSetting(id + ".logPriorityByChannelLookup", logPriorityByChannelLookup);
		}
		
		// Set 1-6 priority to show only messages with higher priority in console
		public function setConsoleChannelPriority(channel:String, priority:int):void
		{
			log(Channel.LOG, "(setConsoleChannelPriority)", "channel:", channel, "priority:", priority)
			// Affect also log priority if needed
			if (logPriorityByChannelLookup[channel] > priority)
			{
				setLogChannelPriority(channel, priority);
			}
			
			consolePriorityByChannelLookup[channel] = priority;
			// Save
			preferences.setSetting(id + ".consolePriorityByChannelLookup", consolePriorityByChannelLookup);
		}
//-
//		// Set 0 to unblock
//		// Set 1-6 priority to block all messages of this priority and lower
//		public static function setBlockChannelPriority(channel:String, priority:int):void
//		{
//			log.blockPriorityByChannelLookup[channel] = priority;
//		}
		
		// Needed to adjust logs for custom users by config file got from server
		public function setChannelsPriorityByData(priorityByChannel:Object):void
		{
			for (var channel:String in priorityByChannel)
			{
				logPriorityByChannelLookup[channel] = priorityByChannel[channel];
			}
			// (Don't save in preferences)
		}
//-
//		public static function setBlockChannelsPriorityByData(priorityByChannel:Object):void
//		{
//			for (var channel:String in priorityByChannel)
//			{
//				log.blockPriorityByChannelLookup[channel] = priorityByChannel[channel];
//			}
//		}
		
		public function resetChannels():void
		{
			for (var channel:String in logPriorityByChannelLookup)
			{
				delete logPriorityByChannelLookup[channel];
			}
			for (channel in consolePriorityByChannelLookup)
			{
				delete consolePriorityByChannelLookup[channel];
			}
			
			// Save
			preferences.setSetting(id + ".logPriorityByChannelLookup", logPriorityByChannelLookup);
			preferences.setSetting(id + ".consolePriorityByChannelLookup", consolePriorityByChannelLookup);
		}
		
		public function _info(channel:String, ...args):void
		{
			add(INFO_PRIORITY, channel, args);
		}
		
		public function _log(channel:String, ...args):void
		{
			add(LOG_PRIORITY, channel, args);
		}
		
		public function _warn(channel:String, ...args):void
		{
			add(WARN_PRIORITY, channel, args);
		}
		
		public function _error(channel:String, ...args):void
		{
			add(ERROR_PRIORITY, channel, args);
		}
		
		public function _fatal(channel:String, ...args):void
		{
			add(FATAL_PRIORITY, channel, args);
		}
		
		/**
		 * Метод для логирования данных, которые являются отладочными
		 * и могут быть отключены установкой общего приоритета при конфигурировании приложения.
		 *
		 * @param args - отладочная информация, которую необходмо вывести в лог.
		 */
		public function info(channel:String, ...args):void
		{
			var fullString:String = add(INFO_PRIORITY, channel, args);
			
			if (INFO_PRIORITY >= reportBugPriority)
			{
				checkReportBug(INFO_PRIORITY, args, fullString);
			}
		}
		
		/**
		 * Стандартный метод логирования.
		 * Предполагается, что всё, что необходимо в релизном билде и не будет отключаться,
		 * будет записываться в лог с помощью этого метода.
		 * (например действия игрока, информация о смене состояния приложения)
		 *  <br><br>
		 * Если необходимо иметь возможность быстро отключить вывод в лог,
		 * то лучше использовать метод info(channel:String, ...args).
		 * <br><br>
		 * В консоли отображается зеленым цветом.
		 * @param args - информация, которую необходмо вывести в лог.
		 */
		public function log(channel:String, ...args):void
		{
			var fullString:String = add(LOG_PRIORITY, channel, args);
			
			if (LOG_PRIORITY >= reportBugPriority)
			{
				checkReportBug(LOG_PRIORITY, args, fullString);
			}
		}
		
		public function warn(channel:String, ...args):void
		{
			var fullString:String = add(WARN_PRIORITY, channel, args);
			
			if (WARN_PRIORITY >= reportBugPriority)
			{
				checkReportBug(WARN_PRIORITY, args, fullString);
			}
		}
		
		public function error(channel:String, ...args):void
		{
			var fullString:String = add(ERROR_PRIORITY, channel, args);
			
			if (ERROR_PRIORITY >= reportBugPriority)
			{
				checkReportBug(ERROR_PRIORITY, args, fullString);
			}
		}
		
		public function fatal(channel:String, ...args):void
		{
			var fullString:String = add(FATAL_PRIORITY, channel, args);
			
			if (FATAL_PRIORITY >= reportBugPriority)
			{
				checkReportBug(FATAL_PRIORITY, args, fullString);
			}
		}
		
		public function checkChannelEnabled(channel:String, priority:int = LOG_PRIORITY):Boolean
		{
			return (logPriorityByChannelLookup[channel] || defaultLogPriority) >= priority;
		}
		
		private function add(priority:int, channel:String, args:Array):String
		{
			if (!isEnabledAll || !isEnabled || (logPriorityByChannelLookup[channel] || defaultLogPriority) > priority)
			{
				return null;
			}
			
			if (args.length == 1 && args[0] is Array)
			{
				args = args[0];
			}
			
			var channelString:String = isShowChannel && minChannelLength > 0 ? StringUtil.fitToMinLength("[" + channel + "] ", minChannelLength) : "";
			if (!(args[0] is String))
			{
				args[0] = isOmitObjectAsSubChannel ? "" : StringUtil.fitToMinLength(String(args[0]), minSubChannelLength);
			}
			args = [prefixByPriority[priority], timeStamp, channelString].concat(args);
			var fullString:String = args.join(" ");
			
			// Add to log data
			lastLogLine = new LogLine(fullString, lastLogLine);
			
			// Trace
			if (isTraceEnabled)
			{
				trace(fullString);
				//-tracer(fullString, INFO_PRIORITY);
			}
			
			// Custom trace method
			if (onTrace != null)
			{
				onTrace(fullString);
			}
			
			// Console
			if (isConsoleEnabled && console && (consolePriorityByChannelLookup[channel] || defaultConsolePriority) <= priority)
			{
				args[0] = args[2] = "";
				var consoleString:String = args.join(" ");
				console.ch(channel, consoleString, consolePriorityByLogPriority[priority]);
			}
			
			return fullString;
		}
		
		private function checkReportBug(priority:int, args:Array, string:String):void
		{
			if (priority >= reportBugPriority)
			{
				var error:Error;
				for each (var object:Object in args)
				{
					error = object as Error;
					if (error)
					{
						break;
					}
				}
				
				if (priority < FATAL_PRIORITY)//?
				{
					BugReporter.reportError(string, error);
				}
				else
				{
					BugReporter.reportFatal(string, error);
				}
			}
		}
		
		public function showConsole():void
		{
			//if (isConsoleEnabled && console)
			{
				console.visible = true;
			}
		}
		
		public function hideConsole():void
		{
			//if (isConsoleEnabled && console)
			{
				console.visible = false;
			}
		}
		
		// To avoid loosing initialization log when it becomes too long
		public function captureInitializationLog():void
		{
			if (!_initializationLog)
			{
				_initializationLog = getAllLog();
			}
		}
		
		public function getAllLog():String
		{
			var time:int = getTimer();
			var memory:int = System.totalMemory;
			var logText:String = firstLogLine ? firstLogLine.getLogFromThis() : "";
			//var log:String = console ? console.getAllLog() : null;
			log(Channel.LOG, "(log.getAllLog() execution time: " + (getTimer() - time) + " msec consumedmemory: " +
					(System.totalMemory - memory) + " bytes log length: " + logText.length + ")");
			return logText;

//was
//			CONFIG::mobile
//			{
//				var logObject:Object = mobileLogWriter.getLogsData();
//				if (logObject)
//				{
//					return logObject.log;
//				}
//			}
//
//			return console.getAllLog();
		}
		
		public function getPreviousLog():String
		{
//			CONFIG::mobile
//			{
//				var logObject:Object = mobileLogWriter.getLogsData();
//				return logObject ? logObject.oldLog : "";
//			}
			
			return null;
		}
		
		public function saveLog():void
		{
			// write to file for air or to sharedobject? otherwise // or writeBufferToFile()
		}
		
		//was 
		public function writeBufferToFile():void
		{
//			CONFIG::mobile
//			{
//				mobileLogWriter.writeBufferToFile();
//			}
		}
		
		//was sendMobileLog
		public function sendLog(callback:Function = null):void
		{
//			CONFIG::mobile
//			{
//				if (logSender.isLogSent)
//				{
//					mobileLogWriter.writeBufferToFile();
//					var log:String = getAllLog();
//					var previousLog:String = getPreviousLog();
//					logSender.sendLog(log, callback);
//				}
//			}
		}
		
		public function addConsoleCommand(command:String, callback:Function):void
		{
			if (!console)
			{
				warn(Channel.LOG, "(addConsoleCommand) Console instance is not set yet!", "console:", console);
				return;
			}
			
			if (command && callback != null)
			{
				console.config.commandLineAllowed = true;
				console.addSlashCommand(command, callback);
			}
		}
		
		protected function addConsoleCommands():void
		{
			console.config.commandLineAllowed = true;
			// "/log 1 preloader,application,resource"
			console.addSlashCommand("log", logCommandHandler);
			// "/logon preloader,application,resource"
			console.addSlashCommand("logon", logonCommandHandler);
			// "/logoff preloader,application,resource"
			console.addSlashCommand("logoff", logoffCommandHandler);
			// "/channel 3 preloader,application,resource"
			console.addSlashCommand("console", consoleCommandHandler);
			// "/channelon preloader,application,resource"
			console.addSlashCommand("consoleon", consoleonCommandHandler);
			// "/channeloff preloader,application,resource"
			console.addSlashCommand("consoleoff", consoleoffCommandHandler);
		}
		
		private function logCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 2)
			{
				return;
			}
			var priority:int = int(paramArray[0]);
			var channelArray:Array = String(paramArray[1]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setLogChannelPriority(channel, priority);
			}
		}
		
		private function logonCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 1)
			{
				return;
			}
			var channelArray:Array = String(paramArray[0]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setLogChannelPriority(channel, LOG_PRIORITY);
			}
		}
		
		private function logoffCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 1)
			{
				return;
			}
			var channelArray:Array = String(paramArray[0]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setLogChannelPriority(channel, WARN_PRIORITY);
			}
		}
		
		private function consoleCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 2)
			{
				return;
			}
			var priority:int = int(paramArray[0]);
			var channelArray:Array = String(paramArray[1]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setConsoleChannelPriority(channel, priority);
			}
		}
		
		private function consoleonCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 1)
			{
				return;
			}
			var channelArray:Array = String(paramArray[0]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setConsoleChannelPriority(channel, LOG_PRIORITY);
			}
		}
		
		private function consoleoffCommandHandler(params:String):void
		{
			var paramArray:Array = params.split(" ");
			if (paramArray.length < 1)
			{
				return;
			}
			var channelArray:Array = String(paramArray[0]).split(",");
			
			for (var i:int = 0; i < channelArray.length; i++)
			{
				var channel:String = channelArray[i];
				setConsoleChannelPriority(channel, WARN_PRIORITY);
			}
		}
//		
//		private function tracer(string:String, priority:int = -1):void
//		{
//			lastLogLine = new LogLine(string, lastLogLine);
//			
//			trace(string);
//			
//			if (onTrace != null)
//			{
//				onTrace(string);
//			}
//
////			if (mobileLogWriter)
////			{
////				mobileLogWriter.write(string);
////				CONFIG::emulator
////				{
////					if (priority >= WARN_PRIORITY)
////					{
////						mobileLogWriter.writeToErrorsFile(string);
////					}
////				}
//////				if (priorityCounterCallback != null)
//////				{
//////					priorityCounterCallback(priority);
//////				}
////			}
////			
////			if (ExternalInterface.available)
////			{
////				try
////				{
////					ExternalInterface.call("console.log", string);
////				}
////				catch (error:Error)
////				{
////				}
////			}
//		}
		
	}
}
//
//class LogLine
//{
//	
//	public var text:String;
//
//	public var prev:LogLine;
//	public var next:LogLine;
//	
//	public function LogLine(text:String, prev:LogLine)
//	{
//		this.text = text;
//		this.prev = prev;
//		if (prev)
//		{
//			prev.next = this;
//		}
//	}
//	
//	public function toString():String
//	{
//		return text;
//	}
//	
//	// Due to "JavaScript optimization" book must be much faster than getLogTillThis()
//	// (Using join(array) should be even faster - todo check)
//	public function getLogFromThis(delim:String = "\n"):String
//	{
//		var logLine:LogLine = this;
//		var result:String = "";
//		do
//		{
//			result += logLine.text;
//			logLine = logLine.next;
//		}
//		while (logLine);
//		return result;
//	}
////-	
////	public function getLogTillThis(delim:String = "\n"):String
////	{
////		var logLine:LogLine = this;
////		var result:String = "";
////		do
////		{
////			result = logLine.text + result;
////			logLine = logLine.prev;
////		}
////		while (logLine);
////		return result;
////	}
//	
//}
