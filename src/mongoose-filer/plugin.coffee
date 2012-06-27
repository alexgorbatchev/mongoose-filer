async = require 'async'
mongoose = require 'mongoose'
_ = require 'underscore'
AttachedFile = require './attached_file'

Attachments = new mongoose.Schema
  name: type: String, required: true
  fileName: String
  contentType: String
  createdAt: type: Date, default: Date.now
, strict: true

Attachments.virtual('file')
  .get ->
    @_file
  .set (value) ->
    @_file = value

Attachments.virtual('config').get ->
  @parent.schema.attachments[@name]

Attachments.virtual('attachedFile').get ->
  @_attachedFile ?=  new AttachedFile @parent.id,
    modelName: @parent.constructor.modelName
    attributeName: @name
    fileName: @fileName
    styles: @config.styles
    file:
      name: @fileName
      type: @contentType
      path: @file

Attachments.path('contentType').validate (v) ->
  contentTypes = @parent?.schema.attachments[@name].contentType
  return !contentTypes? or (v in contentTypes)
, "acceptable content type"

Attachments.method
  url: (style) ->
    @attachedFile.url(style)

  toObject: (options) ->
    json = mongoose.Model.prototype.toObject.call(@, options)
    if options.client
      styles = _.extend {original: ''}, @config.styles
      for own style, options of styles
        json[style] = url: @url(style)
    json

Attachments.pre 'save', (next) ->
  return next() unless @isNew and @file?
  @attachedFile.save next

exports = module.exports = (schema, options) ->

  name = options.name
  schema.attachments ||= {}
  schema.attachments[name] = options

  if !schema.path 'attachments'
    schema.add 'attachments': [ Attachments ]

  schema.virtual(name).get ->
    _(@attachments).find (a) -> a.name == name

  schema.virtual(name).set (value) ->
    (existing = @get(name)) and existing.remove()
    if value.path? # It's a file
      @attachments.push
        name: name
        fileName: value.name
        contentType: value.type
        file: value.path
    else
      value.name = name
      @attachments.push value

  # This implementation is not quite right. It happens after other validation has succeeded but
  # before save so if other validation fails, this is not called. There is no mongoose hook in to validate.
  if options.required
    schema.pre 'save', (next) ->
      return next() if @get(name)?
      @invalidate name, 'required'
      next(@_validationError)



exports.Attachment = mongoose.model 'Attachment', Attachments