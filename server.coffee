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
headingy = -1.0
queuedIns = []
scaling = 4
distScaling = 8

carC = 5  #TEMPORARY!! diameter of car

cap = (powerlevel) ->
  if powerlevel > 255
    return 255
  else
    return Math.floor(powerlevel)

powerup = (theta, d, right) ->
  # deal with small theta case (go straight)
  if theta < (Math.PI/16)
    return (powl: 100, powr: 100)
  part1 = (d / (Math.PI * theta))
  part2 = (carC/2)
  r = (d / (Math.PI * theta)) - (carC / 2)
  if right
    powl = (r + carC)*Math.PI*theta
    powr = (r)*Math.PI*theta
  else
    powr = (r + carC)*Math.PI*theta
    powl = (r)*Math.PI*theta
#  console.log(theta,  r, "dist: ", d, "powl", powl, "powr", powr)

  return (powl: distScaling*powl, powr: distScaling*powr)    

rightness = (a,b, c,d) ->
    console.log("checking rightness of","(", a, b, ") and (", c, d,")")
    if (b >= 0 and d >= 0)
       return a > c
    if (b <= 0 and d <= 0)
       return a < c
    else
       return not rightness(-a,-b, c,d)
       

reorient = (p1, p2) ->
  a = p1.x
  b = p1.y
  c = p2.x
  d = p2.y

  quarter = Math.PI / 2
  quarterTime = 1000
  x = a - c
  y = b - d
  
  magnitude = Math.sqrt(x * x + y * y)
  if magnitude == 0
    return {L: 0, R: 0, t: p2.delta * scaling}

  unitx = x / magnitude
  unity = y / magnitude
  turnAngle = Math.acos(unitx * headingx + unity * headingy)
 
  right = rightness(unitx, unity, headingx, headingy)

  #This heading will be very wrong
  headingx = unitx
  headingy = unity
#  console.log("new heading:", headingx, headingy)

  if turnAngle > quarter
    turnDir = if right then 1 else -1 
    normedTurn = if turnAngle > 2*quarter then 4*quarter - turnAngle else turnAngle
    return {L: 255 * turnDir, R: -255 * turnDir, t: quarterTime * (normedTurn / quarter)}
  else
    powers = powerup(turnAngle, magnitude, right)
    return {L: cap(powers.powl), R: cap(powers.powr), t: cap(p1.delta)}

app.use '/query', (req, res) ->
  io.sockets.emit('moved', path[counter])

  if path.length - counter < 2
    res.send([0, 0, 0, 0, 0, 0, path.length].join(' '))
    return
  if queuedIns.length > 0
    retVal = queuedIns.shift()
    res.send(retVal.join(' '))
    return

  currpt = path[counter + 1]
  prevpt = path[counter]
#  console.log(prevpt, "to" , currpt)
  counter += 1

  data = reorient(currpt, prevpt)
  if data.L * data.R == -65025
    queuedIns.push ([120, 120, currpt.t, prevpt.x, prevpt.y, counter, path.length])
  res.send([data.L, data.R, data.t, prevpt.x, prevpt.y, counter, path.length].join(' '))

app.use (req, res, next)->
  counter = 0
  path = []
  next()

app.use(express.static(__dirname + '/www'))

io.on 'connection', (socket) ->
  socket.on 'update', (data) ->
    path.push(new Point(data.x, data.y, data.delta, data.start, data.color))
