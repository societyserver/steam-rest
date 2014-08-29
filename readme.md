step 1: install node

    http://nodejs.org/download/



step 2: clone the repo

    git clone https://github.com/societyserver/steam-rest


step 3: install node packages:

    npm install

this installs all dependencies (including coffee) for our project into  the project's node_modules directory based on the 'package.json' file


step 4: start the server

    node_modules/.bin/coffee scripts/server.coffee


but for convenience we can install coffee in the global node environment:

    npm install -g coffee-script


so we can just say

    coffee scripts/server.coffee

if the server is working you'll see:

    Listening on port 8000
