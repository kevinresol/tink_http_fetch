package tink.http;

import tink.http.Request;
import tink.http.Response;
import tink.http.Header;
import tink.http.Method;
import tink.http.Client;
import tink.io.IdealSource;
import tink.url.Host;
import tink.Url;

using tink.CoreApi;

class Fetch {
	
	static var client(get, null):Client;
	static var sclient(get, null):Client;
	
	public static function fetch(url:Url, ?options:FetchOptions) {
		
		return Future.async(function(cb) {
			
			var client = url.scheme == 'https' ? sclient : client;
			
			var uri:String = url.path;
			if(url.query != null) uri += '?' + url.query;
			
			var method = GET;
			var headers = null;
			var body:IdealSource = Empty.instance;
			
			if(options != null) {
				if(options.method != null) method = options.method;
				if(options.headers != null) headers = options.headers;
				if(options.body != null) body = options.body;
			}
			
			client.request(new OutgoingRequest(
				new OutgoingRequestHeader(method, url.host, uri, headers),
				body
			)).handle(function(res) {
				switch res.header.statusCode {
					case 301 | 302: fetch(res.header.byName('location').sure(), options).handle(cb); // TODO: reconstruct body
					// TODO: case 307 | 308: 
					default: cb(res);
				}
			});
			
		});
	}
	
	static function get_client() {
		if(client == null) client =
			#if (js && !nodejs) new JsClient()
			#elseif nodejs new NodeClient()
			#elseif sys new StdClient()
			#end ;
		return client;
	}
		
	static function get_sclient() {
		if(sclient == null) sclient =
			#if (js && !nodejs) new JsSecureClient()
			#elseif nodejs new NodeSecureClient()
			#elseif sys new SecureStdClient()
			#end ;
			
		return sclient;
	}
}

typedef FetchOptions = {
	?method:Method,
	?headers:Array<HeaderField>,
	?body:IdealSource,
}