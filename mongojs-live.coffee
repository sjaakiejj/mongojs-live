# The MIT License (MIT)

# Copyright (c) 2015 Jacobus Meulen

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

mongohooks = require 'mongohooks'
mongoquery = require 'mongo-json-query'
_ = require 'lodash'

processEvent = (listenQuery, callback) ->
  (error, result, query, update) ->
    return if error?
    # Update could be an array or a single entry
    #if update instanceof Array
    #  fullObject = _.map update, (upd) -> _.extend(query, upd)
    #else

    # For now just support single entries
    fullObject = _.extend(query, update)

    # Match the object
    mongoquery.match(fullObject, listenQuery, (matches) ->
      callback(
        result: result
        query: query
        update: update
      ) if matches and callback?
    )


# These are the supplementary functions provided by this module
wrappedFind = (find, mongo, collection) ->
  () ->
    args = arguments
    cursor = find.apply(@, arguments)
    cursor.observe = (callback) ->
      mongohooks(mongo[collection]).on 'insert', processEvent(args[0], callback)
      mongohooks(mongo[collection]).on 'update', processEvent(args[0], callback)
      mongohooks(mongo[collection]).on 'remove', processEvent(args[0], callback)
      mongohooks(mongo[collection]).on 'save',   processEvent(args[0], callback)

    cursor.observeChange = (callback) ->
      callback("Not currently supported")

    return cursor

module.exports = 
  extend: (mongo, tables) ->
    for collection in tables
      originalFind = mongo[collection].find
      mongo[collection].find = wrappedFind(originalFind, mongo, collection)
    return mongo
