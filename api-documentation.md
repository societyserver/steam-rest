# REST API for the community calender

All requests to the API begin with `http://dev-back1.techgrind.asia/scripts/rest.pike`. Each response has `debug`, `me`, and other objects with meta details, and then the actual response.


## Meta 

### Debug

The debug method is a part of every response from the API. It looks like:

```json
"debug":{  
  "count":4, // Integer, number of items in main response array
  "request":{  
     "request":"URL you made the request to",
     "interface":"public",
     "referer":"none",
     "auth":"http",
     "type":"content",
     "__internal":{  
        "request_method":"GET",
        "client":[  
           "Mozilla"
        ],
        "request_headers":{  
           "connection":"close",
           "x-forwarded-server":"dev-back1.techgrind.asia",
           "x-forwarded-for":"59.176.40.4",
           "if-none-match":"\"07aa5ede6329b54e0c76d6acfeb20bb5;gzip\"",
           "if-modified-since":"Fri, 02 Jan 2015 11:48:31 GMT",
           "proxy-software":"Roxen/5.4.66-r1",
           "user-agent":"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.45 Safari/537.36",
           "accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
           "accept-encoding":"gzip, deflate, sdch",
           "host":"dev-back1.techgrind.asia:81",
           "x-forwarded-host":"dev-back1.techgrind.asia",
           "cache-control":"max-age=0",
           "dnt":"1",
           "accept-language":"en-GB,en-US;q=0.8,en;q=0.6"
        }
     },
     "host":"dev-back1.techgrind.asia"
  },
  "type-handler":[  
     "GET",
     "event-list", // The name of the array which has useful information
     "techgrind.events(#3393,/classes/Group,65)",
     [  
        // Additional parameter supplied to the call
     ]
  ]
}
```

### Me

Gives information about the user requesting data from the API. Default response shown below:

```json
"me":{  
  "name":"guest",
  "documents":0,
  "id":"guest",
  "path":"/home/guest",
  "description":"Guest is the guest user.",
  "vsession":"0",
  "class":"User",
  "oid":88,
  "links":0,
  "icon":{  
     "name":"user_unknown.jpg",
     "mime_type":"image/jpeg",
     "title":"",
     "size":778,
     "path":"/images/doctypes/user_unknown.jpg",
     "description":"",
     "class":"Document",
     "oid":159
  },
  "fullname":"User 1"
}
```

## Techgrind Events

URL: `?request=techgrind.events`
Data in: `event-list`.

`event-list` is an array of object, each having:

Key | Description
--- | ---
class | String. Class to which it belongs, example "Group".
title | String. Title of event, example "curated events".
oid | Integer. Unique ID, 4 digit.
name | String. Name of the event.
id | String. In the form of techgrind.events.{{ name }}
description | String. A short description.
category | String. Example, "event" or "conference"
path | String. In the form of /home/{{ id }}
eventid | String. Usually equal to {{ id }}
type | event
place | String. Example "Singapore"
keywords | An array of keywords related to the event, like "linux" or "free-software"
schedule | An array of objects with information about the schedule of an event (see below)

The schedule is an array of objects used to specify times and location of an upcoming event.

Key | Description
--- | ---
type | event
name | String. Name of the event.
id | String. In the form of {{ parent id }}.{{ name }}
title | String.
address | String. Street address of location.
country | String. Example "china".
path | String. In the form of /home/{{ id }}
time | String. Time in 24 hours format, HH:MM
date | String. Based on milliseconds since Jan 1
city | String. City, example "beijing"
class | String. Group
oid | Integer. 4 digit unique ID.