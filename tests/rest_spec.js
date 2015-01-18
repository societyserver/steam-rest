var frisby = require('frisby');

function testDebug (d) {
  expect(d.count).toEqual(jasmine.any(Number));
  expect(d.request.request).toEqual(jasmine.any(String));
  expect(d.request['interface']).toEqual(jasmine.any(String));
  expect(d.request.referer).toEqual(jasmine.any(String));
  expect(d.request.auth).toEqual(jasmine.any(String));
  expect(d.request.type).toEqual(jasmine.any(String));
  expect(d.request['__internal']).toBeDefined();
  expect(d.request.host).toEqual(jasmine.any(String));
  expect(d['type-handler']).toBeDefined();
}

function testMe (me) {
  expect(me.name).toEqual(jasmine.any(String));
  expect(me.documents).toEqual(jasmine.any(Number));
  expect(me.id).toEqual(jasmine.any(String));
  expect(me.path).toEqual(jasmine.any(String));
  expect(me.description).toEqual(jasmine.any(String));
  expect(me.vsession).toEqual(jasmine.any(String));
  expect(me['class']).toEqual(jasmine.any(String));
  expect(me.oid).toEqual(jasmine.any(Number));
  expect(me.links).toEqual(jasmine.any(Number));
  expect(me.icon).toBeDefined();
  expect(me.fullname).toEqual(jasmine.any(String));
}

function toBeStringIfExists(val) {
  if ( val ) 
    expect(val).toEqual(jasmine.any(String));
}
function toBeObjectIfExists(val) {
  if ( val ) 
    expect(val).toEqual(jasmine.any(Object));
}

frisby.create('Test events')
  .get('http://dev-back1.techgrind.asia/scripts/rest.pike?request=techgrind.events')
  .expectStatus(200)
  .expectJSON({
    "request": "techgrind.events",
    "request-method": "GET",
    "debug": testDebug,
    "me": testMe,
  })
  .expectJSONTypes('event-list.*', {
    "class": String,
    "title": String,
    "oid": Number,
    "name": String,
    "id": String,
    "description": toBeStringIfExists,
    "category": toBeStringIfExists,
    "path": String,
    "eventid": toBeStringIfExists,
    "type": String,
    "owner": toBeStringIfExists,
    "events": toBeObjectIfExists,
    "keywords": function(kw) {
      if ( kw ) {
        kw.forEach(function(word) {
          expect(word).toEqual(jasmine.any(String));
        })
      }
    }
  })
  .toss();


/*
{  
  "class":"Group",
  "title":"curated events",
  "oid":3977,
  "name":"gap",
  "id":"techgrind.events.gap",
  "description":"Find your cofounders - partners - and hires!",
  "category":"event",
  "path":"/home/techgrind.events.gap",
  "eventid":"techgrind.events.gap",
  "type":"event"
},
*/