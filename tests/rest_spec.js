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

frisby.create('Test events')
  .get('http://dev-back1.techgrind.asia/scripts/rest.pike?request=techgrind.events')
  .expectStatus(200)
  .expectJSON({
    "request": "techgrind.events",
    "debug": testDebug,
    "me": testMe
  })
  .toss();
