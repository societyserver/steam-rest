var frisby = require('frisby');
var restTest = require('./rest_spec.js');

// Testing Functions

function testRegistrationVersion (rvr) {
  expect(rvr[0]).toEqual(jasmine.any(String));
  expect(rvr[1]).toEqual(jasmine.any(String));
}

function testRegistrationDate (rd) {
  expect(rd).toEqual(jasmine.any(String));
}

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
    "me": restTest.testMe,
    "__version": testRegistrationVersion,
    "__date": testRegistrationDate
  })
  .toss();
