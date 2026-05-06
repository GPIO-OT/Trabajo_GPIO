FROM node:20-alpine AS build
WORKDIR /app
ARG REACT_APP_API_BASE_URL=/api
ARG REACT_APP_API_KEY=gpio-api-key-2026
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL
ENV REACT_APP_API_KEY=$REACT_APP_API_KEY
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
