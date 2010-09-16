#!/usr/bin/env python
from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
import feed
import comment

def main():
    application = webapp.WSGIApplication([
            ('/qa_feed', feed.FetchQAFeedHandler),
            ('/devblog_feed', feed.FetchDevBlogFeedHandler)
            ('/comments', comment.Comments)
            ], debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
