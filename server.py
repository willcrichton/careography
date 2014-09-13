from flask import Flask, render_template
from flask_cake import Cake
app = Flask(__name__)
cake = Cake(app)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == "__main__":
    cake.init_app(app)
    app.run(debug=True)
