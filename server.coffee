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
carC = 5  #TEMPORARY!! diameter of car

cap = (powerlevel) ->
  if powerlevel > 255
    return 255
  else
    return Math.floor(powerlevel)

powerup = (theta, d) ->
  # deal with small theta case (go straight)
  if theta < (Math.PI/16)
    return (powl: 100, powr: 100)
  part1 = (d / (Math.PI * theta))
  part2 = (carC/2)
  r = (d / (Math.PI * theta)) - (carC / 2)
  if theta < Math.PI
    powl = (r + carC)*Math.PI*theta
    powr = (r)*Math.PI*theta
  else
    powr = (r + carC)*Math.PI*theta
    powl = (r)*Math.PI*theta
 # console.log(theta,  r, "dist: ", d, "powl", powl, "powr", powr)

  return (powl: powl, powr: powr)    

reorient = (p1, p2) ->
  a = p1.x
  b = p1.y
  c = p2.x
  d = p2.y

  quarter = Math.PI / 2
  quarterTime = 4
  x = c - a
  y = d - b

  magnitude = Math.sqrt(x * x + y * y)
  if magnitude == 0
    return {L: 0, R: 0, t: quarterTime}

  unitx = x / magnitude
  unity = y / magnitude
  turnAngle = Math.acos(unitx * headingx + unity * headingy)
  if turnAngle > quarter and turnAngle < (3*quarter)
    turnDir = if (turnAngle > (2*quarter)) then 1 else -1 
    return {L: 100 * turnDir, R: -100 * turnDir, t: quarterTime * (turnAngle / quarter)}
  else
    powers = powerup(turnAngle, magnitude)
    return {L: cap(powers.powl), R: cap(powers.powr), t: 1}

app.use '/query', (req, res) ->
  io.sockets.emit('moved', path[counter])

  if path.length - counter < 2
    res.send([0, 0, 0, 0, 0, 0, path.length].join(' '))
    return

  currpt = path[counter + 1]
  prevpt = path[counter]
#  console.log(prevpt, "to" , currpt)
  counter += 1

  data = reorient(currpt, prevpt)
  res.send([data.L, data.R, data.t, prevpt.x, prevpt.y, counter, path.length].join(' '))

app.use (req, res, next)->
  counter = 0
  path = []
  next()

app.use(express.static(__dirname + '/www'))

io.on 'connection', (socket) ->
  socket.on 'update', (data) ->
    path.push(new Point(data.x, data.y, data.delta, data.start, data.color))
