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
scaling = 4  #try not to change this number
distScaling = 5
walkScaling = 4
waitTime = 250
revolution = 1700


carC = 50  #TEMPORARY!! diameter of car

cap = (powerlevel) ->
  newPower = 0
  if powerlevel > 255
    powerlevel = 255
  if powerlevel > 0
    newPower = (powerlevel / 1.13333333) + 30
   return Math.floor(newPower)

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
 #   console.log("checking rightness of","(", a, b, ") and (", c, d,")")
    if (b >= 0 and d >= 0)
       return a < c
    if (b <= 0 and d <= 0)
       return a > c
    else
       return not rightness(-a,-b, c,d)


reorient = (p1, p2) ->
  a = p1.x
  b = p1.y
  c = p2.x
  d = p2.y

  quarter = Math.PI / 2
  quarterTime = revolution / (4 * scaling)
  x = a - c
  y = b - d

  magnitude = Math.sqrt(x * x + y * y)
  if magnitude == 0
    return {L: 0, R: 0, t: p2.delta}

  unitx = x / magnitude
  unity = y / magnitude
  turnAngle = Math.acos(unitx * headingx + unity * headingy)

  right = rightness(unitx, unity, headingx, headingy)

#  if headingx != unitx || headingy != unity
#  console.log("from",headingx, headingy, "to", unitx, unity, "turning", if right then "right" else "left")

  #If this heading is right, we win
  headingx = unitx
  headingy = unity

  console.log(turnAngle, p1.delta)

  if turnAngle > (quarter / 4)
    turnDir = if right then 1 else -1
    return {L: 255 * turnDir, R: -255 * turnDir, t: quarterTime * (turnAngle/quarter)}
  else
    powers = powerup(turnAngle, magnitude, right)
    return {L: cap(powers.powl), R: cap(powers.powr), t: Math.floor(p1.delta)}

app.use '/query', (req, res) ->
  if path[counter]?
    io.sockets.emit('moved', path[counter])

  if path.length - counter < 2
    console.log("0")
    res.send([0, 0, waitTime, 0, 0, 0, path.length].join(' '))
    return
  if queuedIns.length > 0
    retVal = queuedIns.shift()
    console.log(retVal)
    res.send(retVal.join(' '))
    return

  currpt = path[counter + 1]
  prevpt = path[counter]
#  console.log(prevpt, "to" , currpt)
  counter += 1

  data = reorient(currpt, prevpt)
  if data.L * data.R == -65025
    queuedIns.push ([120, 120, currpt.delta, currpt.x, currpt.y, headingx, headingy])
  args = [data.L, data.R, scaling*data.t, currpt.x, currpt.y, headingx, headingy]
  console.log(args)
  res.send(args.join(' '))

app.use (req, res, next)->
  counter = 0
  path = []
  next()

app.use(express.static(__dirname + '/www'))

io.on 'connection', (socket) ->
  socket.on 'update', (data) ->
    path.push(new Point(data.x, data.y, data.delta, data.start, data.color))
