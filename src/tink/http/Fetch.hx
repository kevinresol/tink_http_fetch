package tink.http;

import haxe.io.Bytes;
import tink.http.Request;
import tink.http.Response;
import tink.http.Header;
import tink.http.Method;
import tink.http.Client;
import tink.io.IdealSource;
import tink.url.Host;
import tink.io.Worker;
import tink.Url;

using tink.CoreApi;

class Fetch {
	
	static var client = new Map<ClientType, Client>();
	static var sclient = new Map<ClientType, Client>();
	
	public static function fetch(url:Url, ?options:FetchOptions):FetchResponse {
		
		return Future.async(function(cb) {
			
			var uri:String = url.path;
			if(url.query != null) uri += '?' + url.query;
			
			var method = GET;
			var headers = null;
			var body:IdealSource = Empty.instance;
			var type = Default;
			
			if(options != null) {
				if(options.method != null) method = options.method;
				if(options.headers != null) headers = options.headers;
				if(options.body != null) body = options.body;
				if(options.client != null) type = options.client; 
			}
			
			var client = getClient(type, url.scheme == 'https');
			client.request(new OutgoingRequest(
				new OutgoingRequestHeader(method, url.host, uri, headers),
				body
			)).handle(function(res) {
				switch res.header.statusCode {
					case 301 | 302: fetch(url.resolve(res.header.byName('location').sure()), options).handle(cb); // TODO: reconstruct body
					// TODO: case 307 | 308: 
					default: cb(res);
				}
			});
		});
	}
	
	static function getClient(type:ClientType, secure:Bool) {
		var cache = secure ? sclient : client;
		
		if(!cache.exists(type)) {
			
			var c:Client = switch type {
				case Default:
					if(secure)
						#if (js && !nodejs) new JsSecureClient()
						#elseif nodejs new NodeSecureClient()
						#elseif sys new SecureSocketClient()
						#end
					else 
						#if (js && !nodejs) new JsClient()
						#elseif nodejs new NodeClient()
						#elseif sys new SocketClient()
						#end ;
				case Local(c): new LocalContainerClient(c);
				case Curl: secure ? new SecureCurlClient() : new CurlClient();
				#if php case Php: secure ? new SecurePhpClient() : new PhpClient(); #end
				// #if (js || php) case Std: secure ? new SecureStdClient() : new StdClient(); #end
				#if tink_tcp case Tcp: secure ? new SecureTcpClient() : new TcpClient(); #end
			}
			
			cache.set(type, c);
		}
		
		return cache.get(type);
		
	}
}

typedef FetchOptions = {
	?method:Method,
	?headers:Array<HeaderField>,
	?body:IdealSource,
	?client:ClientType,
}

enum ClientType {
	Default;
	Local(container:tink.http.containers.LocalContainer);
	Curl;
	#if php Php; #end
	// #if (js || php) Std; #end
	#if tink_tcp Tcp; #end
}

@:forward
abstract FetchResponse(Future<IncomingResponse>) from Future<IncomingResponse> to Future<IncomingResponse> {
	public function all():Promise<CompleteResponse> {
		return this >> 
			function(res:IncomingResponse) return res.body.all() >>
			function(bytes:Bytes) return new CompleteResponse(res.header, bytes);
	}
	
	public function asFuture():Future<IncomingResponse>
		return this;
}

class CompleteResponse {
	public var header:ResponseHeader;
	public var body:Bytes;
	
	public function new(header, body) {
		this.header = header;
		this.body = body;
	}
}
