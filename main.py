
import os,io
import base64
from flask import Flask, request, redirect, url_for,jsonify
from werkzeug.utils import secure_filename
from flask import jsonify
from tools import getCloseImages,loadImage
from PIL import Image

## AUXILIAR TOOLS ##
def stringToIMG(base64_string):
    imgdata = base64.b64decode(str(base64_string))
    image = Image.open(io.BytesIO(imgdata))
    return image

## MAIN API ##

app = Flask(__name__)

@app.route('/api/query', methods=['POST'])
def query():
    if request.method == 'POST':
        imageJson = request.get_json()
        queryResult = getCloseImages((stringToIMG(imageJson['base64'])),imageJson['range'])
        result = []
        for image in queryResult:
            with open('./images/'+image[0],'rb') as img_file:
                result.append({'name': image[0],'image': base64.b64encode(img_file.read()),'distance':image[1]})

        return jsonify({'closeImages': result})


@app.route('/api/loadImages', methods=['POST'])
def loadImages():
    if request.method == 'POST':

        imageListJson = request.get_json()
        for image_dic in imageListJson['images']:
            image = stringToIMG(image_dic['base64'])
            name = image_dic['filename']
            
            image.save('./images/'+name)

            loadImage(image,name)
        
        return jsonify({'success':'true','message':'Imagenes cargadas con exito.'})
        
if __name__ == '__main__':
     app.run(port=5000)
