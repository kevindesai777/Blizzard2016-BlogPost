import json
import tweepy
import configparser
from HTMLParser import HTMLParser

class TweeterStreamListener(tweepy.StreamListener):
    def __init__(self, api):
        self.api = api
        super(tweepy.StreamListener, self).__init__()
    

    def on_status(self, status):
        if status.place:
            
            st = status.place.full_name + ': ' + str(status.created_at) + '\n'
            print st
            with open("places.txt", "a") as myfile:
                myfile.write(st)
            #f = open('places.txt','a')
            #f.write(status.place.full_name + ', ' + str(status.created_at) + '\n')
            #f.close()
        return True

    def on_error(self, status_code):
        print("Error")
        return True # Don't kill the stream

    def on_timeout(self):
        return True # Don't kill the stream

if __name__ == '__main__':

    # Read the credententials from 'twitter.txt' file
    config = configparser.ConfigParser()
    config.read('twitter.txt')
    consumer_key = config['DEFAULT']['consumerKey']
    consumer_secret = config['DEFAULT']['consumerSecret']
    access_key = config['DEFAULT']['accessToken']
    access_secret = config['DEFAULT']['accessTokenSecret']


    # Create Auth object
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_key, access_secret)
    api = tweepy.API(auth)
    places_time = []
    #f = open('places.txt','w')
    #f.write('Hello\n')
    # Create stream and bind the listener to it
    stream = tweepy.Stream(auth, listener = TweeterStreamListener(api))

    #Custom Filter rules pull all traffic for those filters in real time.
    stream.filter(track = ['stormjonas', 'blizzard2016', 'jonas', 'blizzard', 'snowzilla'], languages = ['en'])
    #stream.filter(locations=[-180,-90,180,90], languages = ['en'])
