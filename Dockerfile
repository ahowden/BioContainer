FROM alpine

RUN apk add --update python3 perl

Copy ["tools","main.py","./"]

CMD ["python","./main.py"]

EXPOSE 80