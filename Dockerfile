FROM python:3.9.13

RUN apt-get update && apt-get install -y \
    libzbar0 \
    && apt-get clean

# 작업 경로 설정
WORKDIR /app

# 의존성 복사 및 설치ㅇ
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# API 폴더 복사
COPY API ./API

# Flask 서버 실행
CMD ["python", "API/app.py"]
