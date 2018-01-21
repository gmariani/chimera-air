/* 
AMF0 parser, reads and writes AMF0 encoded data
Copyright (C) 2009  Gabriel Mariani

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
uint8 - BYTE - readUnsignedByte
int8 - CHAR - readByte
uint16 - USHORT - readUnsignedShort
int16 - SHORT - readShort
uint32 - ULONG - readUnsignedInt
int32 - LONG - readInt

readBoolean : moves position by 1
readByte : moves position by 1
readDouble : moves position by 8
readFloat : moves position by 4
readInt : moves position by 4
readMultiByte : Reads a multibyte string of specified length from the file stream, byte stream
readShort : moves position by 2
readUnsignedByte : moves position by 1
readUnsignedInt : moves position by 4
readUnsignedShort : moves position by 2
readUTF : reads based on assumed prefix of string length
readUTFBytes : moves specified amount

http://opensource.adobe.com/svn/opensource/blazeds/trunk/modules/core/src/flex/messaging/io/amf/Amf0Output.java
*/

package com.coursevector.chimera.plugins {
	
	import flash.utils.ByteArray;
	import flash.xml.XMLDocument;
	
	public class AMF0Plugin extends Plugin {
		
		// AMF marker constants
		protected const NUMBER_TYPE:int = 0;
		protected const BOOLEAN_TYPE:int = 1;
		protected const STRING_TYPE:int = 2;
		protected const OBJECT_TYPE:int = 3;
		protected const MOVIECLIP_TYPE:int = 4; // reserved, not supported
		protected const NULL_TYPE:int = 5;
		protected const UNDEFINED_TYPE:int = 6;
		protected const REFERENCE_TYPE:int = 7;
		protected const ECMA_ARRAY_TYPE:int = 8; // associative
		protected const OBJECT_END_TYPE:int = 9;
		protected const STRICT_ARRAY_TYPE:int = 10;
		protected const DATE_TYPE:int = 11;
		protected const LONG_STRING_TYPE:int = 12; // string.length > 2^16
		protected const UNSUPPORTED_TYPE:int = 13;
		protected const RECORD_SET_TYPE:int = 14; // reserved, not supported
		protected const XML_OBJECT_TYPE:int = 15;
		protected const TYPED_OBJECT_TYPE:int = 16;
		protected const AVMPLUS_OBJECT_TYPE:int = 17;
		
		/**
		 * The actual object cache used to store references
		 */
		protected var readObjectCache:Array = new Array(); // Length 64
		
		/**
		 * The raw binary data
		 */
		protected var _rawData:ByteArray;
		
		/**
		 * The decoded data
		 */
		protected var _data:*;
		
		/**
		 * Unfortunately the Flash Player starts AMF 3 messages off with the legacy
		 * AMF 0 format and uses a type, AmfTypes.kAvmPlusObjectType, to indicate
		 * that the next object in the stream is to be deserialized differently. The
		 * original hope was for two independent encoding versions... but for now
		 * we just keep a reference to objectInput here.
		 * @exclude
		 */
		protected var amf3:AMF3Plugin;
		
		public function AMF0Plugin():void { }
		
		public function get data():* { return _data; }
		
		public function get rawData():ByteArray { return _rawData; }
		
		public function reset():void {
			readObjectCache = new Array();
			if (amf3) amf3.reset();
		}
		
		override public function parse(ba:ByteArray):void {
			reset();
			
			_rawData = ba;
			_data = readData(_rawData);
		}
		
		public function readData(ba:ByteArray, type:int = -1):* {
			var e:PluginEvent;
			if(type == -1) {
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Type', null, 0x0000FF, 100);
				type = ba.readByte();
			} else {
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position - 1, 'Type', type, 0x0000FF, 100);
			}
			e.value = type;
			switch(type) {
				case NUMBER_TYPE : 
					e.value += ' - Number';
					dispatchPluginEvent(e, ba.position);
					return readNumber(ba);
				case BOOLEAN_TYPE : 
					e.color = 0x3ED0D5;
					e.brightness = 0;
					e.value += ' - Boolean';
					dispatchPluginEvent(e, ba.position);
					return readBoolean(ba);
				case STRING_TYPE :
					e.value += ' - String';
					dispatchPluginEvent(e, ba.position);
					return readString(ba);
				case OBJECT_TYPE : 
					e.value += ' - Object';
					dispatchPluginEvent(e, ba.position);
					return readObject(ba);
					//case MOVIECLIP_TYPE : return null;
				case NULL_TYPE : 
					e.color = 0xF000FF;
					e.brightness = 0;
					e.value += ' - Null';
					dispatchPluginEvent(e, ba.position);
					return null;
				case UNDEFINED_TYPE : 
					e.color = 0xF000FF;
					e.brightness = 0;
					e.value += ' - Undefined';
					dispatchPluginEvent(e, ba.position);
					return undefined;
				case REFERENCE_TYPE : 
					e.value += ' - Reference';
					dispatchPluginEvent(e, ba.position);
					return getObjectReference(ba);
				case ECMA_ARRAY_TYPE : 
					e.value += ' - ECMA Array';
					dispatchPluginEvent(e, ba.position);
					return readECMAArray(ba);
				case OBJECT_END_TYPE :
					e.value += ' - Object End';
					dispatchPluginEvent(e, ba.position);
					// Unexpected object end tag in AMF stream
					trace("AMF0::readData - Warning : Unexpected object end tag in AMF stream");
					return null;
				case STRICT_ARRAY_TYPE : 
					e.value += ' - Strict Array';
					dispatchPluginEvent(e, ba.position);
					return readArray(ba);
				case DATE_TYPE : 
					e.value += ' - Date';
					dispatchPluginEvent(e, ba.position);
					return readDate(ba);
				case LONG_STRING_TYPE : 
					e.value += ' - Long String';
					dispatchPluginEvent(e, ba.position);
					return readLongString(ba);
				case UNSUPPORTED_TYPE :
					// Unsupported type found in AMF stream
					trace("AMF0::readData - Warning : Unsupported type found in AMF stream");
					dispatchPluginEvent(e, ba.position);
					return "__unsupported";
				case RECORD_SET_TYPE :
					// AMF Recordsets are not supported
					trace("AMF0::readData - Warning : Unexpected recordset in AMF stream");
					dispatchPluginEvent(e, ba.position);
					return null;
				case XML_OBJECT_TYPE : 
					e.value += ' - XML';
					dispatchPluginEvent(e, ba.position);
					return readXML(ba);
				case TYPED_OBJECT_TYPE : 
					e.value += ' - Typed Object';
					dispatchPluginEvent(e, ba.position);
					return readCustomClass(ba);
				case AVMPLUS_OBJECT_TYPE :
					e.value += ' - AVM+';
					dispatchPluginEvent(e, ba.position);
					if(amf3 == null) {
						amf3 = new AMF3Plugin();
						amf3.addEventListener(PluginEvent.START_GROUP, pluginHandler);
						amf3.addEventListener(PluginEvent.END_GROUP, pluginHandler);
						amf3.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
					}
					return amf3.readData(ba);
					/*
					With the introduction of AMF 3 in Flash Player 9 to support ActionScript 3.0 and the 
					new AVM+, the AMF 0 format was extended to allow an AMF 0 encoding context to be 
					switched to AMF 3. To achieve this, a new type marker was added to AMF 0, the 
					avmplus-object-marker. The presence of this marker signifies that the following Object is 
					formatted in AMF 3.
					*/
				default:
					dispatchPluginEvent(e, ba.position);
					throw Error("AMF0::readData - Error : Undefined AMF0 type encountered '" + type + "'");
			}
		}
		
		protected function pluginHandler(e:PluginEvent):void {
			dispatchEvent(e.clone());
		}
		
		protected function readNumber(ba:ByteArray):Number {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Number', ba.readDouble(), 0x49D908);
			dispatchPluginEvent(e, ba.position);
			return e.value;
		}
		
		protected function readBoolean(ba:ByteArray):Boolean {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Boolean', ba.readBoolean(), 0x3ED0D5);
			dispatchPluginEvent(e, ba.position);
			return e.value;
		}
		
		public function readString(ba:ByteArray):String {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'String', ba.readUTF(), 0x49D908);
			dispatchPluginEvent(e, ba.position);
			return e.value;
		}
		
		/**
		 * readObject reads the name/value properties of the amf message
		 */
		protected function readObject(ba:ByteArray):Object {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Object');
			dispatchPluginEvent(e, ba.position);
			
			var obj:Object = new Object();
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Variable Name', null, 0x49D908);
			var varName:String = ba.readUTF();
			e.value = varName;
			dispatchPluginEvent(e, ba.position);
			var type:int = ba.readByte();
			
			// 0x00 0x00 (varname) 0x09 (end object type)
			while(varName.length > 0 && type != OBJECT_END_TYPE) {
				obj[varName] = readData(ba, type);
				e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Variable Name', null, 0x49D908);
				varName = ba.readUTF();
				e.value = varName;
				dispatchPluginEvent(e, ba.position);
				type = ba.readByte();
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			readObjectCache.push(obj);
			return obj;
		}
		
		/**
		 * An ECMA Array or 'associative' Array is used when an ActionScript Array contains 
		 * non-ordinal indices. This type is considered a complex type and thus reoccurring 
		 * instances can be sent by reference. All indices, ordinal or otherwise, are treated 
		 * as string 'keys' instead of integers. For the purposes of serialization this type 
		 * is very similar to an anonymous Object.
		 */
		protected function readECMAArray(ba:ByteArray):Array {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'ECMA Array');
			dispatchPluginEvent(e, ba.position);
			
			var arr:Array = new Array();
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'ECMA Array Length', null, 0x30DFC4);
			var l:uint = ba.readUnsignedInt();
			e.value = l;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Variable Name', null, 0x49D908);
			var varName:String = ba.readUTF();
			e.value = varName;
			dispatchPluginEvent(e, ba.position);
			var type:int = ba.readByte();
			
			// 0x00 0x00 (varname) 0x09 (end object type)
			while(varName.length > 0 && type != OBJECT_END_TYPE) {
				arr[varName] = readData(ba, type);
				e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Variable Name', null, 0x49D908);
				varName = ba.readUTF();
				e.value = varName;
				dispatchPluginEvent(e, ba.position);
				type = ba.readByte();
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			readObjectCache.push(arr);
			return arr;
		}
		
		/**
		 * readArray turns an all numeric keyed actionscript array
		 */
		protected function readArray(ba:ByteArray):Array {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Strict Array');
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Strict Array Length', null, 0x30DFC4);
			var l:uint = ba.readUnsignedInt();
			e.value = l;
			dispatchPluginEvent(e, ba.position);
			
			var arr:Array = new Array(l);
			for (var i:int = 0; i < l; ++i) {
				arr.push(readData(ba));
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			readObjectCache.push(arr);
			return arr;
		}
		
		/**
		 * readDate reads a date from the amf message
		 */
		protected function readDate(ba:ByteArray):Date {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Date', null, 0xBE9E80);
			var ms:Number = ba.readDouble();
			
			/*
			We read in the timezone but do nothing with the value as
			we expect dates to be written in the UTC timezone. Client
			and servers are responsible for applying their own
			timezones.
			*/
			var timezone:int = ba.readShort(); // reserved, not supported. should be set to 0x0000
			//if (timezone > 720) timezone = -(65536 - timezone);
			//timezone *= -60;
			
			var d:Date = new Date(ms);
			e.value = d.toString();
			
			dispatchPluginEvent(e, ba.position);
			return d;
		}
		
		protected function readLongString(ba:ByteArray):String {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Long String Length', null, 0x49D908);
			var len:uint = ba.readUnsignedShort();
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Long String', ba.readUTFBytes(len), 0x49D908);
			dispatchPluginEvent(e, ba.position);
			return e.value;
		}
		
		protected function readXML(ba:ByteArray):XMLDocument {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML Length', null, 0xEC65C8);
			var len:uint = ba.readUnsignedShort();
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML', ba.readUTFBytes(len), 0xEC65C8);
			dispatchPluginEvent(e, ba.position);
			
			return new XMLDocument(e.value);
		}
		
		/**
		 * If a strongly typed object has an alias registered for its class then the type name 
		 * will also be serialized. Typed objects are considered complex types and reoccurring 
		 * instances can be sent by reference.
		 */
		protected function readCustomClass(ba:ByteArray):* {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Typed Object');
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Class Name', null, 0x5760D6);
			var className:String = ba.readUTF();
			e.value = className;
			dispatchPluginEvent(e, ba.position);
			
			try {
				var obj:Object = readObject(ba);
			} catch (e:Error) {
				throw new Error("AMF0::readCustomClass - Error : Cannot parse custom class");
			}
			
			obj.__traits = { type:className };
			
			// Try to type it to the class def
			/*try {
			var classDef:Class = getClassByAlias(className);
			obj = new classDef();
			obj.readExternal(ba);
			} catch (e:Error) {
			obj = readData(ba);
			}*/
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return obj;
		}
		
		protected function getObjectReference(ba:ByteArray):Object {
			var ref:int = ba.readUnsignedShort();
			if (ref >= readObjectCache.length) {
				throw Error("AMF0::getObjectReference - Error : Undefined object reference '" + ref + "' :: " + ba.position);
				return null;
			}
			
			return readObjectCache[ref];
		}
	}
}