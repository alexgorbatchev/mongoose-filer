async = require 'async'
mongoose = require 'mongoose'
_ = require 'underscore'
Attachment = require './attachment'

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

Attachments.path('contentType').validate (v) ->
  contentTypes = @parent?.schema.attachments[@name].contentType
  return !contentTypes? or (v in contentTypes)
, "acceptable content type"

Attachments.method
  url: (style) ->
    @attachment ||=  new Attachment @parent.id,
      name: @fileName
      prefix: @prefix()
      styles: @parent.schema.attachments[@name].styles

    @attachment.url(style)

  prefix: ->
    @parent.schema.attachments[@name].prefix or "#{@parent.constructor.modelName}/#{@name}"


exports = module.exports = (schema, options) ->

  name = options.name
  schema.attachments ||= {}
  schema.attachments[name] = options

  if !schema.path 'attachments'
    schema.add 'attachments': [ Attachments ]
    schema.pre 'save', (next) ->
      saves = for attachment in @attachments when attachment.isNew && attachment.file?
        a = new Attachment @id,
          prefix: attachment.prefix()
          styles: options.styles
          file: attachment.file
        (cb) -> a.save cb
      async.parallel saves, next

  schema.virtual(name).get ->
    _(@attachments).find (a) -> a.name == name

  schema.virtual(name).set (value) ->
    (existing = @get(name)) and existing.remove()
    if value.path # it's a file
      @attachments.push
        name: name
        fileName: value.name
        contentType: value.type
        file: value.path

exports.MongooseAttachment = mongoose.model 'Attachment', Attachments

