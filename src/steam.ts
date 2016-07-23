import {autoinject} from 'aurelia-framework';
import {HttpClient} from 'aurelia-fetch-client';

@autoinject
export class Steam {
  heading: string = 'sTeam service';

  constructor(private http: HttpClient) {
    http.configure(config => {
      config
        .useStandardConfiguration()
        .withBaseUrl('http://steam.realss.com/scripts/rest.pike?request=/home/');
    });
  }

  get(request) {
    return this.http.fetch(request)
      .then(response => response.json())
      .then(data => data);
  }
}
