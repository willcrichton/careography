define (require) ->
  requirejs.config
    enforceDefine: true
    inlineText: true
    urlArgs: "bust={new Date().getTime()}"

  paper.install(window)
  paper.setup('main')

  path = null
  tool = new Tool()

  tool.onMouseDown = (event) ->
    path = new Path()
    path.strokeColor = 'black'
    path.strokeWidth = 5

  tool.onMouseDrag = (event) ->
    path.add(event.point)

  tool.onMouseUp = ->
    path.simplify(2.0)
