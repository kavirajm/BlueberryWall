import datetime
import time
import re
import requests
from twisted.internet.protocol import Factory, Protocol
from twisted.internet import reactor
import ssl
import json
import socket
import struct
import binascii
import threading
from pymongo import MongoClient
import settings
from bson.objectid import ObjectId



class TimerThread(threading.Thread):

    def run(self):
        while not self.event.is_set():
            self.event.wait(settings.wait_time_msec)
            print "in timer"

        self.stop()

    def stop(self):
        self.event.set()
        return "y"

        
class Mustino(Protocol):

    def connectionMade(self):
        self.pairs = []
        self.userId = ""
        self.pairId = ""
        self.status = settings.INACTIVE
        self.pairs.append(self)
        self.factory.clients.append(self)
        print "Connected clients are ", self.factory.clients



    def connectionLost(self, reason):
        self.factory.clients.remove(self)
        client = MongoClient(settings.MONGOURI)
        db = client["bbw_dev1"]
        bbw_main = db["bbw_main"]
        save_status = settings.PAIRED if self.status == settings.CONNECT else self.status
        if save_status!=settings.INACTIVE:
            db.bbw_main.update({"userId":self.userId},{"$set":{"status":save_status}}) 
        print "status saved and client removed"  


    def dataReceived(self, data):
        a = data.split(':')
        print data
        if a[0]=="on":
            print "hi"

        elif a[0] == "register":
            print "register"
            self.userId = a[1].rstrip()
            client = MongoClient(settings.MONGOURI)
            db = client["bbw_dev1"]
            bbw_main = db["bbw_main"]
            db.bbw_main.insert({"userId":a[1].rstrip(),"pairId":"","status":settings.REGISTERED})
            self.status = 1
            self.message("registered")

        elif a[0] == "pair":
            print "pair"
            self.pairId =  a[1].rstrip()
            client = MongoClient(settings.MONGOURI)
            db = client["bbw_dev1"]
            bbw_main = db["bbw_main"]
            db.bbw_main.update({"userId":self.userId},{"$set":{"status":settings.PAIRED,"pairId":a[1].rstrip()}})
            self.status = 2
            self.message("paired")

        # elif a[0] == "connect":
        #     print "connect"
        #     connection = pymongo.Connection(settings.MONGOURI)
        #     db = connection["mustino_dev1"]
        #     users = db["users"]
        #     cursor = db.users.find_one({"userId":a[1].rstrip()},{"pairId":1,"status":settings.REGISTERED,"_id":0})
        #     # print "user info -->", a[1].rstrip(),cursor["pairId"] if "pairId" in cursor else 0,cursor["status"] if "status" in cursor else 0
        #     if cursor is not None:
        #         self.status = cursor["status"] if "status" in cursor else 0
        #         self.userId = a[1].rstrip()
        #         self.pairId = cursor["pairId"] if "pairId" in cursor else 0

        #     if (self.status == settings.INACTIVE): 
        #         self.message("inactive")
        #     elif (self.status == settings.REGISTERED):
        #         self.message("registered")
        #     elif (self.status == settings.PAIRED):
        #         for c in self.factory.clients:
        #             if self.pairId == c.userId :
        #                 self.pairs.append(c)
        #                 self.status = settings.CONNECT
        #                 connection = pymongo.Connection(settings.MONGOURI)
        #                 db = connection["mustino_dev1"]
        #                 users = db["users"]
        #                 db.users.update({"userId":self.userId},{"$set":{"status":settings.CONNECT}})
        #                 if (len(c.pairs)==1):
        #                     c.pairs.append(self)
        #                     c.pairId = self.userId
        #                     c.status = settings.CONNECT
        #                     connection = pymongo.Connection(settings.MONGOURI)
        #                     db = connection["mustino_dev1"]
        #                     users = db["users"]
        #                     db.users.update({"userId":c.userId},{"$set":{"status":3,"pairId":self.userId}})
        #                     c.message("connected")
        #                 self.message("connected")
        #     elif (self.status == settings.CONNECT):
        #         print "Already Connected"

        elif a[0] == "mustino_t":
            
            for c in self.pairs:
                if c != self:
                    print self.userId,"RX Mustino_t to", c.userId
                    c.message(a[1].replace("<","").replace(">","").replace(" ",""))

        elif a[0] == "status":
            print "status-->",self.status
            print "userId-->",self.userId
            print "pairId-->",self.pairId
            print "pairs -->",self.pairs
            

        else:
            print "nothing to see", data


    def message(self, message):
        print "sending msg.."+message
        self.transport.write(message + '\n')


factory = Factory()
factory.clients = []
factory.protocol = Mustino
reactor.listenTCP(settings.PORT, factory)
print "BBW server started at ",settings.PORT
reactor.run()
