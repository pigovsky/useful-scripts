FROM python:3.11-slim

RUN apt-get update && apt-get install -y openssh-client && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies before copying the rest of the files to take advantage of Docker caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code and other files
COPY src/ src/
COPY .kinder-bot.pigovsky.com/ .kinder-bot.pigovsky.com/

# Setting python path so that kinder_bot package is available
ENV PYTHONPATH="${PYTHONPATH}:/app/src"

CMD ["python", "src/kinder_bot/bot.py"]
