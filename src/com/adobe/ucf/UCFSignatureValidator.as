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
	
	import com.hurlant.crypto.hash.IHash;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.hash.SHA256;
	
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.security.XMLSignatureValidator;
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	
	/**
	 * UCFSignatureValidator is used to validate the package signature of a UCF file.
	 */
	
	public final class UCFSignatureValidator extends EventDispatcher {				

		private const SHA256_ALGORITHM:String = "http://www.w3.org/2001/04/xmlenc#sha256";
		private const SHA1_ALGORITHM:String   = "http://www.w3.org/2000/09/xmldsig#sha1";
		
		private const STATUS_INVALID     :String    = "invalid"
		private const SIGNATURE_FILE_PATH:String    = "META-INF/signatures.xml";
		private const XMLDSIG            :Namespace = new Namespace( "http://www.w3.org/2000/09/xmldsig#" );
		private const XADES              :Namespace = new Namespace( "http://uri.etsi.org/01903/v1.1.1#"  );

		private var xmldsigElements:Object = { CanonicalizationMethod:true, DigestMethod:true, DigestValue:true, KeyInfo:true, Manifest:true, Object:true, Reference:true, Signature:true, SignedInfo:true, SignatureMethod:true, SignatureValue:true, Transform:true, Transforms:true, X509Certificate:true, X509CRL:true, X509Data:true };
		private var xadesElements:Object = { EncapsulatedTimeStamp:true, HashDataInfo:true, QualifyingProperties:true, SignatureTimeStamp:true, UnsignedProperties:true, UnsignedSignatureProperties: true };

		private var   _validator     :XMLSignatureValidator;
		private var   _packageRoot   :File;
		private var   _validityStatus:String;

		public function UCFSignatureValidator() {
			_validator = new XMLSignatureValidator();
		}
		
		public function get packageRoot():File {
			return _packageRoot;
		}
		
		public function get xmlSignatureValidator():XMLSignatureValidator {
			return _validator;
		}
		
		/** 
		 * The root won't be examined for the contents of the UCF package
		 * until (and unless) verify() is called.
		 */
		
		public function set packageRoot( value:File ):void {
			_packageRoot = value;
		}
		
		/**
		 * Specifies whether or not certificates in the system trust store are used 
		 * for chain building.
		 * 
		 * <p>If <code>true</code>, then the trust anchors in the system trust store 
		 * are used as trusted roots. The system trust store is not used by default.</p>
		 * 
		 * @throws IllegalOperationError If set while a signature is being validated.
		 */
		
		public function set useSystemTrustStore( trusted:Boolean ):void {
			_validator.useSystemTrustStore = trusted;
		}
		
		public function get useSystemTrustStore():Boolean {
			return _validator.useSystemTrustStore;
		}
		
		/**
		 * Adds an x509 certificate for chain building.
		 *
		 * <p>The certificate added must be a DER-encoded x509 certificate.</p>
		 *
		 * <p>If the <code>trusted</code> parameter is <code>true</code>, the
		 * certificate is considered a trust anchor.</p>
		 *
		 * <p><b>Note:</b> An XML signature may include certificates for building
		 * the signer's certificate chain. The UCFSignatureValidator class uses
		 * these certificates for chain building, but not as trusted roots (by default).</p>
		 *
		 * @param cert    A ByteArray object containing a DER-encoded x509 digital certificate.
		 * @param trusted Set to <code>true</code> to designate this certificate as a trust anchor.
		 * 
		 * @throws IllegalOperationError If called while a signature is being validated.
		 */
		
		public function addCertificate( cert:ByteArray, trusted:Boolean ):void {
			_validator.addCertificate( cert, trusted );
		}
		
		/**
		 * Asynchronously verifies the signature of the UCF package contained in the 
		 * packageRoot directory. Dispatches COMPLETE if successful; note that you must
		 * still check validityStatus to see whether or not the signature is valid.
		 * Dispatches ERROR if something goes wrong and the validity status cannot be
		 * determined.
		 * 
		 * @throws IllegalOperationError If packageRoot is not set.
		 * @throws Error                 If the package does not contain a valid signature.
		 */
		
		public function verify():void {
			if( _packageRoot == null ) throw new IllegalOperationError( "Package root not set." );
			if( !_packageRoot.resolvePath( SIGNATURE_FILE_PATH ).exists ) throw new Error( "Package does not contain a signature file." );
			
			var signatures      :XML = this.readXMLFromFile( _packageRoot.resolvePath( SIGNATURE_FILE_PATH ));
			var packageSignature:XML = XML( signatures.XMLDSIG::Signature.(@Id="PackageSignature"));
			
			// Certain kinds of modifications to the signatures.xml file are allowed after the 
			// PackageSignature has been created, e.g., adding additional signatures. However,
			// not all kinds of modifications should be allowed, as that capability could be abused.
			// This block of code makes sure that all elements in the signature file appear to
			// fall into the legitimate use cases.

			var noMatch:Boolean = true;
			
			for each( var element:XML in signatures.descendants()) {
				if( element.nodeKind() != "element" ) continue;
				
				switch( element.namespace().uri ) {
					case XMLDSIG.uri:
						if( !xmldsigElements[element.localName()] ) {
							throw new Error( "Illegal xmldsig element in signature: " + element.toXMLString());
						}
						noMatch = false;
						break;
					case XADES.uri:
						if( !xadesElements[element.localName()] ) {
							throw new Error( "Illegal xades element in signature: " + element.toXMLString());
						}
						noMatch = false;
						break;
					default:
						throw new Error( "Illegal element in signature: " + element.toXMLString());
				}
			}

			if (noMatch) {
				throw new Error("Illegal signature XML format.");
			}
			
			_validator.uriDereferencer = new UCFURIDereferencer( signatures );
			_validator.addEventListener( Event.COMPLETE, onComplete );
			_validator.addEventListener( ErrorEvent.ERROR, onError );
			_validator.verify( packageSignature );
		}
		
		public function get validityStatus():String {
			return this._validityStatus;
		}
		
		private function onComplete( event:Event ):void {
			
			// To begin with, set our validity to that of the signature. If the signature is already
			// invalid, stop here: processing more is both unnecessary and potentially dangerous.
			//
			// Implementation Note: In general, once a signature is determined to be invalid, processing
			// should stop. This method uses a short-circuiting return to implement that logic.
			
			// TODO: Check into referencesValidationSetting; it's possible we also need to stop here
			// if the cert is unknown, I think.
			
			_validityStatus = _validator.validityStatus;
			if( _validityStatus == STATUS_INVALID ) {
				dispatchEvent( event.clone());
				return;
			}
			
			// The signature is valid; now make sure the package contents match the manifest.
			// This is really what distinguishes UCF signature validation from plain-old 
			// XML signature validation.
			
			var signatures     :XML     = this.readXMLFromFile( _packageRoot.resolvePath( SIGNATURE_FILE_PATH ));
			var references     :XMLList = signatures..XMLDSIG::Manifest.(@Id="PackageContents").XMLDSIG::Reference;
			var referencedFiles:Object  = new Object();
			
			for each( var reference:XML in references ) {
				
				var base64Decoder:Base64Decoder = new Base64Decoder;
				base64Decoder.decode(reference.XMLDSIG::DigestValue.toString());
				var expectedDigest:ByteArray = base64Decoder.toByteArray();
				
				var file:File = _packageRoot.resolvePath( reference.@URI );
				if( !file.exists ) {
					_validityStatus = STATUS_INVALID;
					dispatchEvent( event.clone());
					return;
				}
				
				// TODO: Read large file asynchronously, thus reducing the time this routine blocks for.

				var hasher:IHash;
				var algorithm:String = reference.XMLDSIG::DigestMethod.@Algorithm;
				
				// Only supports SHA1 and SHA256 for now
				switch (algorithm) {
					case SHA256_ALGORITHM:
						hasher = new SHA256();
						break;
					case SHA1_ALGORITHM:
						hasher = new SHA1();
						break;
					default:
						_validityStatus = STATUS_INVALID;
						dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, "Unsupported digest method: " + reference.XMLDSIG::DigestMethod.@Algorithm ));
						return;
				}
				
				var actualDigest:ByteArray = hasher.hash(this.readByteArrayFromFile(file));

				if( actualDigest.length != expectedDigest.length ) {
					_validityStatus = STATUS_INVALID;
					dispatchEvent( event.clone());
					return;
				}
				
				expectedDigest.position = 0;
				actualDigest  .position = 0;
				for( var i:int = 0; i < actualDigest.length; i++ ) {
					if( expectedDigest.readByte() != actualDigest.readByte()) {
						_validityStatus = STATUS_INVALID;
						dispatchEvent( event.clone());
						return;
					}
				}
				
				referencedFiles[reference.@URI] = true;
			}
			
			// Breadth-first check of files on disk to make sure they all appear in the manifest.
			
			var filesToCheck:Array = _packageRoot.getDirectoryListing();
			while( filesToCheck.length > 0 ) {
				var fileToCheck:File = filesToCheck.pop();
				if( fileToCheck.isDirectory ) {
					filesToCheck.push.apply( filesToCheck, fileToCheck.getDirectoryListing());
					continue;
				}
				
				var relativePath   :String  = _packageRoot.getRelativePath( fileToCheck );
				var referenced     :Boolean = referencedFiles[relativePath];
				var isSignatureFile:Boolean = ( relativePath == SIGNATURE_FILE_PATH );
				if( !referenced && !isSignatureFile ) {
					_validityStatus = STATUS_INVALID;
					dispatchEvent( event.clone());
					return;
				}
			}
			
			dispatchEvent( event.clone());
		}

		private function readByteArrayFromFile(f:File):ByteArray {
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes, 0, fs.bytesAvailable);
			fs.close();
			return bytes;
		}
		
		private function readXMLFromFile(f:File):XML {
			return new XML(this.readByteArrayFromFile(f));
		}

		private function onError( event:ErrorEvent ):void {
			dispatchEvent( event.clone());
		}
	}
}
