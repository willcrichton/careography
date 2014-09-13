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
    [0, 0, 0],
    [255, 0, 0],
    [0, 255, 0],
    [0, 0, 255],
    [255, 255, 0],
    [0, 255, 255],
    [255, 0, 255],
    [255, 255, 255]
  ]

  path = null
  lastSend = null
  pathColor = new Color(0, 0, 0)

  getTime = ->
    new Date().getTime()

  sendPoint = (args) ->
    $.ajax
      url: '/update'
      data: $.extend(args,
        r: pathColor.red
        g: pathColor.green
        b: pathColor.blue
      )

  tool = new Tool()
  tool.onMouseDown = (event) ->
    path = new Path()
    path.strokeColor = pathColor
    path.strokeWidth = 5
    path.add(event.point)

    lastSend = getTime()
    sendPoint
      x: event.point.x
      y: event.point.y
      start: true
      delta: 0

  tool.onMouseDrag = (event) ->
    path.add(event.point)

    time = getTime()
    if time - lastSend > DELTA_THRESHOLD
      sendPoint
        x: event.point.x
        y: event.point.y
        start: false
        delta: time - lastSend

      lastSend = time

  tool.onMouseUp = ->
    path.simplify(2.0)

  $(document).ready ->
    $('#colors').css('width', COLOR_PRESETS.length * 50)
    for color in COLOR_PRESETS
      $div = $('<div class="color"></div>');
      $div.css('background-color', 'rgb(' + color.join(',') + ')')
      $div.data('color', color)
      $('#colors').append($div)

    $('.color').click ->
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
