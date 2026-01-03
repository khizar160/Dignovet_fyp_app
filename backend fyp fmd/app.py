from flask import Flask, request, jsonify
from fmd_model import predict_from_image_file  # import the function
import os

app = Flask(__name__)

@app.route("/predict", methods=["POST"])
def predict():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "Empty filename"}), 400

    try:
        result = predict_from_image_file(file)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # host='0.0.0.0' allows access from other devices like Flutter on phone
    app.run(host="0.0.0.0", port=8000, debug=True)
