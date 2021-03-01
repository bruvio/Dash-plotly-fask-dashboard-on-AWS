FROM python:3.7-slim
# continuumio/miniconda3
WORKDIR /usr/src/app

COPY ./workouts_bruvio_2020.csv /usr/src/app/workouts_bruvio_2020.csv
COPY ./requirements.txt /tmp/ 
COPY ./app /usr/src/app
RUN apt update \
    && apt-get install -y libglib2.0-0 libsm6 libxrender1 libxext6 libgl1-mesa-dev

RUN pip install --no-cache-dir -r /tmp/requirements.txt



# ENTRYPOINT [ "python3" ]
CMD [ "python","application.py" ]


EXPOSE 8050
