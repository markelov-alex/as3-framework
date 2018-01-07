package napalm.framework.log
{
	import napalm.framework.utils.DebugUtil;
	
	/**
	 * LogLine.
	 *
	 *
	 */
	internal class LogLine
	{
		
		public var text:String;
		
		public var prev:LogLine;
		public var next:LogLine;
		
		public function LogLine(text:String, prev:LogLine)
		{
			this.text = text;
			this.prev = prev;
			if (prev)
			{
				prev.next = this;
			}
		}
		
		public function toString():String
		{
			return text;
		}
		
		// Due to "JavaScript optimization" book must be much faster than getLogTillThis()
		// (Using join(array) should be even faster - todo check)
		public function getLogFromThis(sep:String = "\n"):String
		{
			var logLine:LogLine = this;
			var textArray:Array = [];
			DebugUtil.getTimeChange("getLogFromThis");
			while (logLine)
			{
				textArray[textArray.length] = logLine.text;
				logLine = logLine.next;
			}
			var temp:String = textArray.join(sep);
			trace(this, "getLogFromThis [by textArray.join()] msec:", DebugUtil.getTimeChangeMsec("getLogFromThis"));
//			return textArray.join(sep);
			
			logLine = this;
			//var logLine:LogLine = this;
			var result:String = "";
			do
			{
				result += logLine.text + sep;
				logLine = logLine.next;
			}
			while (logLine);
			trace(this, "getLogFromThis [by result+=logLine.text] msec:", DebugUtil.getTimeChangeMsec("getLogFromThis"));
			return result;
		}
//-	
//		public function getLogTillThis(delim:String = "\n"):String
//		{
//			var logLine:LogLine = this;
//			var result:String = "";
//			do
//			{
//				result = logLine.text + result;
//				logLine = logLine.prev;
//			}
//			while (logLine);
//			return result;
//		}
		
	}
}
