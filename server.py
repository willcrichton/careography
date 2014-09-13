from flask import Flask, render_template, g, request
from flask_cake import Cake
app = Flask(__name__)
cake = Cake(app)

path = []
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
    x = int(request.args.get('x'))
    y = int(request.args.get('y'))
    delta = int(request.args.get('delta'))
    color = (int(request.args.get('r')), int(request.args.get('g')), int(request.args.get('b')))
    start = request.args.get('start')
    path.append(Point(x, y, delta, start, color))

    return ''

# returns (left motor energy, right motor energy, duration, light on, light r, light g, light b)
@app.route('/query')
def query():
    args = [0, 0, 0, 0, 0, 0, 0]
    return ' '.join(map(repr, args))

if __name__ == "__main__":
    cake.init_app(app)
    app.run(debug=True)
