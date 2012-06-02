#!/bin/sh

curl http://docs.appcelerator.com/titanium/data/2.0.2/api.json -o - | ruby ./generator.rb 
scp -r doc/* www:/www/domains/tidocs.com/public_html/mobile/latest/

