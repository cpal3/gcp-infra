from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    hostname = os.uname()[1]
    return f"Hello from GKE! Running on host: {hostname}\n"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
