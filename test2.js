var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);
var tests = require('mongodb').MongoClient;
var assert = require('assert');
// var tests = require('./tests')
var url = "mongodb://bbw_admin:blueberrywall@ds051553.mongolab.com:51553/bbw_dev1"
var users = {};
var sockets = {};
var msgg = '';
var wallid = '';
var wall = {};
var sockets = {};
io.sockets.on('connection', function(socket) {
    console.log("connection sucess");


    /* --------------- don,t have a wall sign in part--------------------------------------- */
    socket.on('signin', function(usr, pass) {
            console.log(usr, pass);

            tests.collection('mycollection').find({
                name: usr,
                password: pass
            }).toArray(function(err, res) {
                wallid = res[0].wall_id;
                console.log(wallid);
                console.log(socket.id);

                msgg = res.length;
                if (!msgg == '0') {
                    var response = {
                        status: "1",
                        wall: wallid
                    };
                    socket.emit('sigin', response);
                    /* ------------- finding the links from aws server for signin -----------*/
                    tests.collection('imagecollection').find({
                        wall_id: wallid
                    }).toArray(function(err, res) {
                        var response = {
                            im_1: res[0].img_1,
                            im_2: res[0].img_2,
                            im_3: res[0].img_3,
                            im_4: res[0].img_4,
                            im_5: res[0].img_5,
                            im_6: res[0].img_6,
                            im_7: res[0].img_7,
                            im_8: res[0].img_8,
                            im_9: res[0].img_9
                        };
                        socket.emit('img_links', response);

                    });
                    /* ------------ finding links for signin ends ------------------------*/
                } else {
                    var response = {
                        status: "0"
                    };
                    socket.emit('sigin', response);
                }
            });
        })
        /* --------------------- i have a wall part registering wall with wallid ----------------------*/
    socket.on('register', function(wallid) {
            console.log(wallid);
            /* ------------- finding the links from aws server for register -----------*/
            tests.collection('imagecollection').find({
                wall_id: wallid
            }).toArray(function(err, res) {

                var response = {
                    im_1: res[0].img_1,
                    im_2: res[0].img_2,
                    im_3: res[0].img_3,
                    im_4: res[0].img_4,
                    im_5: res[0].img_5,
                    im_6: res[0].img_6,
                    im_7: res[0].img_7,
                    im_8: res[0].img_8,
                    im_9: res[0].img_9
                };
                socket.emit('reg_links', response);

            });
            /* ------------ finding links for register ends ------------------------*/
        })
        /* -------------------- register part ends-------------------------------------------------*/
        /*------------- Getting wall values ----------------------------*/
    socket.on('wallpressid', function(wallid) {
            console.log(wallid);
            var msg = {
                msgs: wallid
            };
            socket.broadcast.emit('val', msg);

        })
        /*------------ Getting wall values ends--------------------*/

    /*------------ Getting wall from mobile wall --------------*/
    socket.on('mobwallid', function(mobid) {
            console.log(mobid);
            var msg = {
                status: "1"
            };
            socket.broadcast.emit('stats', msg);

        })
        /*------------- Getting from mobile ends------------------*/
});
tests.connect(url, function(err, db) {
    assert.equal(null, err);
    tests = db;
});
http.listen(4000);