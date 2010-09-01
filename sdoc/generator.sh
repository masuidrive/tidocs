#!/bin/sh

curl http://developer.appcelerator.com/apidoc/mobile/1.4/api.json -o - | ruby ./generator.rb 
scp -r doc/* www:/www/domains/tidocs.com/public_html/mobile/latest/

