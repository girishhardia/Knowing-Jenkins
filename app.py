# app.py
# This is the main file for our Flask application.

from flask import Flask

# Initialize the Flask application
app = Flask(__name__)

# Define a route for the root URL ('/')
@app.route('/')
def hello_world():
    """
    This function is executed when a user accesses the root URL.
    It returns a simple 'Hello, World!' string.
    """
    return 'Hello, World from Flask in a Docker container!'

# This block ensures that the development server is run only when
# this script is executed directly (not when imported as a module).
if __name__ == '__main__':
    # The app will run on host 0.0.0.0, which makes it accessible
    # from outside the container. Port 5000 is the standard for Flask.
    app.run(host='0.0.0.0', port=5000)
