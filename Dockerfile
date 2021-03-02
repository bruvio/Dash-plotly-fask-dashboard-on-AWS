FROM ubuntu:20.10

# LABEL maintainer="Chris von Csefalvay <chris@chrisvoncsefalvay.com>"

RUN apt-get update
RUN apt-get install -y python3 python3-dev python3-pip
# RUN apt-get install -y gunicorn


COPY ./requirements.txt /tmp/ 


RUN pip3 install -r /tmp/requirements.txt

COPY ./app /app
WORKDIR /app

# CMD [ "gunicorn" "--bind" "0.0.0.0:80" "wsgi" ]
CMD gunicorn --bind 0.0.0.0:80 wsgi