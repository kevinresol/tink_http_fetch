package ;

import haxe.io.Bytes;
import haxe.Json;
import tink.unit.TestRunner;
import tink.unit.Assert.*;
import tink.http.Fetch.*;
import tink.http.Response;

using tink.CoreApi;

class RunTests {

  static function main() {
    
    TestRunner.run([
      new RunTests()
    ]).handle(function(result) travix.Logger.exit(result.errors));
    
  }
  
  public function new() {}
  
  public function testGet() {
    return fetch('http://example.com/').map(function(res) return equals(200, res.header.statusCode));
  }
  
  public function testSecureGet() {
    return fetch('https://example.com/').map(function(res) return equals(200, res.header.statusCode));
  }
  
  public function testHeaders() {
    var name = 'my-sample-header';
    var value = 'foobar';
    return fetch('https://postman-echo.com/headers', {
      headers:[{name: name, value: value}],
    }) >> 
      function(res:IncomingResponse) return res.body.all() >>
      function(bytes:Bytes) return equals(200, res.header.statusCode) && equals(value, Reflect.field(Json.parse(bytes.toString()).headers, name));
  }
  
  public function testSecurePost() {
    var body = 'Hello, World!';
    return fetch('https://postman-echo.com/post', {
      method: POST,
      headers:[{name: 'content-type', value: 'text/plain'}],
      body: body,
    }) >> 
      function(res:IncomingResponse) return res.body.all() >>
      function(bytes:Bytes) return equals(200, res.header.statusCode) && equals(body, Json.parse(bytes.toString()).data);
  }
  
}