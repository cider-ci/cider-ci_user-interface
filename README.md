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

