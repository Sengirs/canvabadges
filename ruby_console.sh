#!/bin/sh
export RACK_ENV=production
bundle exec irb -r ./canvabadges.rb
