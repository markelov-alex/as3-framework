package napalm.framework.utils
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	CONFIG::mobile
	{
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
	}

	/**
	 * FileUtil.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class FileUtil
	{
		
		// Class constants
		
		public static const APP_STORAGE_URL_PREFIX:String = "app-storage:/";
		
		// Class variables
		
		private static var infoByFileStreamLookup:Dictionary = new Dictionary();
		private static var callbackByFileLookup:Dictionary = new Dictionary();
		private static var fileStreamCacheArray:Array = [];
		
		// Class methods

//?		public static function cleanUpAll():void
//		{
//			CONFIG::mobile
//			{
//				for (var fileStream:FileStream in infoByFileStreamLookup)
//				{
//					clearFileStream(fileStream);
//				}
//				for (var file:File in callbackByFileLookup)
//				{
//					clearFile(file);
//				}
//			}
//		}

		// Paths (see alse URLUtil)

//		public static function treatAppStorageURL(path:String):String
//		{
//			if (!path)
//			{
//				return path;
//			}
//
//			var index:int = path.indexOf(APP_STORAGE_URL_PREFIX);
//			return index == -1 ? APP_STORAGE_URL_PREFIX + path : path;
//		}
		
		// Files

		CONFIG::mobile
		{
			/**
			 * (File|String) -> File
			 * 
			 * Use defaultFileInstance to save memory reusing File instances.
			 */
			public static function getFile(fileOrPath:*, defaultFileInstance:File = null):File
			{
				// File -> File
				if (fileOrPath is File)
				{
					return fileOrPath as File;
				}
				
			//TODO test
				// String -> File
				if (fileOrPath is String)
				{
					// Mobile
					if (Device.isMobile)
					{
						// (Check local storage first, because it could be updated hence could contain the latest version of file)
						var fileInStorage:File = File.applicationStorageDirectory.resolvePath(fileOrPath as String);
						if (fileInStorage.exists)
						{
							return fileInStorage;
						}
						
						// (If file does not exist in app directory too return fileInStorage, because it could be used for writing)
						var fileInAppDir:File = File.applicationDirectory.resolvePath(fileOrPath as String);
						return fileInAppDir && fileInAppDir.exists ? fileInAppDir : fileInStorage;
					}
					
					// Desktop
					var file:File = defaultFileInstance || new File();
					file.nativePath = fileOrPath as String;
					return file;
				}
				
				// else -> null
				return null;
			}
			
			/**
			 * (File|String) -> File
			 *
			 * Use defaultFileInstance to save memory reusing File instances.
			 */
			public static function getOrCreateDirectory(fileOrPath:*, defaultFileInstance:File = null):File
			{
				var directoryFile:File = getFile(fileOrPath, defaultFileInstance);
				
				if (directoryFile && !directoryFile.exists)
				{
					directoryFile.createDirectory();
				}
	
				return directoryFile;
			}
		}

		public static function checkExists(filePath:String):Boolean
		{
			CONFIG::mobile
			{
				var file:File = File.applicationStorageDirectory.resolvePath(filePath);
				return file && file.exists;
			}
			return false;
		}
		
		public static function read(fileOrPath:*):ByteArray
		{
			var byteArray:ByteArray = null;
			CONFIG::mobile
			{
				var file:File = getFile(fileOrPath);
				Log.info(Channel.UTIL, FileUtil, "(read) fileOrPath:", fileOrPath, "file:", file, "nativePath:", file.nativePath, ".exists:", file.exists);//, "onComplete:", onComplete
				if (file.exists)
				{
					Log.info(Channel.UTIL, FileUtil, "  (read) <fileStream.readBytes> file.exists:", file.exists);
					byteArray = new ByteArray();

					var fileStream:FileStream = getFileStream();
					fileStream.open(file, FileMode.READ);
					fileStream.readBytes(byteArray);
					fileStream.close();
				}
			}

			return byteArray;
		}

		public static function readText(fileOrPath:*):String
		{
			var byteArray:ByteArray = read(fileOrPath);
			return byteArray.readUTFBytes(byteArray.bytesAvailable);
		}

		public static function readJSON(fileOrPath:*):Object
		{
			var text:String = String(read(fileOrPath));
			try
			{
				var json:Object = text ? JSON.parse(text) : null;
			}
			catch (error:Error)
			{
				Log.error(Channel.UTIL, FileUtil, "FileUtil.readJSONFile. Cannot parse text from file:" + 
						(fileOrPath.hasOwnProperty("url") ? fileOrPath.url : fileOrPath) + " Error:", error);
			}
			return json;
		}

		public static function readAsync(fileOrPath:*, onComplete:Function):Boolean
		{
			CONFIG::mobile
			{
				var file:File = getFile(fileOrPath);
				Log.info(Channel.UTIL, FileUtil, "(readAsync) fileOrPath:", fileOrPath, "file:", file.nativePath, ".exists:", file.exists);//, "onComplete:", onComplete
				if (file.exists)
				{
					Log.info(Channel.UTIL, FileUtil, "  (readAsync) <fileStream.readBytes> file.exists:", file.exists);

					var fileStream:FileStream = getFileStream();
					if (onComplete != null)
					{
						// Register callback
						infoByFileStreamLookup[fileStream] = new FileStreamInfo(true, file.nativePath, onComplete);
					}
					// Listeners
					fileStream.addEventListener(Event.COMPLETE, fileStream_completeHandler);
					fileStream.addEventListener(IOErrorEvent.IO_ERROR, fileStream_ioErrorHandler);
					fileStream.addEventListener(Event.CLOSE, fileStream_closeHandler);

					// Read
					fileStream.openAsync(file, FileMode.READ);
					return true;
				}
			}

			return false;
		}

		public static function write(fileOrPath:*, byteArray:ByteArray):Boolean
		{
			CONFIG::mobile
			{
				Log.info(Channel.UTIL, FileUtil, "(write) fileOrPath:", fileOrPath, 
						"byteArray:", StringUtil.cutStringInMiddle(String(byteArray), 200));

				if (!checkAvailableSpaceFor(byteArray))
				{
					return false;
				}

				// Init
				var file:File = getFile(fileOrPath);
				//if (Device.isIOS)
				//{
				//	file.preventBackup = true;
				//}

				var fileStream:FileStream = getFileStream();
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeBytes(byteArray);
				fileStream.close();
				
				return true;
			}
			
			return false;
		}

		public static function writeText(fileOrPath:*, text:String):Boolean
		{
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeUTFBytes(text);
			return write(fileOrPath, byteArray);
		}

		public static function writeJSON(fileOrPath:*, json:Object):Boolean
		{
			var text:String = JSON.stringify(json);
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeUTFBytes(text);
			return write(fileOrPath, byteArray);
		}

		public static function writeAsync(fileOrPath:*, byteArray:ByteArray, onComplete:Function = null):Boolean
		{
			CONFIG::mobile
			{
				Log.info(Channel.UTIL, FileUtil, "(writeAsync) fileOrPath:", fileOrPath, 
						"byteArray:", StringUtil.cutStringInMiddle(String(byteArray), 200));
				
				if (!checkAvailableSpaceFor(byteArray))
				{
					return false;
				}

				// Init
				var file:File = getFile(fileOrPath);
				//if (Device.isIOS)
				//{
				//	file.preventBackup = true;
				//}

				var fileStream:FileStream = getFileStream();
				// Register fileStream
				infoByFileStreamLookup[fileStream] = new FileStreamInfo(false, file.nativePath, onComplete, byteArray);
				// Listeners
				fileStream.addEventListener(Event.COMPLETE, fileStream_completeHandler);
				fileStream.addEventListener(IOErrorEvent.IO_ERROR, fileStream_ioErrorHandler);
				fileStream.addEventListener(Event.CLOSE, fileStream_closeHandler);

				// Write
				fileStream.openAsync(file, FileMode.WRITE);
				fileStream.writeBytes(byteArray);
				fileStream.close();
				
				return true;
			}
			
			return false;
		}

		/**
		 * @param fileOrPathArray
		 * @return true if at least one file in array was deleted
		 */
		public static function deleteFiles(fileOrPathArray:Array, isDeleteDirIfEmpty:Boolean = false):Boolean
		{
			CONFIG::mobile
			{
				Log.info(Channel.UTIL, FileUtil, "(deleteFiles) fileOrPathArray.length:", 
						fileOrPathArray ? fileOrPathArray.length : null);
				var result:Boolean = false;
				for each (var fileOrPath:* in fileOrPathArray)
				{
					var file:File = getFile(fileOrPath);
					if (file.exists)
					{
						Log.info(Channel.UTIL, FileUtil, " (deleteFiles) delete file:", file.nativePath);
						file.deleteFile();
						result = true;
						
						if (isDeleteDirIfEmpty && file.parent && !file.parent.getDirectoryListing().length)
						{
							Log.info(Channel.UTIL, FileUtil, "  (deleteFiles) delete empty directory:", file.parent.nativePath);
							file.parent.deleteDirectory();
						}
					}
				}
				return result;
			}
			return false;
		}

		public static function deleteAsync(fileOrPath:*, onComplete:Function = null):Boolean
		{
			Log.info(Channel.UTIL, FileUtil, "(deleteAsync) fileOrPath:", fileOrPath, "onComplete:", onComplete);
			CONFIG::mobile
			{
				var file:File = getFile(fileOrPath);
				if (file && file.exists)
				{
					// Register
					if (callbackByFileLookup[file] && onComplete != null && callbackByFileLookup[file] != onComplete)
					{
						Log.warn(Channel.UTIL, FileUtil, " (deleteAsync) Another callback is already registered with this " +
								"File instance! Previous callback will be overwritten by new one! file:", file.nativePath);
					}
					if (onComplete != null)
					{
						callbackByFileLookup[file] = onComplete;
					}
					// Listeners
					file.addEventListener(Event.COMPLETE, file_completeHandler);
					file.addEventListener(IOErrorEvent.IO_ERROR, file_ioErrorHandler);

					Log.info(Channel.UTIL, FileUtil, " (deleteAsync) delete file:", file.nativePath);
					file.deleteFileAsync();
					return true;
				}
			}
			return false;
		}

		public static function saveBitmapAsPNG(fileOrPath:*, bitmapData:BitmapData):Boolean
		{
			if (!fileOrPath || !bitmapData)
			{
				return false;
			}

			CONFIG::mobile
			{
				var file:File = getFile(fileOrPath);
				var byteArray:ByteArray = PNGEncoder.encode(bitmapData);

				// Write
				return write(file, byteArray);
			}
			return false;
		}

		CONFIG::mobile
		{
			public static function createAndRunBatFile(fileOrPath:*, content:String):File
			{
				var file:File = getFile(fileOrPath);
				writeText(file, content);

				file.openWithDefaultApplication();

				return file;
			}

			private static function checkAvailableSpaceFor(byteArray:ByteArray):Boolean
			{
				var spaceAvailable:Number = File.applicationStorageDirectory.spaceAvailable;
				var fileSize:int = byteArray ? byteArray.length : 0;
	
				if (spaceAvailable < fileSize)
				{
					Log.error(Channel.UTIL, FileUtil, "Not enough free disk space! spaceAvailable:", File.applicationStorageDirectory.spaceAvailable, "fileSize:", fileSize);
					return false;
				}

				return true;
			}
			
			/**
			 * Get from cache or create.
			 */
			private static function getFileStream():FileStream
			{
				return fileStreamCacheArray.length ? fileStreamCacheArray.pop() as FileStream : new FileStream();
			}
	
			/**
			 * Clear all links to fileStream instance and return it to cache.
			 * 
			 * @param fileStream
			 */
			private static function clearFileStream(fileStream:FileStream):void
			{
				if (!fileStream)
				{
					return;
				}
	
				// Unregister fileStream
				delete infoByFileStreamLookup[fileStream];
				
				// Listeners
				fileStream.removeEventListener(Event.COMPLETE, fileStream_completeHandler);
				fileStream.removeEventListener(IOErrorEvent.IO_ERROR, fileStream_ioErrorHandler);
				fileStream.removeEventListener(Event.CLOSE, fileStream_closeHandler);
	
				// Return to cache
				fileStreamCacheArray[fileStreamCacheArray.length] = fileStream;
			}
	
			private static function clearFile(file:File):void
			{
				if (!file)
				{
					return;
				}
	
				// Unregister file
				delete callbackByFileLookup[file];
	
				// Listeners
				file.removeEventListener(Event.COMPLETE, file_completeHandler);
				file.removeEventListener(IOErrorEvent.IO_ERROR, file_ioErrorHandler);
			}

			// Directories

			public static function traceDir(directory:File, propertyName:String = "name", fileDelim:String = "\n", nestingShift:String = ""):String
			{
				if (!directory)
				{
					return null;
				}

				// File
				var result:String = nestingShift + directory[propertyName] + fileDelim;

				// Directory listing recursively
				var directoryListing:Array = directory.isDirectory ? directory.getDirectoryListing() : null;
				for each (var file:File in directoryListing)
				{
					result += traceDir(file, propertyName, fileDelim, nestingShift + "-")
				}

				return result;
			}
		}

		// Class event handlers

		CONFIG::mobile
		{
			private static function callCompleteOnFileStreamFinished(fileStream:FileStream):void
			{
				var info:FileStreamInfo = infoByFileStreamLookup[fileStream] as FileStreamInfo;
				Log.info(Channel.UTIL, FileUtil, "(fileStream_completeHandler)", info);

				var byteArray:ByteArray = null;
				if (info.isRead)
				{
					byteArray = new ByteArray();

					fileStream.readBytes(byteArray);
					fileStream.close();
				}
				else
				{
					byteArray = info.writeByteArray;
				}

				//-?clearFileStream(fileStream);

				FunctionUtil.call(info.onComplete, [byteArray]);
			}
			
			//(not called, close dispatched without dispatching complete...)
			private static function fileStream_completeHandler(event:Event):void
			{
				var fileStream:FileStream = event.target as FileStream;
				//?
				//callCompleteOnFileStreamFinished(fileStream);
			}
	
			private static function fileStream_ioErrorHandler(event:Event):void
			{
				var fileStream:FileStream = event.target as FileStream;
				var info:FileStreamInfo = infoByFileStreamLookup[fileStream] as FileStreamInfo;

				Log.error(Channel.UTIL, FileUtil, "(fileStream_ioErrorHandler)", info, event);

				callCompleteOnFileStreamFinished(fileStream);

				clearFileStream(fileStream);
//?was				//-?clearFileStream(fileStream);
//				
//				//?
//				FunctionUtil.call(info.onComplete, [null]);
			}
	
			private static function fileStream_closeHandler(event:Event):void
			{
				var fileStream:FileStream = event.target as FileStream;
				var info:FileStreamInfo = infoByFileStreamLookup[fileStream] as FileStreamInfo;
				Log.info(Channel.UTIL, FileUtil, "(fileStream_closeHandler)", info);

				callCompleteOnFileStreamFinished(fileStream);
				
				clearFileStream(fileStream);
			}

			private static function file_completeHandler(event:Event):void
			{
				var file:File = event.target as File;
				var onComplete:Function = callbackByFileLookup[file] as Function;
				Log.info(Channel.UTIL, FileUtil, "(file_completeHandler) onComplete:", onComplete, "nativePath:", file.nativePath);

				FunctionUtil.call(onComplete, [file]);
				clearFile(file);
			}

			private static function file_ioErrorHandler(event:Event):void
			{
				var file:File = event.target as File;
				var onComplete:Function = callbackByFileLookup[file] as Function;

				Log.error(Channel.UTIL, FileUtil, "(file_ioErrorHandler) onComplete:", onComplete, "event:", event, "nativePath:", file.nativePath);

				//?
				FunctionUtil.call(onComplete, [file]);
				clearFile(file);
			}
		}

//		public static function checkIfFileIsEncodable(filePath:String, withOutExtension: Boolean = false):Boolean
//		{
//			if (withOutExtension) 
//			{
//				var extensions: Array = [".json", ".txt"];
//				for each (var extension: String in extensions)
//				{
//					if (checkIfFileIsEncodable(filePath + extension, false))
//					{
//						return true;
//					}
//				}
//			}
//			filePath = filePath.toLowerCase().replace(/\\/g, "/");
//			for each (var fileNameToEncode: String in fileNamesToEncodeArray) {
//				if (filePath.indexOf(fileNameToEncode) != -1)
//				{
//					return true;
//				}
//			}
//			return false;
//		}
//		
//		public static function addFileNamesToEncode(...fileNames): void
//		{
//			for each (var fileName: String in fileNames) 
//			{
//				fileNamesToEncodeArray[fileNamesToEncodeArray.length] = fileName.toLowerCase().replace(/\\/g, "/");
//			}
//		}
//				
//		public static function encodeBase64(byteArray: ByteArray): ByteArray
//		{
//			var encoded: String = Base64.encode(byteArray);
//			byteArray = new ByteArray();
//			byteArray.writeUTFBytes(encoded);
//			byteArray.position = 0;
//			return byteArray;
//		}
//		
//		public static function decodeBase64(byteArray: ByteArray): ByteArray
//		{
//			byteArray = Base64.decode(byteArray.readUTFBytes(byteArray.bytesAvailable));
//			byteArray.position = 0;
//			return byteArray;
//		}
		
	}
}

import flash.utils.ByteArray;

class FileStreamInfo
{
	
	public var isRead:Boolean;
	public var filePath:String;
	public var onComplete:Function;
	public var writeByteArray:ByteArray;
	
	public function FileStreamInfo(isRead:Boolean, filePath:String, onComplete:Function = null, writeByteArray:ByteArray = null)
	{
		this.isRead = isRead;
		this.filePath = filePath;
		this.onComplete = onComplete;
		this.writeByteArray = writeByteArray;
	}
	
	public function toString():String
	{
		return "[" + (isRead ? "read" : "write") + " filePath: " + filePath + "]";
	}
	
}
