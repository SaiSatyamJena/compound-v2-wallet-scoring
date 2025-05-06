# Dockerfile (place in the project root: zeru-compound-scoring/Dockerfile)

# Start from a lean Python base image. Using Python 3.10 here, but 3.9+ is fine.
FROM python:3.10-slim

# Set the working directory inside the container. All subsequent commands run relative to this path.
WORKDIR /workspace

# Set environment variables to prevent Python from writing pyc files and buffering stdout/stderr.
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Optional: Install system dependencies if any Python libraries require them.
# For pandas, numpy, scikit-learn, typically none are needed on standard Debian/Ubuntu based images.
# RUN apt-get update && apt-get install -y --no-install-recommends some-package && rm -rf /var/lib/apt/lists/*

# Copy the requirements file first. This leverages Docker's layer caching.
# If requirements.txt doesn't change, Docker won't need to reinstall dependencies on subsequent builds.
COPY requirements.txt .

# Install the Python dependencies specified in requirements.txt.
# --no-cache-dir reduces image size. --upgrade pip ensures the latest pip is used.
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container's working directory.
# This line should ideally be after installing dependencies to optimize caching.
# Since you'll be mounting the code via devcontainer.json, this isn't strictly necessary
# for development, but good practice for building standalone images later.
COPY . /workspace/

# Expose the port Jupyter Notebook will run on. This needs to match the port forwarded in devcontainer.json.
EXPOSE 8888

# Optional: Default command to run when the container starts.
# VS Code often manages the command itself when launching the dev container,
# but this can be useful for running the container standalone.
# Starts Jupyter allowing connections from any IP within the container, on the exposed port, without launching a browser.
# CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--notebook-dir=/workspace"]