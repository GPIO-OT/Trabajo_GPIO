# swagger_template.py

swagger_template = {
    "swagger": "2.0",
    "info": {
        "title": "BE TEST",
        "description": "API documentation for BE",
        "version": "1.0.0",
    },
    "basePath": "/",
    "schemes": ["http", "https"],
    "securityDefinitions": {
        "Bearer": {
            "type": "apiKey",
            "name": "Authorization",
            "in": "header",
            "description": "Enter the token with the `Bearer: ` prefix, e.g. Bearer abcde12345.",
        }
    },
    "security": [{"Bearer": []}],
}
