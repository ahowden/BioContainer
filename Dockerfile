FROM alpine

RUN apk add --update python3 perl

Copy ["src","main.py","./"]

CMD ["python","./main.py"]

CMD ["ls /var/lib/docker/volumes/seq-vol/_data"]

EXPOSE 80