Cider-CI User-Interface 
=======================

Part of [Cider-CI](https://github.com/cider-ci/cider-ci). This in ruby on rails
implemented component serves all of the user interface. This component also
includes code which builds executions and does a few other things. 


## Developing the frontend only

It is possible to run this part of Cider-CI in development mode without
connecting it to the other Cider-CI services. It is also possible to use MRI
ruby (instead of JRuby) in development mode. 

    RAILS_RELATIVE_URL_ROOT=/cider-ci/ui rails s -p 8880

### Quick Setup 

```sh
git clone https://github.com/cider-ci/cider-ci_user-interface cider-ui
cd cider-ui
cp config/database_dev.yml config/database.yml
cp config/secrets_dev.yml config/secrets.yml 
```

### CSS Dev

When working on CSS only, it's possible to preview your local styles on any 
running instance. For convienience, a bookmarklet it recommended:

```js
// plain:
$('head link[rel="stylesheet"]').attr("href", "http://localhost:8880/cider-ci/ui/assets/application.css")
```

[Bookmarklet](javascript:(function(){%24('head%20link%5Brel%3D%22stylesheet%22%5D').attr(%22href%22%2C%22http%3A%2F%2Flocalhost%3A8880%2Fcider-ci%2Fui%2Fassets%2Fapplication.css%3F%22%2BDate.now())%3B})();)


### Messaging 

The application will try to open a connection to the configured message broker.
It will continue when in `development` or `test` environment with a warning (to
the console and log) if the connection could not be established. 


### Code Status

[![Code Climate](https://codeclimate.com/github/cider-ci/cider-ci_user-interface/badges/gpa.svg)](https://codeclimate.com/github/cider-ci/cider-ci_user-interface)


## License

Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
Licensed under the terms of the GNU Affero General Public License v3.
See the LICENSE.txt file provided with this software.
