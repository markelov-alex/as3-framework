package napalm.framework.utils
{
	CONFIG::mobile
	{
		import flash.filesystem.File;
	}

	/**
	 * URLUtil.
	 * 
	 * @author alex.panoptik@gmail.com
	 */
	public class URLUtil
	{
		
		// Class constants
		
		// Class variables
		
		// Class methods

		// GET URL
		
		public static function buildGetURL(url:String, vars:Object):String
		{
			if (!url || !vars)
			{
				return url;
			}

			var varsString:String = "";
			var ampersand:String = "";
			for (var propName:String in vars)
			{
				var value:String = vars[propName];
				varsString += ampersand + propName + (value ? "=" + value : "");
				ampersand = "&";
			}

			var uniteChar:String = url.indexOf("?") == -1 ? "?" : "&";
			return url + uniteChar + varsString;
		}

		public static function addGetParamsSuffix(url:String, getParamsSuffix:String):String
		{
			if (!url)
			{
				return url;
			}

			var uniteChar:String = url.lastIndexOf("?") == -1 ? "?" : "&";
			return url + uniteChar + getParamsSuffix;
		}

		public static function forceCacheFor(url:String):String
		{
			var versionSuffix:String = "t=" + Math.round(new Date().time / 1000);//Math.round(new Date().time / 3600 / 1000);//
			return URLUtil.addGetParamsSuffix(url, versionSuffix);
		}
		
		// Path

		public static function endWithSlash(url:String):String
		{
			if (!url)
			{
				return url;
			}
			
			return url.lastIndexOf("/") != url.length - 1 ? url + "/" : url;
		}

		/**
		 * "http://any/some/dir/file" -> "file"
		 * "http://any/some/dir/" -> ""
		 * "http://any/some/dir" -> "dir"
		 * 
		 * Check by last "/".
		 * 
		 * @param url
		 * @return
		 */
		public static function getFileName(url:String):String
		{
			if (!url)
			{
				return url;
			}

			var index:int = url.lastIndexOf("/");
			return index > -1 && index < url.length - 1 ? url.slice(index + 1) : "";
		}
		
		/**
		 * "http://any/some/dir/file" -> "http://any/some/dir/"
		 * "http://any/some/dir/" -> "http://any/some/dir/"
		 * "http://any/some/dir" -> "http://any/some/"
		 * 
		 * Check by last "/".
		 * 
		 * @param url
		 * @return
		 */
		public static function getDirectoryPath(url:String):String
		{
			if (!url)
			{
				return url;
			}

			var index:int = Math.max(url.lastIndexOf("/"), url.lastIndexOf("\\"));
			return index > -1 && index < url.length - 1 ? url.slice(0, index + 1) : url;
		}

		/**
		 * "http://somedir/dir1/dir2/dir3/filename.ext" -> "http://somedir/filename.ext"
		 * "somedir/dir1/dir2/dir3/filename.ext" -> "somedir/filename.ext"
		 * "somedir/dir1/dir2/dir3/" -> "somedir/"
		 * "somedir/dir1/dir2/dir3" -> "somedir/dir3"
		 *
		 * @param filePath
		 * @return
		 */
		public static function abolishSubdirectories(filePath:String):String
		{
			// 
			var fileNameParts:Array = filePath.split("/");

			var topDirName:String = fileNameParts[0];
			// Check for protocol "xxx://"
			if (topDirName.indexOf(":") == topDirName.length - 1 && !fileNameParts[1])
			{
				topDirName += "//" + fileNameParts[2];
			}
			
			var fileName:String = fileNameParts[fileNameParts.length - 1];

			return topDirName + "/" + fileName;
		}

		/**
		 * "http://any/some/dir.dir/file.ext" -> "http://any/some/dir.dir/file"
		 * "http://any/some/dir.dir/" -> "http://any/some/dir.dir/"
		 * "http://any/some/dir.dir" -> "http://any/some/dir"
		 *
		 * @param filePath
		 * @return
		 */
		public static function stripExtension(filePath:String):String
		{
			if (!filePath)
			{
				return null;
			}

			var separator:String = "/";
			CONFIG::mobile
			{
				separator = File.separator;
			}
			var lastDotIndex:int = filePath.lastIndexOf(".");
			var lastSeparatorIndex:int = filePath.lastIndexOf(separator);
			if (lastDotIndex != -1 && lastDotIndex > lastSeparatorIndex)
			{
				return filePath.slice(0, lastDotIndex);
			}
			return filePath;
		}

		public static function checkIsZipFileName(filePath:String):Boolean
		{
			var index:int = filePath.lastIndexOf(".zip");
			//trace("##### (checkIsZipFileName) <return>", "filePath:", filePath, "index:", index, "return:", index == filePath.length - 3);
			return index == filePath.length - 4;
		}

		//no need
		//public static function checkIsFontFileName(filePath:String):Boolean
		//{
		//	if (!filePath)
		//	{
		//		return false;
		//	}
		//	
		//	var extIndex:int = filePath.length - 4;
		//	return filePath.lastIndexOf(".otf") == extIndex || filePath.lastIndexOf(".ttf") == extIndex;
		//}
		
	}
}
