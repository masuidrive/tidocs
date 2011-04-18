#!/usr/bin/env python
import os
import urllib
import hashlib
import logging
import datetime
from django.utils import simplejson
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import util
import gdispatch

class Module(db.Model):
    name = db.StringProperty()
    version = db.StringProperty()
    
class Events(db.Model):
    


class Document(db.Model):
    module = db.ReferenceProperty(Module)
    name = db.StringProperty()
    filename = db.StringProperty()
    type = db.StringProperty() # class, method, property, event
    version = db.StringProperty()
    original = db.StringProperty()
    text = db.TextProperty()
    editor = db.TextProperty()
    official = db.BooleanProperty()
    created_at = db.DateTimeProperty(auto_now=True)
    latest = db.BooleanProperty()


gdispatch.route(lambda:('/apidoc/documents/([^/]+)/([^/]+)/([^/]+)', TranslatedHandler))
class TranslatedHandler(webapp.RequestHandler):
    def get(self, version, module, name):
        query = db.Query(document)
        query.filter('module =', module)
        query.filter('name =', name)
        query.filter('version =', version)
        query.order('-created_at')
        doc = Document.
