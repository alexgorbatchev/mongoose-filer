// Generated by CoffeeScript 1.6.2
(function() {
  var EventEmitter, Processor, assert, async, dir, exports, fs, imagemagick, path, tmpFile, _i, _len, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  imagemagick = require('imagemagick');

  async = require('async');

  EventEmitter = require('events').EventEmitter;

  assert = require('assert');

  path = require('path');

  fs = require('fs');

  tmpFile = function() {
    var i, name, _i;

    name = "";
    for (i = _i = 0; _i < 32; i = ++_i) {
      name += Math.floor(Math.random() * 16).toString(16);
    }
    return path.join(Processor.tmpDir, name);
  };

  exports = module.exports = Processor = (function(_super) {
    __extends(Processor, _super);

    function Processor(file, options) {
      this.file = file;
      this.options = options != null ? options : {};
    }

    Processor.prototype.conversions = function() {
      var conversion, conversions, destFileBase, style;

      destFileBase = tmpFile();
      return conversions = (function() {
        var _ref, _results,
          _this = this;

        _ref = this.options.styles;
        _results = [];
        for (style in _ref) {
          conversion = _ref[style];
          _results.push((function(style, conversion) {
            var args, destFile, groups, processor;

            destFile = "" + destFileBase + "-" + style;
            args = [_this.file.path, '-auto-orient', '-resize', conversion];
            if (groups = conversion.match(/^(.*)\^$/)) {
              args = args.concat(['-gravity', 'center', '-extent', groups[1]]);
            }
            args.push(destFile);
            processor = _this;
            return {
              style: style,
              path: destFile,
              args: args,
              convert: function(cb) {
                return imagemagick.convert(args, function(err) {
                  if (err != null) {
                    return cb("Imagemagick " + err);
                  }
                  processor.emit('convert', {
                    style: style,
                    file: destFile
                  });
                  return cb(null);
                });
              }
            };
          })(style, conversion));
        }
        return _results;
      }).call(this);
    };

    Processor.prototype.convert = function(cb) {
      var c, conversions,
        _this = this;

      conversions = this.conversions();
      return async.parallel((function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = conversions.length; _i < _len; _i++) {
          c = conversions[_i];
          _results.push(c.convert);
        }
        return _results;
      })(), function(err) {
        if (err != null) {
          _this.emit('error', err);
        }
        _this.emit('done');
        if (cb != null) {
          return cb(err);
        }
      });
    };

    return Processor;

  })(EventEmitter);

  _ref = [process.env.TMPDIR, '/tmp'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    dir = _ref[_i];
    if (!Processor.tmpDir && fs.existsSync(dir)) {
      Processor.tmpDir = dir;
    }
  }

  assert.ok(Processor.tmpDir, "Unable to find temp dir. Please set environment variable TMPDIR.");

}).call(this);
