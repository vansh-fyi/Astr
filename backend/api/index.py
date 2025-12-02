from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"status": "online", "service": "Astr Backend"})

@app.route('/api/health')
def health():
    return jsonify({"status": "ok"})

# Vercel requires the app to be exposed as 'app'
if __name__ == '__main__':
    app.run(debug=True)
