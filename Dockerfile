# FROM python:3.6-stretch
# FROM python:3.8-buster  # needs pip install numpy
# FROM python:3.7-stretch
FROM ubuntu:latest
RUN apt update

# the chmod will
# resolve PermissionError on heroku
# more context in issue #100
# TODO: make chmod less insecure by only setting needed permissions
RUN apt-get update \
  && apt-get install -y python3-pip python3-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip \
  && chmod 777 /usr/lib/python3/dist-packages/*

# verify permissions set
RUN ls -lah /usr/lib/python3/dist-packages/

# put the requirements file into the container
ADD requirements.txt /nimbus/requirements.txt

# install the requirements in the container
RUN pip install -r /nimbus/requirements.txt \
  && chmod 777 /usr/lib/python3/dist-packages/*

# verify permissions set
RUN ls -lah /usr/lib/python3/dist-packages/

# put all the code into nimbus folder
ADD . /nimbus

# # https://devcenter.heroku.com/articles/container-registry-and-runtime#unsupported-dockerfile-commands
# # Expose is NOT supported by Heroku
# EXPOSE 8080

# need to declare the --build-arg that gets passed in
# for ENV to work properly
ARG DATABASE_HOSTNAME
ARG DATABASE_PASSWORD
ARG DATABASE_USERNAME
ARG DATABASE_NAME
ARG PYDRIVE_CLIENT_ID
ARG PYDRIVE_CLIENT_SECRET
ARG GOOGLE_DRIVE_CREDENTIALS
ARG GOOGLE_DRIVE_FOLDER_ID
ARG GOOGLE_CLOUD_NLP_CREDENTIALS
ARG GOOGLE_CLOUD_NLP_MODEL_NAME

# env variables needed for the setup...py
ENV DATABASE_HOSTNAME ${DATABASE_HOSTNAME}
ENV DATABASE_PASSWORD ${DATABASE_PASSWORD}
ENV DATABASE_USERNAME ${DATABASE_USERNAME}
ENV DATABASE_NAME ${DATABASE_NAME}
ENV PYDRIVE_CLIENT_ID ${PYDRIVE_CLIENT_ID}
ENV PYDRIVE_CLIENT_SECRET ${PYDRIVE_CLIENT_SECRET}
ENV GOOGLE_DRIVE_CREDENTIALS ${GOOGLE_DRIVE_CREDENTIALS}
ENV GOOGLE_DRIVE_FOLDER_ID ${GOOGLE_DRIVE_FOLDER_ID}
ENV GOOGLE_CLOUD_NLP_CREDENTIALS ${GOOGLE_CLOUD_NLP_CREDENTIALS}
ENV GOOGLE_CLOUD_NLP_MODEL_NAME ${GOOGLE_CLOUD_NLP_MODEL_NAME}

# need set WORKDIR for setup...py to save config.json to right place
WORKDIR /nimbus

# generate all the special configuration files
RUN ./setup_special_files_from_env.py

## download the nlp stuff
# RUN ./download_nlp_stuff.sh
#
## download the nltk stuff
# RUN python3 download_nltk_stuff.py

# the above "download..." scripts were inconsistent on herkou
# so lets download the required stuff directly
RUN python3 -m spacy download en_core_web_sm  
# TODO: consider en_core_web_lg or en_core_web_md because server can handle it
# RUN python3 -m spacy download en_core_web_lg
RUN python3 -m nltk.downloader punkt
RUN python3 -m nltk.downloader averaged_perceptron_tagger 

# just make sure the file is there
RUN ls | grep config

# need set WORKDIR for gunicorn
WORKDIR /nimbus

# verify permissions set
RUN ls -lah /usr/lib/python3/dist-packages/

# https://github.com/heroku/alpinehelloworld/blob/master/Dockerfile
# Heroku will set the PORT environment variable
# the gunicorn_config.py will check the env vars for PORT
# else it will do port=8080
CMD ["gunicorn", "flask_api:app", "--config=gunicorn_config.py"]