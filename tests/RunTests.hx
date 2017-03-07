package ;

import haxe.io.Bytes;
import haxe.Json;
import tink.unit.TestRunner;
import tink.unit.Assert.*;
import tink.http.Fetch.*;
import tink.http.Response;
import tink.http.Header;
import tink.http.Method;

using haxe.Json;
using tink.CoreApi;

@:timeout(10000)
class RunTests {

  static function main() {
    
    TestRunner.run([
      new RunTests()
    ]).handle(function(result) travix.Logger.exit(result.errors));
    
  }
  
  public function new() {}
  
  public function testGet() return testStatus('http://httpbin.org/');
  public function testSecureGet() return testStatus('https://httpbin.org/');
  public function testPost() return testData('https://httpbin.org/post', POST);
  public function testSecurePost() return testData('https://httpbin.org/post', POST);
  public function testDelete() return testData('https://httpbin.org/delete', DELETE);
  public function testSecureDelete() return testData('https://httpbin.org/delete', DELETE);
  public function testPatch() return testData('https://httpbin.org/patch', PATCH);
  public function testSecurePatch() return testData('https://httpbin.org/patch', PATCH);
  public function testPut() return testData('https://httpbin.org/put', PUT);
  public function testSecurePut() return testData('https://httpbin.org/put', PUT);
  public function testRedirect() return testStatus('http://httpbin.org/redirect/5');
  public function testSecureRedirect() return testStatus('https://httpbin.org/redirect/5');
  
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
  
  function testStatus(url:String, status = 200) {
    return fetch(url).map(function(res) return equals(status, res.header.statusCode));
  }
  
  function testData(url:String, method:Method) {
    var body = 'Hello, World!';
    return fetch(url, {
      method: method,
      headers:[
        {name: 'content-type', value: 'text/plain'},
        {name: 'content-length', value: Std.string(body.length)},
      ],
      body: body,
    }).all().next(function(res) return equals(200, res.header.statusCode) && equals(body, res.body.toString().parse().data));
  }
  
  function objectToHeader(obj:Dynamic) {
    return new Header([for(key in Reflect.fields(obj)) new HeaderField(key, Reflect.field(obj, key))]);
  }
  
}