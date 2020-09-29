FROM python:3.7.5
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /code/

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends \
        rlwrap \
        gettext \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y --force-yes

# speed up caching
ADD requirements.txt /code/
ADD requirements_dev.txt /code/

RUN pip install -r requirements_dev.txt
 
ADD . /code/

