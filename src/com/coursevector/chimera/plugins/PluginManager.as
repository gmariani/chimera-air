package com.coursevector.chimera.plugins {
	
	import com.adobe.ucf.UCFSignatureValidator;
	import com.coursevector.chimera.plugins.PluginData;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipEvent;
	import deng.fzip.FZipFile;
	
	import flash.display.DisplayObject;
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.SWFLoader;
	import mx.events.CloseEvent;
	import mx.managers.SystemManager;
	import mx.utils.UIDUtil;
	
	public class PluginManager extends EventDispatcher {
		
		private var pluginLoader:SWFLoader = new SWFLoader();
		private var tmpDir:File; // The directory that plugins are unpacked into.
		private var pluginHome:File; // The directory where plugins live.
		private var browseFile:File; // File for browsing for local plugins.
		private var zipFileParseError:Boolean; // Indicates whether the plugin was successfully unzipped.
		
		// Some namespaces we need for parsing and validating XML.
		
		private const AIR_NS:Namespace = new Namespace("http://ns.adobe.com/air/application/1.5.3");
		
		private var _plugins:ArrayCollection = new ArrayCollection();
		
		public function PluginManager() {
			// Set up the loader context for the SWFLoader that loads plugins
			var pluginLoaderContext:LoaderContext = new LoaderContext();
			pluginLoaderContext.allowLoadBytesCodeExecution = true;
			pluginLoader.loaderContext = pluginLoaderContext;
			
			// Get a reference to the plugin directory. If it doesn't exist, create it.
			pluginHome = File.applicationStorageDirectory.resolvePath("plugins");
			if (!pluginHome.exists) pluginHome.createDirectory();
		}
		
		public function initPlugins():void {
			//setStatus("Parsing plugins");
			var pluginDirs:Array = pluginHome.getDirectoryListing();				
			for each (var pluginDir:File in pluginDirs)	{
				var pluginData:PluginData = getPluginDataFromDir(pluginDir);
				if (pluginData == null)	{
					showError("Load Error", "One of your plugins is corrupt.");
					continue;
				}
				_plugins.addItem(pluginData);
				dispatchEvent(new Event(Event.CHANGE, false, false));
			}
		}
		
		public function get plugins():ArrayCollection {
			return _plugins;
		}
		
		public function get plugin():DisplayObject {
			return pluginLoader.content
		}
		
		/**
		 * Load a new plugin. Unload a previous one if there is one
		 */
		public function loadPlugin(pluginData:PluginData):void {
			//setStatus("Loading " + pluginData.name);
			if (pluginLoader.content != null) {
				var listener:Function = function(e:Event):void {
					pluginLoader.removeEventListener(Event.UNLOAD, listener);
					onPluginUnloaded(pluginData);
				};
				pluginLoader.addEventListener(Event.UNLOAD, listener);
				pluginLoader.unloadAndStop();
			} else {
				onPluginUnloaded(pluginData);
			}
		}
		
		public function deletePlugin(pluginData:PluginData):void {
			var pluginFile:File = pluginHome.resolvePath(pluginData.pluginPath);
			try {
				pluginFile.deleteDirectory(true);
			} catch(e:IOError) {
				showError("IO Error", "Unable to delete this plugin: " + e.message);
			}
			
			_plugins.removeItemAt(_plugins.getItemIndex(pluginData));
		}
		
		/**
		 * Look for Plugins locally
		 */
		public function browseForPlugin():void {
			if (browseFile == null) {
				browseFile = File.userDirectory;
				browseFile.addEventListener(Event.SELECT, onPluginSelected);
			}
			//browseFile.browseForOpen("Select the plugin you want to install.", [new FileFilter("Plugins", ".zip")]);
			browseFile.browseForOpen("Select the plugin you want to install.");
			//setStatus("Loading plugin");
		}
		
		public function cleanUpTmpDir():void {
			if (tmpDir != null && tmpDir.parent.exists) {
				tmpDir.parent.deleteDirectory(true);
			}
			tmpDir = null;
		}
		
		/*private function onPluginIOError(e:IOErrorEvent):void {
			showError("Load Error", "Error loading plugin: " + e.text + ". Try deleting this plugin, then reinstalling it.", "Couldn't load plugin");
		}*/
		
		/**
		 * Once a plugin is unloaded, load the next one
		 */
		private function onPluginUnloaded(pluginData:PluginData):void {
			var contentFile:File = new File(pluginData.contentPath);
			if (!contentFile.exists) {
				showError("Load Error", "Unable to load plugin. The content SWF is missing. Delete this plugin, and try reinstalling it.", "Load Error");
				return;
			}
			var contentBytes:ByteArray = getFileBytes(contentFile);
			pluginLoader.source = contentBytes;
		}
		
		private function getPluginDataFromDir(pluginDir:File):PluginData {
			var pluginXMLFile:File = pluginDir.resolvePath("META-INF/AIR/application.xml");
			if (!pluginXMLFile.exists) return null;
			
			try {
				var xmlBytes:ByteArray = getFileBytes(pluginXMLFile);
				var pluginXML:XML = new XML(xmlBytes);
				
				var pluginData:PluginData = new PluginData();
				
				var name:String = pluginXML.AIR_NS::name;
				var id:String = pluginXML.AIR_NS::id;
				var description:String = pluginXML.AIR_NS::description;
				var version:String = pluginXML.AIR_NS::version;
				
				if (name.length == 0 || id.length == 0 || description.length == 0 || version.length == 0) return null;
				
				pluginData.name = name;
				pluginData.id = id;
				pluginData.pluginPath = pluginDir.nativePath;
				pluginData.description = description;
				pluginData.version = Number(version);
				
				var pluginFile:File = pluginDir.resolvePath(pluginXML.AIR_NS::initialWindow.AIR_NS::content);
				if (!pluginFile.exists) return null;
				
				pluginData.contentPath = pluginFile.nativePath;
			} catch (e:Error) {
				return null; // Plugin is currupt.
			}
			
			return pluginData;
		}
		
		private function getFileBytes(f:File):ByteArray {
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes, 0, fs.bytesAvailable);
			fs.close();
			return bytes;
		}
		
		private function createTmpDir():void {
			var tmp:File = File.createTempDirectory();
			tmpDir = tmp.resolvePath(UIDUtil.createUID());
			tmpDir.createDirectory();
		}
		
		/*private function setStatus(msg:String):void {
			statusMessage.text = msg;
		}*/
		
		private function showError(title:String, errorMsg:String, statusMsg:String = null, cleanUpTmpDir:Boolean = false):void {
			Alert.show(errorMsg, title, Alert.OK);
			//if (statusMsg != null) setStatus(statusMsg);
			if (cleanUpTmpDir) this.cleanUpTmpDir();
		}
		
		private function validationHandler(e:Event):void {
			var validator:UCFSignatureValidator = e.target as UCFSignatureValidator;
			validator.removeEventListener(ErrorEvent.ERROR, validationHandler);
			validator.removeEventListener(Event.COMPLETE, validationHandler);
			
			if (e.type == ErrorEvent.ERROR) {
				showError("Signature Validation Failed", "This plugin's signature could not be validated: " + ErrorEvent(e).text, "Signature validation failed", true);
			} else if (e.type == Event.COMPLETE) {
				//setStatus("Signature validation complete");
				
				var pluginXMLFile:File = tmpDir.resolvePath("META-INF/AIR/application.xml");
				var pluginXMLBytes:ByteArray = getFileBytes(pluginXMLFile);
				var pluginXML:XML = new XML(pluginXMLBytes);
				
				var confirm:PluginInstallConfirmation = new PluginInstallConfirmation();
				confirm.addEventListener(CloseEvent.CLOSE, confirmHandler);
				confirm.setData(pluginXML.AIR_NS::name, pluginXML.AIR_NS::description, validator.xmlSignatureValidator.signerCN, (validator.xmlSignatureValidator.validityStatus == "valid"));
				confirm.open();
			}
		}
		
		/**
		 * Result if the user agrees to install plugin or not
		 */
		private function confirmHandler(e:CloseEvent):void {
			var confirm:PluginInstallConfirmation = e.target as PluginInstallConfirmation;
			confirm.removeEventListener(CloseEvent.CLOSE, confirmHandler);
			
			if (e.detail == Alert.YES) {
				try {
					//setStatus("Installing plugin");
					var destination:File = pluginHome.resolvePath(tmpDir.name);
					tmpDir.moveTo(destination, true);
					
					var newPluginDir:File = pluginHome.resolvePath(tmpDir.name);
					var pluginData:PluginData = getPluginDataFromDir(newPluginDir);
					
					_plugins.addItemAt(pluginData, 0);
					dispatchEvent(new Event(Event.CHANGE, false, false));
				} catch(e:Error) {
					showError("Installation Failed", "The installation of this plugin failed: " + e.message, "Installation failed", true);
					return;
				}
			} else {
				//setStatus("Plugin installation aborted");
			}
			
			cleanUpTmpDir();
		}
		
		/*private function onDownloadPlugin():void {
			//setStatus("Downloading plugin", true);
			loadPluginDrawer.close();
			var url:String = urlInput.text;
			if (url.search(/^(http(s?)):\/\/.+$/) == -1) // Valid URL?
			{
				showError("Invalid URL", "Please enter a valid URL", "Download aborted");
				return;
			}
			var req:URLRequest = new URLRequest(url);
			urlInput.text = "";
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onRemotePluginLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onRemotePluginIOError);
			loader.load(req);
		}
		
		private function onRemotePluginIOError(e:IOErrorEvent):void
		{
			setStatus("Download error");
			var loader:URLLoader = e.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onRemotePluginLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onRemotePluginIOError);
			showError("Load Error", "Unable to load plugin: " + e.target, "Unable to load plugin");
		}
		
		private function onRemotePluginLoaded(e:Event):void
		{
			setStatus("Plugin successfully downloaded");
			var loader:URLLoader = e.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onRemotePluginLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onRemotePluginIOError);
			parseZipFile(loader.data);
		}*/
		
		private function parseZipFile(data:ByteArray):void {
			zipFileParseError = false;
			createTmpDir();
			
			var zip:FZip = new FZip();
			zip.addEventListener(FZipEvent.FILE_LOADED, onFileFound);
			zip.addEventListener(Event.COMPLETE, zipFileHandler);
			zip.addEventListener(FZipErrorEvent.PARSE_ERROR, zipFileHandler);
			zip.addEventListener(IOErrorEvent.IO_ERROR, zipFileHandler);
			//setStatus("Unzipping plugin");
			zip.loadBytes(data);
		}
		
		private function zipFileHandler(e:Event):void {
			var zip:FZip = e.target as FZip;
			zip.removeEventListener(FZipEvent.FILE_LOADED, onFileFound);
			zip.removeEventListener(Event.COMPLETE, zipFileHandler);
			zip.removeEventListener(FZipErrorEvent.PARSE_ERROR, zipFileHandler);
			zip.removeEventListener(IOErrorEvent.IO_ERROR, zipFileHandler);
			
			if (e.type == Event.COMPLETE) {
				if (!zipFileParseError) {
					//setStatus("Plugin unzipped. Started signature validation.");
					
					// Start Validation
					//setStatus("Beginning signature validation");
					
					var validator:UCFSignatureValidator = new UCFSignatureValidator();
					validator.useSystemTrustStore = true;
					validator.packageRoot = tmpDir;
					validator.addEventListener(ErrorEvent.ERROR, validationHandler);
					validator.addEventListener(Event.COMPLETE, validationHandler);
					
					try {
						validator.verify();
					} catch (e:Error) {
						validator.removeEventListener(ErrorEvent.ERROR, validationHandler);
						validator.removeEventListener(Event.COMPLETE, validationHandler);
						showError("Validation Error", e.message, "Plugin invalid", true);
					}
				}
			} else if (e.type == FZipErrorEvent.PARSE_ERROR || e.type == IOErrorEvent.IO_ERROR) {
				if (!zipFileParseError) {
					if (e.type == FZipErrorEvent.PARSE_ERROR) {
						showError("Package Parse Error", "Unable to unpackage this plugin: " + ErrorEvent(e).text, "Parse error", true);
					} else if (e.type == IOErrorEvent.IO_ERROR) {
						showError("Package IO Error", "Unable to unpackage this plugin: " + ErrorEvent(e).text, "IO error", true);
					}
				}
				
				zipFileParseError = true;
			}
		}
		
		private function onFileFound(e:FZipEvent):void {
			try {
				// Check to see if this plugin is already installed
				if (e.file.filename.toLocaleLowerCase() == "meta-inf/air/application.xml") {
					var pluginXML:XML = new XML(e.file.content);
					var pluginId:String = pluginXML.AIR_NS::id;
					for each (var pluginData:PluginData in _plugins) {
						if (pluginData.id == pluginId) {
							showError("Duplicate Plugin", "This plugin is already installed. You can't install multiple instances of the same plugin.", "Installation aborted", true);
							
							var zip:FZip = e.target as FZip;
							zip.removeEventListener(FZipEvent.FILE_LOADED, onFileFound);
							zip.removeEventListener(Event.COMPLETE, zipFileHandler);
							zip.removeEventListener(FZipErrorEvent.PARSE_ERROR, zipFileHandler);
							zip.removeEventListener(IOErrorEvent.IO_ERROR, zipFileHandler);
							return;
						}
					}
				}
				
				var zFile:FZipFile = e.file;
				//setStatus("Saving " + zFile.filename);
				
				var f:File = tmpDir.resolvePath(zFile.filename);
				trace('file', f.url);
				if (zFile.content.length == 0) {
					f.createDirectory();
				} else {
					var fs:FileStream = new FileStream();
					fs.open(f, FileMode.WRITE);
					fs.writeBytes(zFile.content, 0, zFile.content.length);
					fs.close();
				}
			} catch(e:Error) {
				if (!zipFileParseError) {
					showError("Corrupt Plugin", "Unable to unzip this plugin: " + e.message, "Unzip error", true);
				}
				
				zipFileParseError = true;
			}
		}
		
		private function onPluginSelected(e:Event):void {
			
			var chosenFile:File = e.target as File;
			trace("plugin selected", chosenFile.url);
			var fileBytes:ByteArray = getFileBytes(chosenFile);
			parseZipFile(fileBytes);
		}
	}
}