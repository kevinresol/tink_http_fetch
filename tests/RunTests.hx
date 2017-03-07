package ;

import haxe.io.Bytes;
import haxe.Json;
import tink.unit.TestRunner;
import tink.unit.Assert.*;
import tink.http.Fetch.*;
import tink.http.Response;
import tink.http.Header;

using haxe.Json;
using tink.CoreApi;

class RunTests {

  static function main() {
    
    TestRunner.run([
      new RunTests()
    ]).handle(function(result) travix.Logger.exit(result.errors));
    
  }
  
  public function new() {}
  
  public function testGet() {
    return fetch('http://httpbin.org/').map(function(res) return equals(200, res.header.statusCode));
  }
  
  public function testSecureGet() {
    // make sure original operator overloads work
    return fetch('https://httpbin.org/').asFuture() >> function(res:IncomingResponse) return equals(200, res.header.statusCode);
  }
  
  public function testHeaders() {
    var name = 'my-sample-header';
    var value = 'foobar';
    return fetch('https://httpbin.org/headers', {
      headers:[{name: name, value: value}],
    }).all().next(
      function(res) 
        return equals(200, res.header.statusCode) && 
          objectToHeader(res.body.toString().parse().headers).byName(name).flatMap(function(v) return equals(value, v))
    );
  }
  
  public function testPost() {
    var body = 'Hello, World!';
    return fetch('http://httpbin.org/post', {
      method: POST,
      headers:[{name: 'content-type', value: 'text/plain'}],
      body: body,
    }).all().next(function(res) return equals(200, res.header.statusCode) && equals(body, res.body.toString().parse().data));
  }
  
  public function testSecurePost() {
    var body = 'Hello, World!';
    return fetch('https://httpbin.org/post', {
      method: POST,
      headers:[{name: 'content-type', value: 'text/plain'}],
      body: body,
    }).all().next(function(res) return equals(200, res.header.statusCode) && equals(body, res.body.toString().parse().data));
  }
  
  function objectToHeader(obj:Dynamic) {
    return new Header([for(key in Reflect.fields(obj)) new HeaderField(key, Reflect.field(obj, key))]);
  }
  
}