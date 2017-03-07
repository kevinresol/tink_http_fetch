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
						#elseif php new SecurePhpClient()
						#elseif sys new SecureSocketClient()
						#end
					else 
						#if (js && !nodejs) new JsClient()
						#elseif nodejs new NodeClient()
						#elseif php new PhpClient()
						#elseif sys new SocketClient()
						#end ;
				case Local(c): new LocalContainerClient(c);
				case Curl: secure ? new SecureCurlClient() : new CurlClient();
				#if (js || php) case Std: secure ? new SecureStdClient() : new StdClient(); #end
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
	#if (js || php) Std; #end
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

// TODO: move to tink_http
class SecureSocketClient extends SocketClient {
	public function new(?worker:Worker) {
		super(worker);
		protocol = 'https';
	}
}

// TODO: move to tink_http
class SocketClient implements tink.http.Client.ClientObject {
	var worker:Worker;
	var protocol:String = 'http';
	public function new(?worker:Worker) {
		this.worker = worker.ensure();
	}
	
	public function request(req:OutgoingRequest):Future<IncomingResponse> {
		
		return Future.async(function(cb) {
			
			var secure = protocol == 'https';
			var socket = 
				if(secure)
					#if php new php.net.SslSocket();
					#elseif java new java.net.SslSocket();
					#elseif (!no_ssl && (hxssl || hl || cpp || (neko && !(macro || interp)))) new sys.ssl.Socket();
					#else throw "Https is only supported with -lib hxssl";
					#end
				else
					new sys.net.Socket();
				
			var sink = tink.io.Sink.ofOutput('Output', socket.output);
			var source = tink.io.Source.ofInput('Input', socket.input);
			var port = switch req.header.host.port {
				case null: secure ? 443 : 80;
				case v: v;
			}
			socket.connect(new sys.net.Host(req.header.host.name), port);
			
			var data:tink.io.Source = req.header.toString();
			data = data.append(req.body);
			data = data.append(' '); // HACK: otherwise the server won't respond?
			
			data.pipeTo(sink).map(function(r) {
				switch r {
					case AllWritten:
						source.parse(ResponseHeader.parser()).handle(function(o) switch o {
							case Success(parsed):
								cb(new IncomingResponse(
									parsed.data,
									parsed.rest
								));
							case Failure(e):
								cb(new IncomingResponse(
									new ResponseHeader(500, 'Header parse error', []),
									std.Std.string(e)
								));
						});
						
					default: 
						cb(new IncomingResponse(
							new ResponseHeader(500, 'Pipe error', []),
							std.Std.string(r)
						));
				}
			});
			
		});
	}
}