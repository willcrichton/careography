express = require('express')
app = express()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(5000)

class Point
  constructor: (@x, @y, @delta, @start, @color) ->

path = []
counter = 0
headingx = 0.0
headingy = 1.0

reorient = (p1, p2) ->
  a = p1.x
  b = p1.y
  c = p2.x
  d = p2.y

  quarter = Math.PI / 4
  quarterTime = 4
  x = c - a
  y = d - b

  magnitude = Math.sqrt(x * x + y * y)
  if magnitude == 0
    return {L: 0, R: 0, t: quarterTime}

  unitx = x / magnitude
  unity = y / magnitude
  turnAngle = Math.acos(unitx * headingx + unity * headingy)
  turnDir = if turnAngle < quarter then 1 else -1

  return {L: 100 * turnDir, R: -100 * turnDir, t: quarterTime * (turnAngle / quarter)}

app.use '/query', (req, res) ->
  io.sockets.emit('moved', path[counter])

  if path.length - counter < 2
    res.send([0, 0, 0, 0, 0, 0, path.length].join(' '))
    return

  currpt = path[counter + 1]
  prevpt = path[counter]
  counter += 1

  data = reorient(currpt, prevpt)
  res.send([data.L, data.R, data.t, 3, 3, 2, path.length].join(' '))

app.use (req, res, next)->
  counter = 0
  path = []
  next()

app.use(express.static(__dirname + '/www'))

io.on 'connection', (socket) ->
  socket.on 'update', (data) ->
    path.push(new Point(data.x, data.y, data.delta, data.start, data.color))