from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from PIL import Image
from tensorflow.keras.preprocessing.sequence import pad_sequences
from keras.applications.xception import Xception
from tensorflow.keras.applications.xception import preprocess_input
from tensorflow.keras.models import load_model
import pickle
import io

app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests

# Load tokenizer and model
with open("tokenizer.p", 'rb') as f:
    tokenizer = pickle.load(f)

model = load_model('models/model_9.h5')
xception_model = Xception(include_top=False, pooling="avg")
# Function to extract features using Xception model
def extract_features(image, model):
    try:
        img = Image.open(io.BytesIO(image))
    except:
        return None
    img = img.resize((299, 299))
    img = np.array(img)
    if img.shape[2] == 4:
        img = img[..., :3]
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img)
    feature = model.predict(img)
    return feature

# Function to map integer predictions to words
def word_for_id(integer, tokenizer):
    for word, index in tokenizer.word_index.items():
        if index == integer:
            return word
    return None

# Function to generate a description for the image
def generate_desc(model, tokenizer, photo, max_length):
    in_text = 'start'
    for i in range(max_length):
        sequence = tokenizer.texts_to_sequences([in_text])[0]
        sequence = pad_sequences([sequence], maxlen=max_length)
        pred = model.predict([photo, sequence], verbose=0)
        pred = np.argmax(pred)
        word = word_for_id(pred, tokenizer)
        if word is None:
            break
        in_text += ' ' + word
        if word == 'end':
            break
    return in_text

# Maximum sequence length
max_length = 32

@app.route('/caption', methods=['POST'])
def get_caption():
    if 'image' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    image_file = request.files['image']
    image_bytes = image_file.read()
    photo = extract_features(image_bytes, xception_model)
    if photo is None:
        return jsonify({'error': 'Error processing image'}), 400
    caption = generate_desc(model, tokenizer, photo, max_length)
    return jsonify({'caption': caption}), 200

if __name__ == '__main__':
    app.run(debug=True, host='ip')  # Listen on all IP addresses
