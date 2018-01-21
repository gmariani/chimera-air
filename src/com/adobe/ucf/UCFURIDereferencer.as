//  Adobe(R) Systems Incorporated Source Code License Agreement
//  Copyright(c) 2006-2010 Adobe Systems Incorporated. All rights reserved.
//	
//  Please read this Source Code License Agreement carefully before using
//  the source code.
//	
//  Adobe Systems Incorporated grants to you a perpetual, worldwide, non-exclusive, 
//  no-charge, royalty-free, irrevocable copyright license, to reproduce,
//  prepare derivative works of, publicly display, publicly perform, and
//  distribute this source code and such derivative works in source or 
//  object code form without any attribution requirements.    
//	
//  The name "Adobe Systems Incorporated" must not be used to endorse or promote products
//  derived from the source code without prior written permission.
//	
//  You agree to indemnify, hold harmless and defend Adobe Systems Incorporated from and
//  against any loss, damage, claims or lawsuits, including attorney's 
//  fees that arise or result from your use or distribution of the source 
//  code.
//  
//  THIS SOURCE CODE IS PROVIDED "AS IS" AND "WITH ALL FAULTS", WITHOUT 
//  ANY TECHNICAL SUPPORT OR ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING,
//  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  ALSO, THERE IS NO WARRANTY OF 
//  NON-INFRINGEMENT, TITLE OR QUIET ENJOYMENT.  IN NO EVENT SHALL ADOBE 
//  OR ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOURCE CODE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package com.adobe.ucf {
	import flash.security.IURIDereferencer;
	import flash.utils.IDataInput;
	import flash.utils.ByteArray;
	
	internal class UCFURIDereferencer implements IURIDereferencer {

		public function UCFURIDereferencer( signatures:XML ) {
			_signatures = signatures;
		}
		
 		public function dereference( uri:String ):IDataInput {
			var xmldsig:Namespace = new Namespace( "http://www.w3.org/2000/09/xmldsig#" );
   			var result:XMLList = null;
			
			switch( uri ) {
				case "#PackageContents":
					result = _signatures..xmldsig::Manifest.(@Id="PackageContents");
					break;
					
				case "#PackageSignatureValue":
					result = _signatures..xmldsig::Signaturevalue.(@Id="PackageSignatureValue");
					break;
					
				default:
					throw new Error( "unrecognized URI " + uri );
			}
			
			var buffer:ByteArray = new ByteArray();
			buffer.writeUTFBytes( result.toXMLString());
			buffer.position = 0;
			return buffer;
 		}
		
		private var _signatures:XML;
	}
}
