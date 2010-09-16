from google.appengine.ext import webapp
from google.appengine.api import urlfetch
from google.appengine.api import memcache
from google.appengine.ext.webapp import util
from django.utils import simplejson

def db_retry(func):
    count = 0
    while count < 3:
        try:
            return func()
        except:
            count += 1
        else:
            raise datastore._ToDatastoreError()

class Comment(db.Model):
    target = db.StringProperty()
    content = db.StringProperty(multiline=True)
    date = db.DateTimeProperty(auto_now=True)
    author = db.StringProperty()
    visible = db.BooleanProperty()
    blocked = db.BooleanProperty()
    deleted = db.BooleanProperty()

class Comments(webapp.RequestHandler):
    def get(self):
        self.response.out.write();

