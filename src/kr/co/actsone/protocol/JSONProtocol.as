/*********************************************************************************
 *
 *  ACTSONE COMPANY
 *  Copyright 2013 Actsone 
 *  All Rights Reserved.
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************************/

package kr.co.actsone.protocol
{
	import com.brokenfunction.json.decodeJson;
	import com.brokenfunction.json.encodeJson;
	
	public class JSONProtocol extends ProtocolBase
	{
		public static const LICENSES:String="licenses";
		
		public static const VERSION:String="version";
		
		public static const PARAMS:String="params";
		
		public static const MESSAGE:String="message";
		
		public static const STATUS:String="status";
		
		private var _jsonObj:Object;
		
		public function get jsonObj():Object
		{
			return this._jsonObj;
		}
		
		public function set jsonObj(value:Object):void
		{
			this._jsonObj=value;
		}
		
		private var _jsonData:String="";
		
		public function get jsonData():String
		{
			return this._jsonData;
		}
		
		public function set jsonData(value:String):void
		{
			this._jsonData=value;
		}
		
		private var _version:String="";
		
		public function get version():String
		{
			return this._version;
		}
		
		public function set version(value:String):void
		{
			this._version=value;
		}
		
		private var _message:String="";
		
		public function get message():String
		{
			return this._message;
		}
		
		public function set message(value:String):void
		{
			this._message=value;
		}
		
		private var _status:String="";
		
		public function get status():String
		{
			return this._status;
		}
		
		public function set status(value:String):void
		{
			this._status=value;
		}
		
		private var _licenses:Array;
		
		public function get licenses():Array
		{
			return this._licenses;
		}
		
		public function set licenses(value:Array):void
		{
			this._licenses=value;
		}
		
		private var _params:Object;
		
		public function get params():Object
		{
			return this._params;
		}
		
		public function set params(value:Object):void
		{
			this._params=value;
		}
		
		public function JSONProtocol(flexApp:Object)
		{
			super(flexApp);	
		}
		
		override public function decode(value:String):Object
		{
			var reg:RegExp=new RegExp("'","g");
			this.jsonData=value.replace(reg,"\"");
			this.jsonObj=decodeJson(jsonData);
			this.licenses=jsonObj[LICENSES];
			this.params=jsonObj[PARAMS]
			this.version=jsonObj[VERSION];
			this.status=jsonObj[STATUS];
			return null;
		}
		
		override public function encode(obj:Object):String
		{
			this.jsonData=encodeJson(obj);
			var reg:RegExp=new RegExp("\"","g");
			var result:String=jsonData.replace(reg,"'");
			return result;
		}
		
	}
}