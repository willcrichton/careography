define (require) ->
  requirejs.config
    enforceDefine: true
    inlineText: true
    urlArgs: "bust={new Date().getTime()}"

  paper.install(window)
  paper.setup('main')

  # wait at least DELTA_THREHSOLD milliseconds to update server
  DELTA_THRESHOLD = 100
  COLOR_PRESETS = [
    [20, 20, 20]
    [210, 45, 45]
    [220, 70, 210]
    [45, 100, 210]
    [100, 220, 220]
    [45, 145, 35]
    [235, 210, 55]
    [245, 245, 245]
  ]

  socket = io('http://' + document.location.host)
  paths = []
  path = null
  lastSend = null
  pathColor = new Color(0, 0, 0)

  getTime = ->
    new Date().getTime()

  sendPoint = (args) ->
    args.color = [pathColor.red, pathColor.green, pathColor.blue]
    socket.emit('update', args)

  tool = new Tool()
  tool.onMouseDown = (event) ->
    path = new Path()
    path.strokeColor = pathColor
    path.strokeWidth = 5
    path.strokeCap = 'round'
    path.opacity = 0.9
    path.add(event.point)

    sendPoint
      x: event.point.x
      y: event.point.y
      start: true
      delta: 0

    lastSend = getTime()

  tool.onMouseDrag = (event) ->
    path.add(event.point)

    time = getTime()
    if time - lastSend > DELTA_THRESHOLD
      sendPoint
        x: parseInt(Math.floor(event.point.x))
        y: parseInt(Math.floor(event.point.y))
        start: false
        delta: time - lastSend

      lastSend = time

  tool.onMouseUp = (event) ->
    paths = paths.concat(path.segments)
    sendPoint
      x: event.point.x
      y: event.point.y
      start: false
      delta: getTime() - lastSend

  visitedPath = null
  socket.on 'moved', (point) ->
    if point.start
      visitedPath = new Path()
      visitedPath.strokeWidth = 8
      visitedPath.strokeColor = 'red'

    visitedPath.add(new Point(point.x, point.y))
    console.log(visitedPath, point)
    view.draw()

  $(document).ready ->
    $('#colors').css('width', COLOR_PRESETS.length * 50)
    for color in COLOR_PRESETS
      active = if color[0] == COLOR_PRESETS[0][0] and color[1] == COLOR_PRESETS[0][1] and color[2] == COLOR_PRESETS[0][2] then "active" else ""
      $div = $("<div class='color #{active}'></div>");
      $div.css('background-color', 'rgb(' + color.join(',') + ')')
      $div.data('color', color)
      $('#colors').append($div)

    $('.color').click ->
      $('.color').removeClass('active')
      $(this).addClass('active')
      pathColor = new Color($(this).data('color').map((n) -> n / 255))

    $('#splash').click ->
      if document.body.webkitRequestFullscreen?
        document.body.webkitRequestFullscreen(Element.ALLOW_KEYBOARD_INPUT)
      else if document.body.mozRequestFullScreen?
        document.body.mozRequestFullScreen()

    $(document).on 'fullscreenchange mozfullscreenchange webkitfullscreenchange', ->
      $('#canvas').css
        opacity: '0.01'
        display: 'block'

      setTimeout( ->
        $('#splash').fadeOut(1000)
        $('#canvas').animate({opacity: 1}, 1000)
      , 1000)

    $(document).on 'keyup', (event) ->
      if event.which != 67 then return
      for path in paths
        path.remove()

      visitedPath?.remove()
      view.draw()
