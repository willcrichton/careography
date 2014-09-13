define (require) ->
  requirejs.config
    enforceDefine: true
    inlineText: true
    urlArgs: "bust={new Date().getTime()}"