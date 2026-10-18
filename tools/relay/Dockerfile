FROM python:3.11-slim
RUN pip install --no-cache-dir aiohttp==3.9.5
WORKDIR /app
COPY app.py .
EXPOSE 7860
CMD ["python", "app.py"]
