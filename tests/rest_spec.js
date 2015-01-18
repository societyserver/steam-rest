var frisby = require('frisby');

//
// Generic testing functions
//
function testDebug (d) {
  expect( d.count ).toEqual( jasmine.any(Number) );
  expect( d.request.request ).toEqual( jasmine.any(String) );
  expect( d.request['interface'] ).toEqual( jasmine.any(String) );
  expect( d.request.referer ).toEqual( jasmine.any(String) );
  expect( d.request.auth ).toEqual( jasmine.any(String) );
  expect( d.request.type ).toEqual( jasmine.any(String) );
  expect( d.request['__internal'] ).toBeDefined();
  expect( d.request.host ).toEqual( jasmine.any(String) );
  expect( d['type-handler'] ).toBeDefined();
}

function testMe (me) {
  expect( me.name ).toEqual( jasmine.any(String) );
  expect( me.documents ).toEqual( jasmine.any(Number) );
  expect( me.id ).toEqual( jasmine.any(String) );
  expect( me.path ).toEqual( jasmine.any(String) );
  expect( me.description ).toEqual( jasmine.any(String) );
  expect( me.vsession ).toEqual( jasmine.any(String) );
  expect( me['class'] ).toEqual( jasmine.any(String) );
  expect( me.oid ).toEqual( jasmine.any(Number) );
  expect( me.links ).toEqual( jasmine.any(Number) );
  expect( me.icon ).toBeDefined();
  expect( me.fullname ).toEqual( jasmine.any(String) );
}

function testEvent(e) {
  expect(e['class']).toEqual( jasmine.any(String) );
  expect(e.title).toEqual( jasmine.any(String) );
  expect(e.name).toEqual( jasmine.any(String) );
  expect(e.id).toEqual( jasmine.any(String) );
  expect(e.path).toEqual( jasmine.any(String) );
  expect(e.type).toEqual( jasmine.any(String) );

  expect(e.oid).toEqual( jasmine.any(Number) );

  toBeStringIfExists( e.description );
  toBeStringIfExists( e.eventid );
  toBeStringIfExists( e.category );
  toBeStringIfExists( e.owner );
  toBeStringIfExists( e.address );
  toBeStringIfExists( e.city );
  toBeStringIfExists( e['time'] );

  toBeDateIfExists( e.date );

  toBeObjectIfExists( e.events );
  toBeObjectIfExists( e.schedule );
  
  if ( e.keywords ) {
    e.keywords.forEach(function(word) {
      expect( word ).toEqual( jasmine.any(String) );
    })
  };
}


//
// Useful helpers
//
function toBeStringIfExists(val) {
  if ( val ) 
    expect( val ).toEqual( jasmine.any(String) );
}
function toBeObjectIfExists(val) {
  if ( val ) 
    expect( val ).toEqual( jasmine.any(Object) );
}
function toBeDateIfExists (val) {
  if ( val ) {
    var date = new Date(val);
    expect( date ).toEqual( jasmine.any(Object) );
  }
}


//
// Actual Tests
//
frisby.create('Test techgrind.events to be well-formed')
  .get('http://dev-back1.techgrind.asia/scripts/rest.pike?request=techgrind.events')
  .expectStatus(200)
  .expectJSON({
    "request": "techgrind.events",
    "request-method": "GET",
    "debug": testDebug,
    "me": testMe,
    "event-list": function(val) { 
      val.forEach(function(e) {
        testEvent(e);
      });
    }
  })
  .toss();


frisby.create('Test techgrind.events/order-by-date to be well-formed')
  .get('http://dev-back1.techgrind.asia/scripts/rest.pike?request=techgrind.events/order-by-date')
  .expectStatus(200)
  .expectJSON({
    "request": "techgrind.events/order-by-date",
    "request-method": "GET",
    "debug": testDebug,
    "me": testMe,
    "event-list": function(val) { 
      val.forEach(function(e) {
        testEvent(e);
      });
    }
  })
  .toss();


frisby.create('Testing an instance of an event to be well-formed')
  .get('http://dev-back1.techgrind.asia/scripts/rest.pike?request=techgrind.events.blug-coding-for-fun')
  .expectStatus(200)
  .expectJSON({
    "request": "techgrind.events/order-by-date",
    "request-method": "GET",
    "debug": testDebug,
    "me": testMe,
    "event": testEvent
    }
  })
  .toss();