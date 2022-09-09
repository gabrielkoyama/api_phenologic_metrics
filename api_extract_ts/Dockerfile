FROM ubuntu:20.04

RUN apt update -y && \
    apt install -y python3-pip python3-dev && \
    pip install wtss==0.7.0-1 && \
    pip3 install Flask geopandas datetime scipy earthengine-api seaborn ipygee matplotlib tqdm 

COPY . /app

WORKDIR /app

ENTRYPOINT [ "python3" ]

CMD [ "app.py" ]


# docker build -t extract-ts-flask .
# docker run -d -p 8081:8080 extract-ts-flask