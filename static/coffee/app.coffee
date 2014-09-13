define (require) ->
  requirejs.config
    enforceDefine: true
    inlineText: true
    urlArgs: "bust={new Date().getTime()}"

  paper.install(window)
  paper.setup('main')

  # wait at least DELTA_THREHSOLD milliseconds to update server
  DELTA_THRESHOLD = 100


  getTime = ->
    new Date().getTime()

  path = null
  lastSend = null
  color = [255, 255, 255]

  tool = new Tool()
  tool.onMouseDown = (event) ->
    path = new Path()
    path.strokeColor = 'black'
    path.strokeWidth = 5

    lastSend = getTime()
    $.ajax
      url: '/update'
      data:
        x: event.point.x
        y: event.point.y
        r: color[0]
        g: color[1]
        b: color[2]
        start: true
        delta: 0


  tool.onMouseDrag = (event) ->
    path.add(event.point)

    time = getTime()
    if time - lastSend > DELTA_THRESHOLD
      $.ajax
        url: '/update'
        data:
          x: event.point.x
          y: event.point.y
          r: color[0]
          g: color[1]
          b: color[2]
          start: false
          delta: time - lastSend

      lastSend = time

  tool.onMouseUp = ->
    path.simplify(2.0)
