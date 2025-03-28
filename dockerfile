FROM python:3.9.13

WORKDIR /API

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "API/app.py", "--host", "0,0,0,0", "--port", "9064"]