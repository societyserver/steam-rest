var frisby = require('frisby');

//
// Generic testing functions
//

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

  if ( e.schedule ) {
    e.schedule.forEach(function(schedule) {
      expect( schedule.type ).toEqual( jasmine.any(String) );
      expect( schedule.name ).toEqual( jasmine.any(String) );
      expect( schedule.title ).toEqual( jasmine.any(String) );
      expect( schedule.id ).toEqual( jasmine.any(String) );
      expect( schedule.path ).toEqual( jasmine.any(String) );
      expect( schedule['class'] ).toEqual( jasmine.any(String) );
      expect( schedule.oid ).toEqual( jasmine.any(Number) );

      toBeStringIfExists( schedule.address )

      toBeDateIfExists( schedule.date );
    });
  }
  
  if ( e.keywords ) {
    e.keywords.forEach(function(word) {
      expect( word ).toEqual( jasmine.any(String) );
    })
  };
}

function testRegistrationVersion (rvr) {
  expect(rvr[0]).toEqual(jasmine.any(String));
  expect(rvr[1]).toEqual(jasmine.any(String));
}

function testRegistrationDate (rd) {
  expect(rd).toEqual(jasmine.any(String));
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
    "request": "techgrind.events.blug-coding-for-fun",
    "request-method": "GET",
    "me": testMe,
    "event": testEvent
  })
  .toss();


// Registration Tests


frisby.create('Testing Registration API calls')
  .post('http://dev-back1.techgrind.asia/scripts/rest.pike?request=register', {
    email: "gcitester@tester.com",
    fullname: "test user tg gci",
    group: "techgrind",
    password: "abcxyz",
    password2: "abcdxyz",
    userid: "test.user.gci"
  }, {json: true})
  .expectStatus(200)
  .expectJSON({
    "request-method": "POST",
    "request": "register",
    "me": testMe,
    "__version": testRegistrationVersion,
    "__date": testRegistrationDate
  })
  .inspectJSON()
  .toss();
