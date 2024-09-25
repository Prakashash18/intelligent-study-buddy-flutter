# Use a simple web server to serve the built app
FROM nginx:alpine

# Copy the built Flutter web app to the Nginx HTML directory
COPY build/web /usr/share/nginx/html

# Copy .env file to the assets directory
# COPY lib/.env /usr/share/nginx/html/assets/.env
# Move nested assets to the correct location
RUN mv /usr/share/nginx/html/assets/assets/* /usr/share/nginx/html/assets/ && rmdir /usr/share/nginx/html/assets/assets

RUN echo $PORT

# RUN echo "8080"

COPY build/web/nginx.conf /etc/nginx/conf.d/default.conf

CMD sed -i -e 's/$PORT/'"$PORT"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'

# CMD nginx -g 'daemon off;'