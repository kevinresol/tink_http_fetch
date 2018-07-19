Deprecated: The code is now moved into the [tink_http](https://github.com/haxetink/tink_http) library itself. See `tink.http.Client.fetch()`.

# Tinkerbell HTTP Fetch [![Build Status](https://travis-ci.org/kevinresol/tink_http_fetch.svg?branch=master)](https://travis-ci.org/kevinresol/tink_http_fetch)

A fetch-like API based on tink_http

The API is very simple:

```haxe
class Fetch {
	public static function fetch(url:Url, ?options:FetchOptions):Future<IncomingResponse>;
}

typedef FetchOptions = {
	?method:Method,
	?headers:Array<HeaderField>,
	?body:IdealSource,
	?client:ClientType,
	?followRedirect:Bool, // default: true
}
```
