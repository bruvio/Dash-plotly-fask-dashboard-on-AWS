# FROM python:3.7-slim
# # continuumio/miniconda3
# WORKDIR /usr/src/app

# COPY ./workouts_bruvio_2020.csv /usr/src/app/workouts_bruvio_2020.csv
# COPY ./requirements.txt /tmp/ 
# COPY ./app /usr/src/app
# RUN apt update \
#     && apt-get install -y libglib2.0-0 libsm6 libxrender1 libxext6 libgl1-mesa-dev

# RUN pip install --no-cache-dir -r /tmp/requirements.txt



# ENTRYPOINT [ "python3" ]
# CMD [ "python","application.py" ]


# EXPOSE 8050


FROM ubuntu:20.10

# LABEL maintainer="Chris von Csefalvay <chris@chrisvoncsefalvay.com>"

RUN apt-get update
RUN apt-get install -y python3 python3-dev python3-pip
# RUN apt-get install -y gunicorn

COPY ./workouts_bruvio_2020.csv /app/workouts_bruvio_2020.csv
COPY ./requirements.txt /tmp/ 
COPY ./ /app

RUN pip3 install -r /tmp/requirements.txt

COPY ./ /app
WORKDIR /app

# CMD [ "gunicorn" "--bind" "0.0.0.0:80" "wsgi" ]
CMD gunicorn --bind 0.0.0.0:80 wsgi