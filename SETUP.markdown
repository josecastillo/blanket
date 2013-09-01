Setup Instructions
==================

Blanket comes in two parts. The client-side component is an iOS app, and the server side component is a simple Flask app written in Python. 

Blanket Client
--------------

The blanket client requires [cocoapods](http://cocoapods.org). Assuming you have cocoapods installed, cd to the ```blanket-ios``` directory and execute the following commands: 

    pod install
    open blanket.xcworkspace

From here you should be able to run the project immediately and connect to the blanket test server at ```blanket.herokuapp.com```. If you wish to connect to a different server (on your local machine or that you have set up remotely), open ```SBWebServiceClient.m``` and edit the ```protocol``` and ```host``` values at the top of the class definition. 

Blanket Server
--------------

The blanket server requires a PostgreSQL database; for simple evaluation purposes you can use Postgres.app to set up a local server, but you could just as easily deploy the project to Heroku. These instructions assume you want to test in the iPhone Simulator, have Postgres.app running, and a local database called 'blanket'. 

To set up the blanket server, cd to the ```blanket-server``` directory and execute the following commands: 

    virtualenv venv --distribute
    source venv/bin/activate
    pip install -r requirements.txt
    DATABASE_URL=postgres://localhost/blanket python create_tables.py
    DATABASE_URL=postgres://localhost/blanket python blankets.py

You now have a blanket server running on your local machine. 
