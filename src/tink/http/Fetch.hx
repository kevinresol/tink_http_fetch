package tink.http;

import tink.http.Request;
import tink.http.Response;
import tink.http.Header;
import tink.http.Method;
import tink.http.Client;
import tink.io.IdealSource;
import tink.url.Host;
import tink.Url;

class Fetch {
	
	static var client(get, null):Client;
	static var sclient(get, null):Client;
	
	public static function fetch(url:Url, ?options:FetchOptions) {
		
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
		
		return client.request(new OutgoingRequest(
			new OutgoingRequestHeader(method, url.host, uri, headers),
			body
		));
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