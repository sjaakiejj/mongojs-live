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

#mongohooks = require 'mongohooks'
mongoquery = require 'mongo-json-query'
_ = require 'lodash'
EventEmitter = require('events').EventEmitter

processEvent = (listenQuery, callback) ->
  (error, query, update, options, result) ->
    return if error?
    # Update could be an array or a single entry
    #if update instanceof Array
    #  fullObject = _.map update, (upd) -> _.extend(query, upd)
    #else

    # For now just support single entries
    fullObject = _.extend(query.q || query, update)
    #console.log query.q
    #console.log listenQuery

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
      mongo[collection].hook.on 'insert', processEvent(args[0], callback)
      mongo[collection].hook.on 'update', processEvent(args[0], callback)
      mongo[collection].hook.on 'remove', processEvent(args[0], callback)
      mongo[collection].hook.on 'save',   processEvent(args[0], callback)

    cursor.observeChange = (callback) ->
      callback("Not currently supported")

    return cursor

afterInsertHook = (originalInsert) ->
  (docOrDocs, callback) ->

    # Establish arguments to apply
    args = [docOrDocs,(err,res) =>
      callback(err,res) if callback?
      process.nextTick () =>
        @hook.emit "insert", err, docOrDocs
    ]

    # Apply the updated arguments
    originalInsert.apply(@,args)

afterUpdateHook = (originalUpdate) ->
  (query, update, options, callback) ->
    # Modify if options is the callback
    callback = options if _.isFunction(options)
    options = {} if _.isFunction(options)

    # Establish arguments to apply
    args = [query,update,options,(err,res) =>
      callback(err,res) if callback?
      process.nextTick () =>
        @hook.emit "update", err, query, update, options, res
    ]

    # Apply the updated arguments
    originalUpdate.apply(@, args)


afterRemoveHook = (originalRemove) ->
  (query, justOne, callback) ->
    callback = justOne if _.isFunction(justOne)
    justOne = false if _.isFunction(justOne)

    # Establish arguments to apply
    args = [query,justOne,(err,res) ->
      callback(err,res) if callback?
      process.nextTick () =>
        @hook.emit "remove", err, query, justOne
    ]
    originalRemove.apply(@, arguments)

afterSaveHook = (originalSave) ->
  (doc, callback) ->
    # Establish arguments to apply
    args = [doc,(err,res) ->
      callback(err,res) if callback?
      process.nextTick () =>
        @hook.emit "save", err, doc
    ]

    # Apply the updated arguments
    originalSave.apply(@,args)

module.exports = 
  extend: (mongo, tables) ->
    for collection in tables
      originalFind = mongo[collection].find
      mongo[collection].hook = new EventEmitter()
      mongo[collection].hook.setMaxListeners(0)
      mongo[collection].find = wrappedFind(originalFind, mongo, collection)
      mongo[collection].update = afterUpdateHook(mongo[collection].update)


    return mongo
