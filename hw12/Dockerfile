FROM alpine:3.17

EXPOSE 80 443


RUN apk add --no-cache nginx

RUN adduser -D -g 'www' www 

RUN mkdir -p /run/nginx && mkdir -p /www  
RUN chown -R www:www /var/lib/nginx && chown -R www:www /www 


COPY index.html /www  
COPY nginx.conf /etc/nginx/nginx.conf


ENTRYPOINT ["nginx"]


