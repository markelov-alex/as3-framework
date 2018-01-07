package napalm.framework.utils
{

	/**
	 * DateUtil.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class DateUtil
	{

		// Class constants

		// Class variables

		// Class methods

		// "hh:mm:ss"
		public static function getCurrentTimeString(delimeter:String = ":"):String
		{
			var date:Date = new Date();

			var hours:Number = date.getHours();
			var minutes:Number = date.getMinutes();
			var seconds:Number = date.getSeconds();

			var hoursString:String = hours < 10 ? "0" + String(hours) : String(hours);
			var minutesString:String = minutes < 10 ? "0" + String(minutes) : String(minutes);
			var secondsString:String = seconds < 10 ? "0" + String(seconds) : String(seconds);

			return hoursString + delimeter + minutesString + delimeter + secondsString;
		}

		// "hh:mm:ss.msc"
		public static function getCurrentFullTimeString(delimeter:String = ":", msecDelimeter:String = "."):String
		{
			var date:Date = new Date();

			var hours:Number = date.getHours();
			var minutes:Number = date.getMinutes();
			var seconds:Number = date.getSeconds();
			var miliseconds:Number = date.getMilliseconds();

			var hoursString:String = hours < 10 ? "0" + String(hours) : String(hours);//?FormatUtil.fitMinLengthWithZeros(hours, 2)
			var minutesString:String = minutes < 10 ? "0" + String(minutes) : String(minutes);
			var secondsString:String = seconds < 10 ? "0" + String(seconds) : String(seconds);
			var milisecondsString:String = miliseconds < 100 ? (miliseconds < 10 ? "00" + String(miliseconds) : "0" + String(miliseconds)) : String(miliseconds);

			return hoursString + delimeter + minutesString + delimeter + secondsString + msecDelimeter + milisecondsString;
		}

		// "yyyy.mm.dd"
		public static function getCurrentDateString(delimeter:String = "."):String
		{
			var date:Date = new Date();

			var years:Number = date.getFullYear();
			var months:Number = date.getMonth();
			var days:Number = date.getDate();

			var yearsString:String = years < 10 ? "0" + String(years) : String(years);//?FormatUtil.fitMinLengthWithZeros(hours, 2)
			var monthsString:String = months < 10 ? "0" + String(months) : String(months);
			var daysString:String = days < 10 ? "0" + String(days) : String(days);

			return yearsString + delimeter + monthsString + delimeter + daysString;
		}

		/**
		 * Получить  количество секунд в дате формата "2013-11-08 13:31:56".
		 *
		 * @param    timeStampString
		 * @return
		 */
			//was getSecondInTimeStampString
		public static function getSecondByTimeStampString(timeStampString:String):int
		{
			var timeStampParts:Array = timeStampString.split(" ");
			var dateParts:Array = timeStampParts[0].split("-");
			var timeParts:Array = timeStampParts[1].split(":");

			var date:Date = new Date(dateParts[0], dateParts[1] - 1, dateParts[2], timeParts[0], timeParts[1], timeParts[2]);
			return ((date.time / 1000) + date.timezoneOffset * 60);
		}

		/**
		 * Seconds to "DD", ..., "DD:HH:MM:SS" string.
		 *
		 * @param    seconds
		 * @return
		 */
			//was convertSecondsToTimeString
		public static function convertSecondsToTimeStamp(seconds:int, isGetDay:Boolean = false, isGetHour:Boolean = false, isGetMinute:Boolean = false, isGetSecond:Boolean = false, delimiter:String = ":"):String
		{
			var day:int = 0;
			var hour:int = 0;
			var min:int = 0;
			var sec:int = 0;
			var resultValue:String = "";

			if (isGetDay)
			{
				day = Math.ceil(seconds / 86400);
				resultValue += day + delimiter;
			}
			if (isGetHour)
			{
				hour = Math.floor(seconds / 3600);
				resultValue += FormatUtil.fitMinLengthWithZeros(hour, 2) + delimiter;
			}
			if (isGetMinute)
			{
				min = Math.floor(seconds / 60) % 60;
				resultValue += FormatUtil.fitMinLengthWithZeros(min, 2) + delimiter;
			}
			if (isGetSecond)
			{
				sec = seconds % 60;
				resultValue += FormatUtil.fitMinLengthWithZeros(sec, 2);
			}

			//no need
			//if (resultValue.charAt(0) == delimiter)
			//{
			//	resultValue = resultValue.slice(1);
			//}
			if (resultValue.charAt(resultValue.length - 1) == delimiter)
			{
				resultValue = resultValue.slice(0, resultValue.length - 1);
			}

			return resultValue;
		}
//
//		//was getTimeStringFromUnix
//		public static function getTimeStampByUnixTime(unixSeconds:int, includeDay:Boolean = true):String
//		{
//			var date:Date = new Date();
//			date.time = unixSeconds * 1000;
//
//			var day:Number = date.getDate();
//			var hours:Number = date.getHours();
//			var minutes:Number = date.getMinutes();
//			var seconds:Number = date.getSeconds();
//
//			var hoursString:String = hours < 10 ? "0" + String(hours) : String(hours);
//			var minutesString:String = minutes < 10 ? "0" + String(minutes) : String(minutes);
//			var secondsString:String = seconds < 10 ? "0" + String(seconds) : String(seconds);
//
//			return (includeDay ? (day + ":") : "") + hoursString + ":" + minutesString + ":" + secondsString;
//		}
//
//		public static function getDateStringFromUnix(unixSeconds:int = -1):String
//		{
//			var date:Date = new Date();
//
//			if (unixSeconds != -1)
//			{
//				date.time = unixSeconds * 1000;
//			}
//
//			var day:Number = date.getDate();
//			var month:Number = date.getMonth() + 1;
//			var year:Number = date.getFullYear()
//
//			var dayString:String = day < 10 ? "0" + String(day) : String(day);
//			var monthString:String = month < 10 ? "0" + String(month) : String(month);
//			var yearString:String = String(year);
//
//			return dayString + "." + monthString + "." + year;
//		}
//
//		public static function getDateStringByDateDifference(dateDifference:Number = 0):String
//		{
//			var date:Date = new Date();
//			date.time += (dateDifference * 86400) * 1000;
//			return getDateStringFromUnix(date.time / 1000);
//		}

	}
}
