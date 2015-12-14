var frisby = require('frisby');

// Testing Function

function testRegistrationMe (rme) {
	expect(rme.icon.oid).toEqual(jasmine.any(Number));
	expect(rme.icon.size).toEqual(jasmine.any(Number));
	expect(rme.icon.path).toEqual(jasmine.any(String));
	expect(rme.icon.description).toEqual(jasmine.any(String));
	expect(rme.icon.title).toEqual(jasmine.any(String));
	expect(rme.icon.name).toEqual(jasmine.any(String));
	expect(rme.icon.mime_type).toEqual(jasmine.any(String));
	expect(rme.icon.class).toEqual(jasmine.any(String));
	expect(rme.documents).toEqual(jasmine.any(Number));
	expect(rme.oid).toEqual(jasmine.any(Number));
	expect(rme.vsession).toEqual(jasmine.any(String));
	expect(rme.id).toEqual(jasmine.any(String));
	expect(rme.path).toEqual(jasmine.any(String));
	expect(rme.fullname).toEqual(jasmine.any(String));
	expect(rme.description).toEqual(jasmine.any(String));
	expect(rme.name).toEqual(jasmine.any(String));
	expect(rme.links).toEqual(jasmine.any(Number));
	expect(rme.class).toEqual(jasmine.any(String));
}

function testRegistrationError (rer) {
	expect(rer).toEqual(jasmine.any(String));
}

function testRegistrationVersion (rvr) {
	expect(rvr[0]).toEqual(jasmine.any(String));
	expect(rvr[1]).toEqual(jasmine.any(String));
}

function testRegistrationDate (rd) {
	expect(rd).toEqual(jasmine.any(String));
}

// Running the test

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
		"me": testRegistrationMe,
		"error": testRegistrationError,
		"__version": testRegistrationVersion,
		"__date": testRegistrationDate
	})
	.toss();