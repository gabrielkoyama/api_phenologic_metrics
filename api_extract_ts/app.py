import os
import json
from extract_ts import extract as aux_extract
from extract_ts import extract_mock as aux_extract_mock
from flask import Flask,request, make_response
import pdb 

app = Flask(__name__)

@app.route('/extract-ts',methods=['GET', 'POST'])
def extract():

    if(request.method == 'GET'):

        geojson  = json.loads(request.args.get("roi"))
        period   = request.args.get("period")
        datacube = request.args.get("datacube")
        token    = request.args.get("token")

        token    = "ZcuMgQjFvNxzKUr1WvRgzioztBK0ZxFa2AqJSxuUS8"
        datacube = "S2-SEN2COR_10_16D_STK-1"

        # payload = aux_extract(geojson, token, datacube, period, n_points=2 ) # str json
        payload = aux_extract_mock(geojson, token, datacube, period, n_points=2 ) # str json

        res = make_response(payload)
        res.headers['Content-Type'] = 'application/json'

        return res
    
    # if(request.method == 'POST'):

    #     geojson  = request.json.get("roi")
    #     period   = request.json.get("period")
    #     datacube = request.json.get("datacube")
    #     token    = request.json.get("token")

    #     token    = "ZcuMgQjFvNxzKUr1WvRgzioztBK0ZxFa2AqJSxuUS8"
    #     datacube = "S2-SEN2COR_10_16D_STK-1"

    #     parameters = { 
    #         "geojson": geojson,
    #         "period": period,
    #         "datacube": datacube,
    #         "token":token }
        
    #     print(parameters)
        
    #     payload = aux_extract_mock(geojson, token, datacube, period, n_points=2 ) # str json

    #     res = make_response(payload)
    #     res.headers['Content-Type'] = 'application/json'

    #     return res


@app.route('/',methods=['GET'])
def teste(roi=""):

    roi = request.args.get("roi")
    print(roi)

    payload = {"ok": 1}
    res = make_response(payload)
    return res



if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0',port=int(os.environ.get("PORT", 8081)))
