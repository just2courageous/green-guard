# 1) Use a small, secure Python base image
FROM python:3.12-slim

# 2) Set working directory inside the container
WORKDIR /app

# 3) Copy only dependency file first (enables layer caching)
COPY requirements.txt .

# 4) Install dependencies without cache (smaller image)
RUN pip install --no-cache-dir -r requirements.txt

# 5) Copy the rest of your source code
COPY . .

# 6) Expose the port your app listens on (documentational)
EXPOSE 8080

# 7) Set env (Environment) variables for predictable defaults
ENV PORT=8080 PYTHONUNBUFFERED=1

# 8) Start the server (Uvicorn = ASGI [Asynchronous Server Gateway Interface] server)
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
