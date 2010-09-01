from google.appengine.ext import webapp
from google.appengine.api import urlfetch
from google.appengine.api import memcache
from google.appengine.ext.webapp import util
from django.utils import simplejson
import feedparser

def feed2json(url, callback, cache=None):
    if cache:
        data = memcache.get(cache)
    else:
        data = None
    
    if data is None:
        feedinput = urlfetch.fetch(url)
        d = feedparser.parse(feedinput.content)
        contents = []
        for entry in d.entries[:5]:
            contents.append({"link": entry.link, "title":entry.title})
        data = callback+"("+simplejson.dumps(contents)+")"
        if cache:
            memcache.set(cache, data, 60 * 60)
    return data

class FetchQAFeedHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write(feed2json("http://developer.appcelerator.com/feed/questions/created", "qa_feed_json", "qa_feed_json"))

class FetchDevBlogFeedHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write(feed2json("http://developer.appcelerator.com/blog/feed", "devblog_json", "devblog_json"))
