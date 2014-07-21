# start it with:
# $ forever --watch --watchIgnore='tmp/**' --watchIgnore='log/**' -c sh start.sh
# (but first: $ npm i -g forever)

export RAILS_RELATIVE_URL_ROOT='/cider-ci'
bundle exec rails s -p 8880