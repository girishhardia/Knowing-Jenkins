# Dockerfile
# This file contains the instructions for Docker to build our container image.

# 1. Start with an official Python runtime as a parent image.
# We're using Python 3.8 on a slim version of Debian (buster) for a smaller image size.
FROM python:3.8-slim-buster

# 2. Set the working directory inside the container.
# This is where our application code will live.
WORKDIR /app

# 3. Copy the local code to the container's working directory.
# Copy requirements.txt first to leverage Docker's layer caching.
COPY requirements.txt requirements.txt

# 4. Install any needed packages specified in requirements.txt.
# --no-cache-dir: Disables the cache, which is good for keeping image size down.
# -r requirements.txt: Tells pip to install from the given requirements file.
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of the application's code into the container.
# This copies the current directory (.) on the host to the current
# working directory (.) inside the container.
COPY . .

# 6. Expose port 5000.
# This tells Docker to listen on this port at runtime. It's a form of documentation
# and allows for easier port mapping.
EXPOSE 5000

# 7. Define the command to run the application.
# This is the command that will be executed when the container starts.
# It's equivalent to running 'python app.py' in the terminal.
CMD ["python", "app.py"]
