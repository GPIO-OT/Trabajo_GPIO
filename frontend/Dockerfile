# Usar la imagen oficial de Node.js
FROM node:18-alpine

# Crear y establecer el directorio de trabajo
WORKDIR /app

# Copiar el archivo package.json y package-lock.json (si existe)
COPY package*.json ./

# Instalar las dependencias
RUN npm install

# Copiar el resto de los archivos del proyecto
COPY . .

# Construir la aplicación
RUN npm run build

# Exponer el puerto en el que la aplicación va a correr
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["npm", "start"]
