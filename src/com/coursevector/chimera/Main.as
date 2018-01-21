import air.update.ApplicationUpdaterUI;
import air.update.events.UpdateEvent;

import com.coursevector.chimera.AboutWindow;
import com.coursevector.chimera.HighlightBlock;
import com.coursevector.chimera.Highlighter;
import com.coursevector.chimera.plugins.*;
import com.coursevector.flex.HTMLToolTip;

import flash.desktop.NativeApplication;
import flash.display.NativeWindow;
import flash.display.Screen;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.utils.Endian;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.Text;
import mx.events.FlexEvent;
import mx.managers.ToolTipManager;

[Bindable]
public var acPlugins:ArrayCollection;

[Bindable]
private var processingFile:Boolean = false;

private var ba:ByteArray = new ByteArray();
private var arrPlugins:Array = [];
private var file:File = File.desktopDirectory;
private var numColumns:int = 16;
private var aboutWin:AboutWindow;
private var appUpdater:ApplicationUpdaterUI = new ApplicationUpdaterUI();
private var hlBytes:Highlighter;
private var hlDump:Highlighter;

private function init(event:FlexEvent):void {
	
	this.nativeWindow.addEventListener(Event.CLOSING, onClosing);
	
	// Center the window
	var initialBounds:Rectangle = new Rectangle((Screen.mainScreen.bounds.width / 2 - (this.width/2)), (Screen.mainScreen.bounds.height / 2 - (this.height/2)), this.width, this.height);
	this.nativeWindow.bounds = initialBounds;				
	this.nativeWindow.visible = true;
	
	// Init tooltips
	ToolTipManager.toolTipClass = HTMLToolTip;
	
	// Init mouse wheel accelerator
	systemManager.addEventListener(MouseEvent.MOUSE_WHEEL, bumpDelta, true);
	
	// Init Updater			
	appUpdater.updateURL = "http://www.coursevector.com/projects/chimera/update.xml";
	appUpdater.isCheckForUpdateVisible = false; // We won't ask permission to check for an update
	appUpdater.addEventListener(UpdateEvent.INITIALIZED, updateHandler);
	appUpdater.addEventListener(ErrorEvent.ERROR, errorHandler);
	appUpdater.initialize();
	
	arrPlugins.push({label:'None', data:null});
	arrPlugins.push({label:'Shared Object', data:SharedObjectPlugin});
	arrPlugins.push({label:'AMF Object', data:AMFPlugin});
	arrPlugins.push({label:'AMF0 Object', data:AMF0ObjectPlugin});
	arrPlugins.push({label:'AMF3 Object', data:AMF3ObjectPlugin});
	arrPlugins.push({label:'Chrome Extension', data:CRXPlugin});
	arrPlugins.push({label:'JPEG', data:JPEGPlugin});
	//arrPlugins.push({label:'AMF3', data:AMF3Plugin});
	//arrPlugins.push({label:'AMF0', data:AMF0Plugin});
	acPlugins = new ArrayCollection(arrPlugins as Array);
	
	// Init display
	cvBytes.addEventListener(Event.COMPLETE, completeHandler);
	cvBytes.addEventListener(ProgressEvent.PROGRESS, progressHandler);
	cvBytes.columns = numColumns;
	file.addEventListener(Event.SELECT, openHandler, false, 0, true);
}

private function onClosing(e:Event = null):void {
	if (e) e.preventDefault();
	
	for (var i:int = NativeApplication.nativeApplication.openedWindows.length - 1; i >= 0; --i)	{
		NativeWindow(NativeApplication.nativeApplication.openedWindows[i]).close();
	}
}

// Fixes super slow scrolling, 1px -> 30px per move
private function bumpDelta(event:MouseEvent):void {
	event.delta *= 30;
}

private function onClickOpen():void {
	file.browse();
}

private function onClickClose():void {
	this.currentState = 'FileClosed';
	this.title = "Course Vector .chimera";
	lblAddress.text = '';
	lblDump.text = '';
	
	// Draw title
	/*lblTitle.text = '';
	for(var i:int = 0; i < _numColumns; i++) {
	lblTitle.text += getByte(i);
	}*/
	
	cvBytes.clear();
}

private function onClickAbout():void {
	aboutWin = new AboutWindow();
	aboutWin.open();
}

private function progressHandler(e:ProgressEvent):void {
	pbProgress.setProgress(e.bytesLoaded, e.bytesTotal);
}

private function errorHandler(event:ErrorEvent):void {
	Alert.show(event.toString());
}

private function updateHandler(event:UpdateEvent):void {
	appUpdater.checkNow();
}

/*private function invokeHandler(e:InvokeEvent):void {
	if(e.arguments.length > 0) {
		if(file.hasEventListener(Event.SELECT)) file.removeEventListener(Event.SELECT, openHandler);
		file = new File(e.arguments[0]);
		openHandler();
	}
}*/

private function openHandler(e:Event = null):void {
	this.title = "Course Vector .chimera - " + file.name;
	this.currentState = 'FileOpen';
	
	// Read file into ByteArray
	ba = new ByteArray();
	var bytes:FileStream = new FileStream();
	bytes.open(file, FileMode.READ);
	bytes.readBytes(ba);
	bytes.close();
	ba.position = 0;
	
	// Update Code
	processingFile = true;
	pbProgress.maximum = ba.length - 1;
	cvBytes.data = ba;
}

private function completeHandler(e:Event):void {
	// Update offsets
	var str:String = '';
	for(var i:int = 0; i <= cvBytes.rows; i++) {
		var byte:String = Number(i * numColumns).toString(16).toUpperCase();
		while (byte.length < 8) byte = '0' + byte;
		str += byte + '\n';
	}
	str = str.substring(0, (str.length - 1));
	lblAddress.text = str;
	
	// Update Dump
	str = '';
	ba.position = 0;
	
	//var fontArray:Array = Font.enumerateFonts(false);
	//var myFont:Font = fontArray[0];
	while (ba.bytesAvailable) {
		var char2:int = ba.readByte();
		/*
		In Flex, fonts specified in CSS @font-face rules will be embedded into the application. Once configured,
		character ranges can be used by name in the @font-face rule's unicode-range descriptor as a short hand
		notation for lengthy ranges.
		
		@font-face {
			font-family : MyCourier;
			src : local("Courier New");
			unicode-range : "Latin I";
		}
		
		.myembedded { font-family: MyCourier; font-size:22pt; }
		
		Uppercase U+0020,U+0041-005A
		Lowercase U+0020,U+0061-007A
		Numerals U+0030-0039,U+002E
		Punctuation U+0020-002F,U+003A-0040,U+005B-0060,U+007B-007E
		Basic Latin U+0020-002F,U+0030-0039,U+003A-0040,U+0041-005A,U+005B-0060,U+0061-007A,U+007B-007E
		Latin I U+0020,U+00A1-00FF,U+2000-206F,U+20A0-20CF,U+2100-2183
		Latin Extended A U+0100-01FF,U+2000-206F,U+20A0-20CF,U+2100-2183
		Latin Extended B U+0180-024F,U+2000-206F,U+20A0-20CF,U+2100-2183
		Latin Extended Add'l U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-2183
		*/
		if (
			(char2 >= 0x0041 && char2 <= 0x005A) || /* Uppercase */
			(char2 >= 0x0061 && char2 <= 0x007A) || /* Lowercase */
			(char2 >= 0x0030 && char2 <= 0x0039) || char2 == 0x002E || /* Numerals */
			(char2 >= 0x0020 && char2 <= 0x002F) || (char2 >= 0x003A && char2 <= 0x0040) || /* Punctuation 1 */
			(char2 >= 0x005B && char2 <= 0x0060) || (char2 >= 0x007B && char2 <= 0x007E) || /* Punctuation 2 */
			(char2 >= 0x00A1 && char2 <= 0x00FF) || (char2 >= 0x2000 && char2 <= 0x206F) || /* Latin I */
			(char2 >= 0x20A0 && char2 <= 0x20CF) || (char2 >= 0x2100 && char2 <= 0x2183) || /* Latin I */
			(char2 >= 0x0100 && char2 <= 0x01FF) || /* Latin Extended A */
			(char2 >= 0x0180 && char2 <= 0x024F) || /* Latin Extended B */
			(char2 >= 0x1E00 && char2 <= 0x1EFF) /* Latin Extended Add'l */
		) {
			str += String.fromCharCode(char2);
		} else {
			str += '.';
		}
		
		// Lets blanks spaces in
		/*var char:String = ba.readUTFBytes(1);
		if (char.length > 0 && myFont.hasGlyphs(char) && char != " ") {
			str += char;
		} else {
			str += '.';
		}*/
		
		if (ba.position % numColumns == 0) str += '\n';
	}
	lblDump.text = str;
	
	// Init highlighters
	var charWidth:Number = 8.8;
	var charHeight:Number = 12.2;
	if (hlBytes) {
		hlBytes.removeEventListener(MouseEvent.MOUSE_OVER, highlightHandler);
		hlBytes.removeEventListener(MouseEvent.MOUSE_OUT, highlightHandler);
	}
	if (hlDump) {
		hlDump.removeEventListener(MouseEvent.MOUSE_OVER, highlightHandler);
		hlDump.removeEventListener(MouseEvent.MOUSE_OUT, highlightHandler);
	}
	
	hlBytes = new Highlighter(cvBytes, ba, numColumns, cvBytes.rows, charHeight + 7, charWidth * 3);
	hlBytes.addEventListener(MouseEvent.MOUSE_OVER, highlightHandler);
	hlBytes.addEventListener(MouseEvent.MOUSE_OUT, highlightHandler);
	hlDump = new Highlighter(grpDump, ba, numColumns, cvBytes.rows, charHeight + 7, charWidth);
	hlDump.addEventListener(MouseEvent.MOUSE_OVER, highlightHandler);
	hlDump.addEventListener(MouseEvent.MOUSE_OUT, highlightHandler);
	hlDump.offsetPoint = new Point(0, -3);
	
	// If user is opening another file after inital program start
	if (ddlPlugins.selectedItem) highlight(ddlPlugins.selectedItem.data);
	
	processingFile = false;
}

private function highlight(pluginClass:Class):void {
	hlBytes.clear();
	hlDump.clear();
	
	ba.position = 0;
	ba.endian = Endian.BIG_ENDIAN;
	if (ba.bytesAvailable <= 0) return;
	if (!pluginClass) return;
	
	var plugin:Plugin = new pluginClass();
	try {
		plugin.addEventListener(PluginEvent.START_GROUP, pluginHandler);
		plugin.addEventListener(PluginEvent.END_GROUP, pluginHandler);
		plugin.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
		plugin.parse(ba);
	} catch (e:Error) {
		var strError:String = e.toString();
		strError = strError.substr(7); // Remove redundant 'Error: '
		
		Alert.show(strError, 'Plugin Error');
		
		var o:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Plugin Error', strError, 0xFF0000);
		o.endIndex = ba.position + 1;
		hlBytes.showBlock(o);
		hlDump.showBlock(o);
	} finally {
		plugin.removeEventListener(PluginEvent.START_GROUP, pluginHandler);
		plugin.removeEventListener(PluginEvent.END_GROUP, pluginHandler);
		plugin.removeEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
		plugin = null;
		ba.endian = Endian.BIG_ENDIAN;
		ba.position = 0;
	}
}

private function highlightHandler(event:MouseEvent):void {
	var hl:Highlighter = event.currentTarget as Highlighter;
	var hlBlock:HighlightBlock = hl.currentBlock;
	var dumpBlock:HighlightBlock = hlDump.blocks[hlBlock.index];
	var bytesBlock:HighlightBlock = hlBytes.blocks[hlBlock.index];
	if (event.type == MouseEvent.MOUSE_OVER) {
		if (hlBlock.group) {
			fadeIn.play([dumpBlock, dumpBlock.group, bytesBlock, bytesBlock.group]);
		} else {
			fadeIn.play([dumpBlock, bytesBlock]);
		}
	} else {
		if (hlBlock.group) {
			fadeOut.play([dumpBlock, dumpBlock.group, bytesBlock, bytesBlock.group]);
		} else {
			fadeOut.play([dumpBlock, bytesBlock]);
		}
	}
}

private function pluginHandler(e:PluginEvent):void {
	switch(e.type) {
		case PluginEvent.START_GROUP :
			hlBytes.startGroup(e.startIndex, e.name);
			hlDump.startGroup(e.startIndex, e.name);
			break;
		case PluginEvent.END_GROUP :
			hlBytes.endGroup(e.startIndex);
			hlDump.endGroup(e.startIndex);
			break;
		case PluginEvent.HIGHLIGHT :
			hlBytes.showBlock(e);
			hlDump.showBlock(e);
			break;
	}
}