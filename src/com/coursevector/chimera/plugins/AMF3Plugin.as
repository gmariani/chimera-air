/* 
AMF3 parsers, reads AMF3 encoded data
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
uint8 - BYTE - readUnsignedByte - U8
int8 - CHAR - readByte
uint16 - USHORT - readUnsignedShort - U16
int16 - SHORT - readShort
uint32 - ULONG - readUnsignedInt - U32
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
*/

package com.coursevector.chimera.plugins {
	
	import com.coursevector.chimera.plugins.Plugin;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.xml.XMLDocument;
	
	public class AMF3Plugin extends Plugin {
		
		// AMF marker constants
		protected const UNDEFINED_TYPE:int = 0;
		protected const NULL_TYPE:int = 1;
		protected const FALSE_TYPE:int = 2;
		protected const TRUE_TYPE:int = 3;
		protected const INTEGER_TYPE:int = 4;
		protected const DOUBLE_TYPE:int = 5;
		protected const STRING_TYPE:int = 6;
		protected const XML_DOC_TYPE:int = 7;
		protected const DATE_TYPE:int = 8;
		protected const ARRAY_TYPE:int = 9;
		protected const OBJECT_TYPE:int = 10;
		// Flash Player 9
		protected const XML_TYPE:int = 11;
		protected const BYTE_ARRAY_TYPE:int = 12;
		// Flash Player 10
		protected const VECTOR_INT_TYPE:int = 13;
		protected const VECTOR_UINT_TYPE:int = 14;
		protected const VECTOR_NUMBER_TYPE:int = 15;
		protected const VECTOR_OBJECT_TYPE:int = 16;
		protected const DICTIONARY_TYPE:int = 17;
		
		// Simplified implementation of the class alias registry 
		protected const CLASS_ALIAS_REGISTRY:Object = {	
			"DSK": "flex.messaging.messages.AcknowledgeMessageExt",
			"DSA": "flex.messaging.messages.AsyncMessageExt",
			"DSC": "flex.messaging.messages.CommandMessageExt"	
		};
		
		/**
		 * The raw binary data
		 */
		protected var _rawData:ByteArray;
		
		/**
		 * The decoded data
		 */
		protected var _data:*;
		
		protected var readStringCache:Array = new Array(); // Length 64
		protected var readObjectCache:Array = new Array(); // Length 64
		protected var readTraitsCache:Array = new Array(); // Length 10
		
		protected var flex:Object = {
			"AbstractMessage" : AbstractMessage,
			"AsyncMessage" : AsyncMessage,
			"AsyncMessageExt" : AsyncMessageExt,
			"AcknowledgeMessage" : AcknowledgeMessage,
			"AcknowledgeMessageExt" : AcknowledgeMessageExt,
			"CommandMessage" : CommandMessage,
			"CommandMessageExt" : CommandMessageExt,
			"ErrorMessage" : ErrorMessage,
			"ArrayCollection" : ArrayCollection,
			"ArrayList" : ArrayList,
			"ObjectProxy" : ObjectProxy,
			"ManagedObjectProxy" : ManagedObjectProxy,
			"SerializationProxy" : SerializationProxy
		};
		
		public function AMF3Plugin():void { }
		
		public function get data():* { return _data; }
		
		public function get rawData():ByteArray { return _rawData; }
		
		public function reset():void {
			readStringCache = new Array();
			readObjectCache = new Array();
			readTraitsCache = new Array();
		}
		
		override public function parse(ba:ByteArray):void {
			reset();
			
			_rawData = ba;
			_data = readData(_rawData);
		}
		
		public function readData(ba:ByteArray):* {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Type', null, 0x0000FF, 100);
			var type:int = ba.readByte();
			e.value = type;
			switch(type) {
				case UNDEFINED_TYPE : 
					e.color = 0xF000FF;
					e.brightness = 0;
					e.value += ' - Undefined';
					dispatchPluginEvent(e, ba.position);
					return undefined;
				case NULL_TYPE :
					e.color = 0xF000FF;
					e.brightness = 0;
					e.value += ' - Null';
					dispatchPluginEvent(e, ba.position);
					return null;
				case FALSE_TYPE :
					e.color = 0x3ED0D5;
					e.brightness = 0;
					e.value += ' - False';
					dispatchPluginEvent(e, ba.position);
					return false;
				case TRUE_TYPE : 
					e.color = 0x3ED0D5;
					e.brightness = 0;
					e.value += ' - True';
					dispatchPluginEvent(e, ba.position);
					return true;
				case INTEGER_TYPE : 
					e.value += ' - Integer';
					dispatchPluginEvent(e, ba.position);
					return readInt(ba);
				case DOUBLE_TYPE : 
					e.value += ' - Double';
					dispatchPluginEvent(e, ba.position);
					return readDouble(ba);
				case STRING_TYPE : 
					e.value += ' - String';
					dispatchPluginEvent(e, ba.position);
					return readString(ba);
				case XML_DOC_TYPE : 
					e.value += ' - XML Document';
					dispatchPluginEvent(e, ba.position);
					return readXMLDoc(ba);
				case DATE_TYPE : 
					e.value += ' - Date';
					dispatchPluginEvent(e, ba.position);
					return readDate(ba);
				case ARRAY_TYPE : 
					e.value += ' - Array';
					dispatchPluginEvent(e, ba.position);
					return readArray(ba);
				case OBJECT_TYPE : 
					e.value += ' - Object';
					dispatchPluginEvent(e, ba.position);
					return readObject(ba);
				case XML_TYPE : 
					e.value += ' - XML';
					dispatchPluginEvent(e, ba.position);
					return readXML(ba);
				case BYTE_ARRAY_TYPE : 
					e.value += ' - ByteArray';
					dispatchPluginEvent(e, ba.position);
					return readByteArray(ba);
				case VECTOR_INT_TYPE : return readVectorInt(ba); // Vector.<int>
				case VECTOR_UINT_TYPE : return readVectorUInt(ba); // Vector.<uint>
				case VECTOR_NUMBER_TYPE : return readVectorNumber(ba); // Vector.<Number>
				case VECTOR_OBJECT_TYPE : return readVectorObject(ba); // Vector.<Object>
				case DICTIONARY_TYPE : return readDictionary(ba);
				default: throw Error("AMF3::readData - Error : Undefined AMF3 type encountered '" + type + "', at position '" + ba.position + "'");
			}
		}
		
		/**
		 * Read and deserialize an integer
		 * 
		 * 0x04 -> integer type code, followed by up to 4 bytes of data.
		 *
		 * @return A int capable of holding an unsigned 29 bit integer.
		 */
		protected function readInt(ba:ByteArray):int {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Integer', null, 0xFC5630);
			var result:int = readUInt29(ba);
			// Symmetric with writing an integer to fix sign bits for negative values...
			result = (result << 3) >> 3;
			e.value = result;
			dispatchPluginEvent(e, ba.position);
			return result;
		}
		
		/**
		 * AMF 3 represents smaller integers with fewer bytes using the most
		 * significant bit of each byte. The worst case uses 32-bits
		 * to represent a 29-bit number, which is what we would have
		 * done with no compression.
		 * <pre>
		 * 0x00000000 - 0x0000007F : 0xxxxxxx
		 * 0x00000080 - 0x00003FFF : 1xxxxxxx 0xxxxxxx
		 * 0x00004000 - 0x001FFFFF : 1xxxxxxx 1xxxxxxx 0xxxxxxx
		 * 0x00200000 - 0x3FFFFFFF : 1xxxxxxx 1xxxxxxx 1xxxxxxx xxxxxxxx
		 * 0x40000000 - 0xFFFFFFFF : throw range exception
		 * </pre>
		 *
		 * @return A int capable of holding an unsigned 29 bit integer.
		 */
		protected function readUInt29(ba:ByteArray):int {
			var result:int = 0;
			
			// Each byte must be treated as unsigned
			var b:int = ba.readUnsignedByte();
			
			if (b < 128) return b;
			
			result = (b & 0x7F) << 7;
			b = ba.readUnsignedByte();
			
			if (b < 128) return (result | b);
			
			result = (result | (b & 0x7F)) << 7;
			b = ba.readUnsignedByte();
			
			if (b < 128) return (result | b);
			
			result = (result | (b & 0x7F)) << 8;
			b = ba.readUnsignedByte();
			
			return (result | b);
		}
		
		/*protected function readUInt29(ba:ByteArray):int {
			var count:int = 1;
			var intReference:int = ba.readByte();
			var result:int = 0;
			while (((intReference & 0x80) != 0) && count < 4) {
				result <<= 7;
				result |= (intReference & 0x7f);
				intReference = ba.readByte();
				count++;
			}
			
			if (count < 4) {
				result <<= 7;
				result |= intReference;
			} else {
				// Use all 8 bits from the 4th byte
				result <<= 8;
				result |= intReference;
				
				// Check if the integer should be negative
				if ((result & 0x10000000) != 0) {
					//and extend the sign bit
					result |= ~0xFFFFFFF;
				}
			}
			return result;
		}*/
		
		protected function readDouble(ba:ByteArray):Number {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Double', ba.readDouble(), 0x49D908);
			dispatchPluginEvent(e, ba.position);
			return e.value;
		}
		
		public function readString(ba:ByteArray):String {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'String Length', null, 0x49D908);
			var ref:int = readUInt29(ba);
			if ((ref & 0x01) == 0) {
				e.name = 'String Reference';
				e.value = ref >> 1; //  index of the array is saved. The table includes keys as well as values.
				dispatchPluginEvent(e, ba.position);
			
				if (ref >= readStringCache.length) {
					//throw Error("AMF3::readString - Error : Undefined string reference '" + ref + "'");
				}
				return readStringCache[ref >> 1];
			}
			
			var len:int = ref >> 1;
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'String', null, 0x49D908);
			var str:String = "";
			if (len > 0) {
				str = ba.readUTFBytes(len);

				readStringCache.push(str);
			}
			e.value = str;
			dispatchPluginEvent(e, ba.position);
			return str;
		}
		
		protected function readXMLDoc(ba:ByteArray):XMLDocument {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML Document Length', null, 0x49D908);
			var ref:int = readUInt29(ba);
			if((ref & 1) == 0) {
				e.name = 'XML Document Reference';
				e.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e.value) as XMLDocument;
			}
			
			var len:int = ref >> 1;
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML Document', null, 0x49D908);
			var xmldoc:XMLDocument = new XMLDocument(ba.readUTFBytes(len));
			readObjectCache.push(xmldoc);
			e.value = xmldoc.toString();
			dispatchPluginEvent(e, ba.position);
			return xmldoc;
		}
		
		protected function readDate(ba:ByteArray):Date {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Date', null, 0xBE9E80);
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				e.name = 'Date Reference';
				e.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e.value) as Date;
			}
			
			var d:Date = new Date(ba.readDouble());
			readObjectCache.push(d);
			e.value = d.toString();
			dispatchPluginEvent(e, ba.position);
			return d;
		}
		
		protected function readArray(ba:ByteArray):Array {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Array');
			var ref:int = readUInt29(ba);
			if ((ref & 0x01) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Array Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e2, ba.position);
				return getObjectReference(e2.value) as Array;
			}
			dispatchPluginEvent(e, ba.position);
			
			var l:int = ref >> 1;
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Array Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var arr:Array = new Array();
			readObjectCache.push(arr);
			
			/*
			AMF considers Arrays in two parts, the dense portion and the associative portion. The 
			binary representation of the associative portion consists of name/value pairs (potentially 
			none) terminated by an empty string. 
			
			The binary representation of the dense portion is the 
			size of the dense portion (potentially zero) followed by an ordered list of values 
			(potentially none). 
			
			The order these are written in AMF is first the size of the dense 
			portion, an empty string terminated list of name/value pairs, followed by size values
			*/
			
			// Associative values
			// If none, there will be an empty string signifying it's termination
			var strKey:String = readString(ba);
			while(strKey != "") {
				arr[strKey] = readData(ba);
				strKey = readString(ba);
			}
			
			// Strict values
			for(var i:int = 0; i < l; i++) {
				arr[i] = readData(ba);
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return arr;
		}
		
		/**
		 * A single AMF 3 type handles ActionScript Objects and custom user classes. The term 'traits' 
		 * is used to describe the defining characteristics of a class. In addition to 'anonymous' objects 
		 * and 'typed' objects, ActionScript 3.0 introduces two further traits to describe how objects are 
		 * serialized, namely 'dynamic' and 'externalizable'.
		 * 
		 * Anonymous : an instance of the actual ActionScript Object type or an instance of a Class without 
		 * a registered alias (that will be treated like an Object on deserialization)
		 * 
		 * Typed : an instance of a Class with a registered alias
		 * 
		 * Dynamic : an instance of a Class definition with the dynamic trait declared; public variable members 
		 * can be added and removed from instances dynamically at runtime
		 * 
		 * Externalizable : an instance of a Class that implements flash.utils.IExternalizable and completely 
		 * controls the serialization of its members (no property names are included in the trait information).
		 * 
		 * @param	ba
		 * @return
		 */
		public function readObject(ba:ByteArray):Object {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Object');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Object Reference', null, 0x5760D6);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value);
			}
			dispatchPluginEvent(e, ba.position);
			
			// Read traits
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Object Traits', '', 0x5760D6);
			var traits:Object;
			if ((ref & 3) == 1) {
				e.value += '<br/>*Traits Reference: ' + (ref >> 2) + '*';
				traits = getTraitReference(ref >> 2);
			} else {
				var isExternalizable:Boolean = ((ref & 4) == 4);
				var isDynamic:Boolean = ((ref & 8) == 8);
				var className:String = readString(ba);
				
				var classMemberCount:int = (ref >> 4); /* uint29 */
				var classMembers:Array = new Array();
				for(var i:int = 0; i < classMemberCount; ++i) {
					classMembers.push(readString(ba));
				}
				if (className.length == 0) className = 'Object';
				traits = { type:className, members:classMembers, count:classMemberCount, externalizable:isExternalizable, dynamic:isDynamic };
				readTraitsCache.push(traits);
			}
			
			// Check for any registered class aliases 
			var aliasedClass:String = CLASS_ALIAS_REGISTRY[traits.type];
			if (aliasedClass != null) traits.type = aliasedClass;
			
			e.value += '<br/>Type: ' + traits.type + '<br/>';
			if (traits.members.length > 0) e.value += 'Members: ' + traits.members.toString() + '<br/>';
			e.value += 'Count: ' + traits.count + '<br/>';
			e.value += 'Externalizable: ' + traits.externalizable + '<br/>';
			e.value += 'Dynamic: ' + traits.dynamic + '<br/>';
			dispatchPluginEvent(e, ba.position);
			
			var obj:Object = new Object();
			
			//Add to references as circular references may search for this object
			readObjectCache.push(obj);
			
			if (traits.externalizable) {
				// Read Externalizable
				try {
					if (traits.type.indexOf("flex.") == 0) {
						// Try to get a class
						var classParts:Array = traits.type.split(".");
						var unqualifiedClassName:String = classParts[(classParts.length - 1)];
						if (unqualifiedClassName && flex[unqualifiedClassName]) {
							var flexParser:Object = new flex[unqualifiedClassName]();
							obj = flexParser.readExternal(ba, this);
						} else {
							obj = readData(ba);
						}
					}
				} catch (e:Error) {
					throw Error("AMF3::readObject - Error : Unable to read externalizable data type '" + traits.type + "' | " + e);
				}
			} else {
				var l:int = traits.members.length;
				var key:String;
				
				for (var j:int = 0; j < l; ++j) {
					var val:* = readData(ba);
					key = traits.members[j];
					obj[key] = val;
				}
				
				if (traits.dynamic) {
					key = readString(ba);
					while(key != "") {
						var value:* = readData(ba);
						obj[key] = value;
						key = readString(ba);
					}
				}
			}
			
			if (traits) obj.__traits = traits;
			
			dispatchPluginEvent(new PluginEvent(PluginEvent.END_GROUP, ba.position), ba.position);
			
			return obj;
		}
		
		protected function readXML(ba:ByteArray):XML {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML Length', null, 0xEC65C8);
			var ref:int = readUInt29(ba);
			if((ref & 1) == 0) {
				e.name = 'XML Reference';
				e.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e.value) as XML;
			}
			
			var len:int = ref >> 1;
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'XML', null, 0xEC65C8);
			var xml:XML = new XML(ba.readUTFBytes(len));
			readObjectCache.push(xml);
			e.value = xml.toXMLString();
			dispatchPluginEvent(e, ba.position);
			return xml;
		}
		
		protected function readByteArray(ba:ByteArray):ByteArray {
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'ByteArray Length', null, 0xB8B8B8);
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				e.name = 'ByteArray Reference';
				e.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e.value) as ByteArray;
			}
			
			var len:int = (ref >> 1);
			e.value = len;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'ByteArray', null, 0xB8B8B8);
			var ba2:ByteArray = new ByteArray();
			ba.readBytes(ba2, 0, len);
			readObjectCache.push(ba2);
			dispatchPluginEvent(e, ba.position);
			return ba2;
		}
		
		protected function readVectorInt(ba:ByteArray):Vector.<int> {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Vector.<int>');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<int> Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value) as Vector.<int>;
			}
			dispatchPluginEvent(e, ba.position);
			
			var l:int = (ref >> 1);
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<int> Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var vect:Vector.<int> = new Vector.<int>(l);
			readObjectCache.push(vect);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Fixed Length?', null, 0x30DFC4);
			var isFixed:Boolean = Boolean(readUInt29(ba));
			e.value = isFixed;
			dispatchPluginEvent(e, ba.position);
			
			for(var i:int = 0; i < l; i++) {
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Integer', null, 0x30DFC4);
				vect[i] = ba.readInt();
				e.value = vect[i];
				dispatchPluginEvent(e, ba.position);
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return vect;
		}
		
		protected function readVectorUInt(ba:ByteArray):Vector.<uint> {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Vector.<uint>');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<uint> Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value) as Vector.<uint>;
			}
			dispatchPluginEvent(e, ba.position);
			
			var l:int = (ref >> 1);
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<uint> Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var vect:Vector.<uint> = new Vector.<uint>(l);
			readObjectCache.push(vect);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Fixed Length?', null, 0x30DFC4);
			var isFixed:Boolean = Boolean(readUInt29(ba));
			e.value = isFixed;
			dispatchPluginEvent(e, ba.position);
			
			for(var i:int = 0; i < l; i++) {
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Unsigned Integer', null, 0x30DFC4);
				vect[i] = ba.readUnsignedInt();
				e.value = vect[i];
				dispatchPluginEvent(e, ba.position);
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return vect;
		}
		
		protected function readVectorNumber(ba:ByteArray):Vector.<Number> {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Vector.<Number>');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<Number> Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value) as Vector.<Number>;
			}
			dispatchPluginEvent(e, ba.position);
			
			var l:int = (ref >> 1);
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<Number> Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var vect:Vector.<Number> = new Vector.<Number>(l);
			readObjectCache.push(vect);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Fixed Length?', null, 0x30DFC4);
			var isFixed:Boolean = Boolean(readUInt29(ba));
			e.value = isFixed;
			dispatchPluginEvent(e, ba.position);
			
			for(var i:int = 0; i < l; i++) {
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Number', null, 0x30DFC4);
				vect[i] = ba.readDouble();
				e.value = vect[i];
				dispatchPluginEvent(e, ba.position);
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return vect;
		}
		
		protected function readVectorObject(ba:ByteArray):Vector.<Object> {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Vector.<Object>');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<Object> Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value) as Vector.<Object>;
			}
			dispatchPluginEvent(e, ba.position);
			
			var l:int = (ref >> 1);
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Vector.<Object> Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var vect:Vector.<Object> = new Vector.<Object>(l);
			readObjectCache.push(vect);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Fixed Length?', null, 0x30DFC4);
			var isFixed:Boolean = Boolean(readUInt29(ba));
			e.value = isFixed;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Class Name', '', 0x5760D6);
			// Vector of Object is like an pure object, it's got a traits defining it's type
			var className:String = readString(ba);
			if (className.length == 0) className = 'Object';
			var traits:Object = { type:'Vector.<' + className + '>', fixed:isFixed };
			e.value = className;
			dispatchPluginEvent(e, ba.position);
			
			// Check for any registered class aliases 
			var aliasedClass:String = CLASS_ALIAS_REGISTRY[traits.type];
			if (aliasedClass != null) traits.type = aliasedClass;
			
			// Store traits somewhere
			vect[0] = traits;
			for (var j:int = 1; j <= l; j++) {
				vect[j] = readData(ba);
			}
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return vect;
		}
		
		protected function readDictionary(ba:ByteArray):Dictionary {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Dictionary');
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) {
				var e2:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Dictionary Reference', null, 0x30DFC4);
				e2.value = ref >> 1;
				dispatchPluginEvent(e, ba.position);
				return getObjectReference(e2.value) as Dictionary;
			}
			
			var l:int = (ref >> 1);
			e = new PluginEvent(PluginEvent.HIGHLIGHT, e.startIndex, 'Dictionary Length', l, 0x30DFC4);
			dispatchPluginEvent(e, ba.position);
			
			var dict:Dictionary = new Dictionary();
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Weak Keys?', null, 0x30DFC4);
			var hasWeakKeys:Boolean = Boolean(ba.readBoolean());
			e.value = hasWeakKeys;
			dispatchPluginEvent(e, ba.position);
			
			for (var i:int = 0; i < l; i++) {
				dict[readData(ba)] = readData(ba);
			}
			
			readObjectCache.push(dict);
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchPluginEvent(e, ba.position);
			
			return dict;
		}
		
		/*protected function getStringReference(ref:int):String {
			
		}*/
		
		protected function getTraitReference(ref:int):Object {
			if (ref >= readTraitsCache.length) {
				throw Error("AMF3::getTraitReference - Error : Undefined trait reference '" + ref + "'");
				return null;
			}
			
			return readTraitsCache[ref];
		}
		
		protected function getObjectReference(ref:int):Object {
			if (ref >= readObjectCache.length) {
				throw Error("AMF3::getObjectReference - Error : Undefined object reference '" + ref + "'");
				return null;
			}
			
			return readObjectCache[ref];
		}
	}
}

import com.coursevector.chimera.plugins.AMF3Plugin;
import mx.utils.ObjectUtil;
import flash.utils.ByteArray;

class UUIDUtils {
	
	private static var UPPER_DIGITS:Array = [
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
	];
	
	public static function isUID(uid:String):Boolean {
		if (uid != null && uid.length == 36) {
			var chars:Array = uid.split();
			for (var i:int = 0; i < 36; i++) {
				var cc:Number = uid.charCodeAt(i);
				var c:String = chars[i];
				
				// Check for correctly placed hyphens
				if (i == 8 || i == 13 || i == 18 || i == 23) {
					if (c != '-') return false;
					
					// We allow capital alpha-numeric hex digits only
				} else if (cc < 48 || cc > 70 || (cc > 57 && cc < 65)) {
					return false;
				}
			}
			
			return true;
		}
		
		return false;
	}
	
	public static function fromByteArray(ba:ByteArray):String {
		if (ba != null && ba.length == 16) {
			var result:String = "";
			for (var i:int = 0; i < 16; i++) {
				if (i == 4 || i == 6 || i == 8 || i == 10) result += "-";
				
				result += UPPER_DIGITS[(ba[i] & 0xF0) >>> 4];
				result += UPPER_DIGITS[(ba[i] & 0x0F)];
			}
			return result;
		}
		
		return null;
	}
	
	public static function toByteArray(uid:String):ByteArray {
		if (isUID(uid)) {
			/*byte[] result = new byte[16];
			char[] chars = uid.toCharArray();
			int r = 0;
			
			for (int i = 0; i < chars.length; i++) {
			if (chars[i] == '-') continue;
			int h1 = Character.digit(chars[i], 16);
			i++;
			int h2 = Character.digit(chars[i], 16);
			result[r++] = (byte)(((h1 << 4) | h2) & 0xFF);
			}
			return result;*/
		}
		
		return null;
	}
}

dynamic class AbstractMessage {
	
	// AbstractMessage Serialization Constants
	protected const HAS_NEXT_FLAG:int = 128;
	protected const BODY_FLAG:int = 1;
	protected const CLIENT_ID_FLAG:int = 2;
	protected const DESTINATION_FLAG:int = 4;
	protected const HEADERS_FLAG:int = 8;
	protected const MESSAGE_ID_FLAG:int = 16;
	protected const TIMESTAMP_FLAG:int = 32;
	protected const TIME_TO_LIVE_FLAG:int = 64;
	protected const CLIENT_ID_BYTES_FLAG:int = 1;
	protected const MESSAGE_ID_BYTES_FLAG:int = 2;
	
	//AsyncMessage Serialization Constants
	protected const CORRELATION_ID_FLAG:int = 1;
	protected const CORRELATION_ID_BYTES_FLAG:int = 2;
	
	// CommandMessage Serialization Constants
	protected const OPERATION_FLAG:int = 1;
	
	public var clientId:Object; // object
	public var destination:String; // string
	public var messageId:String; // string
	public var timestamp:Number; // number
	public var timeToLive:Number; // number
	
	public var headers:Object; // Map
	public var body:Object; // object
	
	public var clientIdBytes:ByteArray; // byte array
	public var messageIdBytes:ByteArray; // byte array
	
	public function readExternal(ba:ByteArray, parser:AMF3Plugin):AbstractMessage {
		var flagsArray:Array = readFlags(ba);
		for (var i:int = 0; i < flagsArray.length; ++i) {
			var flags:int = flagsArray[i];
			var reservedPosition:int = 0;
			
			if (i == 0) {
				if ((flags & BODY_FLAG) != 0) readExternalBody(ba, parser);
				if ((flags & CLIENT_ID_FLAG) != 0) clientId = parser.readData(ba);
				if ((flags & DESTINATION_FLAG) != 0) destination = parser.readData(ba);
				if ((flags & HEADERS_FLAG) != 0) headers = parser.readData(ba);
				if ((flags & MESSAGE_ID_FLAG) != 0) messageId = parser.readData(ba);
				if ((flags & TIMESTAMP_FLAG) != 0) timestamp = parser.readData(ba);
				if ((flags & TIME_TO_LIVE_FLAG) != 0) timeToLive = parser.readData(ba);
				reservedPosition = 7;
			} else if (i == 1) {
				if ((flags & CLIENT_ID_BYTES_FLAG) != 0) {
					var clientIdBytes:ByteArray = parser.readData(ba);
					clientId = UUIDUtils.fromByteArray(clientIdBytes);
				}
				
				if ((flags & MESSAGE_ID_BYTES_FLAG) != 0) {
					var messageIdBytes:ByteArray = parser.readData(ba);
					messageId = UUIDUtils.fromByteArray(messageIdBytes);
				}
				
				reservedPosition = 2;
			}
			
			// For forwards compatibility, read in any other flagged objects to
			// preserve the integrity of the input stream...
			if ((flags >> reservedPosition) != 0) {
				for (var j:int = reservedPosition; j < 6; ++j) {
					if (((flags >> j) & 1) != 0) parser.readData(ba);
				}
			}
		}
		
		return this;
	}
	
	public function readExternalBody(ba:ByteArray, parser:AMF3Plugin):void {
		body = parser.readData(ba);
	}
	
	public function readFlags(ba:ByteArray):Array {
		var hasNextFlag:Boolean = true; 
		var flagsArray:Array = [];
		var i:int = 0;
		
		while (hasNextFlag) {
			var flags:uint = ba.readUnsignedByte();
			/*if (i == flagsArray.length) {
			short[] tempArray = new short[i*2];
			System.arraycopy(flagsArray, 0, tempArray, 0, flagsArray.length);
			flagsArray = tempArray;
			}*/
			
			flagsArray[i] = flags;
			hasNextFlag = ((flags & HAS_NEXT_FLAG) != 0) ? true : false;
			i++;
		}
		
		return flagsArray;
	}
};

dynamic class AsyncMessage extends AbstractMessage {
	
	public var correlationId:String;
	public var correlationIdBytes:ByteArray;
	
	override public function readExternal(ba:ByteArray, parser:AMF3Plugin):AbstractMessage {
		super.readExternal(ba, parser);
		
		var flagsArray:Array = this.readFlags(ba);
		for (var i:int = 0; i < flagsArray.length; ++i) {
			var flags:int = flagsArray[i];
			var reservedPosition:int = 0;
			
			if (i == 0) {
				if ((flags & CORRELATION_ID_FLAG) != 0) correlationId = parser.readData(ba);
				
				if ((flags & CORRELATION_ID_BYTES_FLAG) != 0) {
					correlationIdBytes = parser.readData(ba);
					correlationId = UUIDUtils.fromByteArray(correlationIdBytes);
				}
				
				reservedPosition = 2;
			}
			
			// For forwards compatibility, read in any other flagged objects
			// to preserve the integrity of the input stream...
			if ((flags >> reservedPosition) != 0) {
				for (var j:int = reservedPosition; j < 6; ++j) {
					if (((flags >> j) & 1) != 0) parser.readData(ba);
				}
			}
		}
		
		return this;
	}
}

dynamic class AsyncMessageExt extends AsyncMessage {
	//
}

dynamic class AcknowledgeMessage extends AsyncMessage {
	override public function readExternal(ba:ByteArray, parser:AMF3Plugin):AbstractMessage {
		super.readExternal(ba, parser);
		
		var flagsArray:Array = readFlags(ba);
		for (var i:int = 0; i < flagsArray.length; ++i) {
			var flags:int = flagsArray[i];
			var reservedPosition:int = 0;
			
			// For forwards compatibility, read in any other flagged objects
			// to preserve the integrity of the input stream...
			if ((flags >> reservedPosition) != 0) {
				for (var j:int = reservedPosition; j < 6; ++j) {
					if (((flags >> j) & 1) != 0) parser.readData(ba);
				}
			}
		}
		
		return this;
	}
}

dynamic class AcknowledgeMessageExt extends AcknowledgeMessage {
	//
}

dynamic class CommandMessage extends AsyncMessage {
	public var operation:int = 1000;
	public var operationName:String = "unknown";
	
	override public function readExternal(ba:ByteArray, parser:AMF3Plugin):AbstractMessage {
		super.readExternal(ba, parser);
		
		var flagsArray:Array = readFlags(ba);
		for (var i:int = 0; i < flagsArray.length; ++i) {
			var flags:int = flagsArray[i];
			var reservedPosition:int = 0;
			var operationNames:Array = [
				"subscribe", "unsubscribe", "poll", "unused3", "client_sync", "client_ping",
				"unused6", "cluster_request", "login", "logout", "subscription_invalidate",
				"multi_subscribe", "disconnect", "trigger_connect"
			];
			
			if (i == 0) {
				if ((flags & OPERATION_FLAG) != 0) {
					operation = parser.readData(ba);
					if (operation < 0 || operation >= operationNames.length) {
						operationName = "invalid." + operation + "";
					} else {
						operationName = operationNames[operation];
					}
				}
				reservedPosition = 1;
			}
			
			// For forwards compatibility, read in any other flagged objects
			// to preserve the integrity of the input stream...
			if ((flags >> reservedPosition) != 0) {
				for (var j:int = reservedPosition; j < 6; ++j) {
					if (((flags >> j) & 1) != 0) parser.readData(ba);
				}
			}
		}
		
		return this;
	}
}

dynamic class CommandMessageExt extends CommandMessage {
	//
}

dynamic class ErrorMessage extends AcknowledgeMessage {
	//
}

//flex.messaging.io.ArrayCollection
dynamic class ArrayCollection {
	public var source:Object;
	
	public function readExternal(ba:ByteArray, parser:AMF3Plugin):ArrayCollection {
		this.source = parser.readData(ba);
		return this;
	}
}

dynamic class ArrayList extends ArrayCollection {
	//
}

dynamic class ObjectProxy {
	public function readExternal(ba:ByteArray, parser:AMF3Plugin):ObjectProxy {
		var obj:Object = parser.readData(ba);
		for (var i:String in obj) {
			this[i] = obj[i];
		}
		return this;
	}
}

dynamic class ManagedObjectProxy extends ObjectProxy {
	//
}

dynamic class SerializationProxy {
	public var defaultInstance:Object;
	
	public function readExternal(ba:ByteArray, parser:AMF3Plugin):SerializationProxy {
		/*var saveObjectTable = null;
		var saveTraitsTable = null;
		var saveStringTable = null;
		var in3 = null;
		
		if (ba instanceof Amf3Input) in3 = ba;*/
		
		try {
			/*if (in3 != null) {
			saveObjectTable = in3.saveObjectTable();
			saveTraitsTable = in3.saveTraitsTable();
			saveStringTable = in3.saveStringTable();
			}*/
			
			defaultInstance = parser.readData(ba);
		} finally {
			/*if (in3 != null) {
			in3.restoreObjectTable(saveObjectTable);
			in3.restoreTraitsTable(saveTraitsTable);
			in3.restoreStringTable(saveStringTable);
			}*/
		}
		
		return this;
	}
}

// flex.management.jmx.Attribute
dynamic class Attribute {
	
	/**
	 * The attribute name.
	 */
	public var name:String;
	
	/**
	 * The attribute value.
	 */
	public var value:Object;
	
	/**
	 *  Returns a string representation of the attribute.
	 * 
	 *  @return String representation of the attribute.
	 */
	public function toString():String {
		return ObjectUtil.toString(this);
	}
}
