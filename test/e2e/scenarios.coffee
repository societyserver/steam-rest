angular.scenario.dsl 'expectClass', -> (klass, selector, label) ->
	expect(element(selector, label).prop('classList')).toContain klass

angular.scenario.dsl 'expectViewText', -> (text, selector, label) ->
	expect(element("[ng-view] "+ (selector || ''), label).text()).toMatch text

describe 'Tech Grind app', ->
	describe 'root page', ->
		beforeEach -> browser().navigateTo '/'
		it 'shows the home page', -> expect(browser().location().url()).toBe "/home"

	describe 'register and activate', ->
		beforeEach -> browser().navigateTo '#/register'
		it 'registration successful', ->
			input('registerdata.fullname').enter('test user tg ')
			input('registerdata.email').enter('martin@ekita.co')
			input('registerdata.password').enter('abc123')
			input('registerdata.password2').enter('abc123')
			element('#registerhere').click()
			expect(element('#newuserid').text()).toContain 'test.user.tg'
			element('#activation_link').click()
			expect(element('#activation').text()).toContain 'user is activated'

	describe 'home page', ->
		beforeEach -> browser().navigateTo '#/home'
		it 'shows Top happenings', -> expectViewText "Top Happenings"
		it 'shows Latest Content', -> expectViewText "Latest Content"
		it 'highlights the home menu and only that', ->
			expectClass 'active', '#menu #home'
			expect(element('#menu [class="active"]').count()).toBe 1

	describe 'regions', ->
		beforeEach -> browser().navigateTo '#/regions'

	describe 'a specific regions', ->
		beforeEach -> browser().navigateTo '#/regions/thailand'

	describe 'calendar', ->
	describe 'events', ->
	describe 'resources', ->
	describe 'media', ->
	describe 'partners', ->
		xit 'shows Global Partners'
		xit 'has Connect With Us form'
