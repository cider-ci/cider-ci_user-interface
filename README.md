Cider-CI Server-TB
==================

Part of [Cider-CI](https://github.com/DrTom/cider-ci). 
This component runs in the application server under the 
[TorqueBox](http://torquebox.org/) stack.


## Developing the frontend only

It is possible to run this part of Cider-CI in development mode without
connecting it to the other Cider-CI services. It is also possible to use MRI
ruby (instead of JRuby) in development mode. 

    RAILS_RELATIVE_URL_ROOT=/cider-ci-dev rails s -p 8888


### Messaging 

The application will try to open a connection to the configured message broker.
It will continue when in `development` or `test` environment with a warning
(to the console and log) if the connection could not be established.

Message consumers are bound if and only if `MESSAGING_BIND_CONSUMERS` is
set and not blank! It is advisable to bind the consumers in a second
process during development, e.g.

    MESSAGING_BIND_CONSUMERS=true rails c


## License

Copyright (C) 2013, 2014 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
Licensed under the terms of the GNU Affero General Public License v3.
See the LICENSE.txt file provided with this software.

