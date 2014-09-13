from flask import Flask, render_template, g, request
from flask_cake import Cake
import math

app = Flask(__name__)
cake = Cake(app)

path = []
(headingx, headingy) = (0.0, 1.0) 
prevInstr = (0, 0, 0)
@app.route('/')
def index():
    del path[:]
    
    return render_template('index.html')

class Point:
    def __init__(self, x, y, delta, start, color):
        self.x = x
        self.y = y
        self.delta = delta
        self.start = start
        self.color = color

    def __repr__(self):
        return repr([self.x, self.y, self.delta, self.start, self.color])

@app.route('/update')
def update():
    x = float(request.args.get('x'))
    y = float(request.args.get('y'))
    delta = int(request.args.get('delta'))
    color = (int(request.args.get('r')), int(request.args.get('g')), int(request.args.get('b')))
    start = request.args.get('start')
    #heading = request.args.get('heading') method does not exist yet.
    path.append(Point(x, y, delta, start, color))

    return ''

# returns (left motor energy, right motor energy, duration, light on, light r, light g, light b)
@app.route('/query')
def query():
    print path
    if len(path) < 2:
        return ' '.join(map(repr, [0,0,0,0,0,0,0]))
    (currpt, prevpt) = (path[0], path[0])
    (L, R, t) = reorient((currpt.x, currpt.y), (prevpt.x, prevpt.y))
    #fix thing but we ignore this for now.
    args = [L, R, t, 4, 3, 2, 1]
    return ' '.join(map(repr, args))

#returns the energy levels needed to reorient from (a,b) to (c,d)
def reorient((a,b), (c,d)):
    quarter = math.pi/4
    quarterTime = 4
    (x,y) = (c-a, d-b)
    magnitude = math.hypot(x,y)
    (unitx, unity) = (x / magnitude, y / magnitude)
    turnAngle = math.acos(unitx*headingx + unity*headingy)
    turnDir = 1 if turnAngle < quarter else -1
    #naive for now
    return (100 * turnDir, -100 * turnDir, quarterTime * (turnAngle / quarter))

    

#return a set of directions to be run 
if __name__ == "__main__":
    cake.init_app(app)
    app.run(host='0.0.0.0', debug=True)
