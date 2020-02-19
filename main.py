
import os
import cv2
from flask import Flask, request, redirect, url_for,jsonify
from werkzeug.utils import secure_filename
from flask import jsonify
from tools import getCloseImages,loadImage
from PIL import Image

## AUXILIAR TOOLS ##
def stringToRGB(base64_string):
    imgdata = base64.b64decode(str(base64_string))
    image = Image.open(io.BytesIO(imgdata))
    return cv2.cvtColor(np.array(image), cv2.COLOR_BGR2RGB)

## MAIN API ##

app = Flask(__name__)

@app.route('/api/query', methods=['POST'])
def query():
    if request.method == 'POST':

        result = getCloseImages(stringToRGB((request.form['base64'])),request.form['range'])
        
        resultData = {'closeImages': result} 
        
        return jsonify(resultData)
    else:
        return jsonify({'message':'BAD REQUEST'})


@app.route('/api/loadImages', methods=['POST'])
def loadImages():
    if request.method == 'POST':
        imageList = request.form.getlist('images')
            
        for image_dic in imageList:
            image = stringToRGB(image_dic['base64'])
            name = image_dic['name']

            loadImage(image,name)
        
        return jsonify({'success':'true','message':'Imagenes cargadas con exito.'})
    
    else:
        return jsonify({'sucess':'false','message':'BAD REQUEST'})
        
if __name__ == '__main__':
     app.run(port='5002')
