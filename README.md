# MongoJS Live
*Disclaimer: This library is currently a WIP. Issues are expected at this stage, and tests are in the process of being written. In its current form, this can be considered more of a proof of concept than a production stage library. Treat it as such.*

A wrapper for the [mongojs](https://github.com/mafintosh/mongojs) node-module that enables cursor observation, enabling the automatic updating of query results in a meteor-like style.

## Install
```
npm install git+https://github.com/sjaakiejj/mongojs-live.git
```

## Example
```javascript
// Load the required dependencies
var mongojs = require('mongojs');
var mongowrapper = require('mongojs-live');

// Initialize the variables that we need
var collections  = ['log', 'test'];
var databaseName = 'testdatabase'; 

// Load mongodb and extend it
var db = mongojs.connect(databaseName, collections);
mongowrapper.extend(db, collections);

// Now use find and observe the cursor, instead of fetching the results
var cursor = db.log.find({event: "error"});

cursor.observe(function(evt){
  console.log(evt);
});

// This will fire observe, since the query specified in the
// cursor matches the document that is inserted
db.log.insert({event: "error", message: "New error detected!"});

// This one won't fire an event, since it doesn't match the query
db.log.insert({event: "update", message: "New update found!"});

```

## License
The MIT License (MIT)

Copyright (c) 2015 Jacobus Meulen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.