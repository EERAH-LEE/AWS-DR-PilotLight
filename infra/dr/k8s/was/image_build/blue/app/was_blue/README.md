# K-Beauty WAS

K-Beauty 상품 쇼핑몰 프로젝트의 백엔드 WAS입니다. Spring Boot 내장 Tomcat 서버로 실행되며, 프론트엔드에서 사용하는 상품 API, 로그인/회원가입 API, 문의 API, 서버 배포 정보 API를 제공합니다.

## 주요 기능

- 상품 목록 조회
- 상품 상세 조회
- 회원가입
- 로그인 세션 생성
- 현재 로그인 사용자 조회
- 로그아웃
- 문의 작성 및 조회
- 서버 배포 정보 조회
  - Host Name
  - Server IP
  - Load Balancer Header
  - Azure Availability Zone
  - DB Host

## 기술 구성

- Java 17
- Spring Boot 4.0.5
- Spring Web MVC
- Spring Data JPA
- Spring JDBC
- MyBatis starter
- MySQL Connector/J
- H2 Database
- Lombok
- Maven Wrapper

## API 목록

| Method | Path | 설명 |
| --- | --- | --- |
| `GET` | `/api/products/all` | 전체 상품 목록 조회 |
| `GET` | `/api/products/{id}` | 상품 상세 조회 |
| `POST` | `/api/auth/register` | 회원가입 |
| `POST` | `/api/auth/login` | 로그인 |
| `GET` | `/api/auth/me` | 현재 로그인 사용자 조회 |
| `POST` | `/api/auth/logout` | 로그아웃 |
| `GET` | `/api/inquiries` | 문의 목록 조회 |
| `POST` | `/api/inquiries` | 문의 작성 |
| `GET` | `/api/server-info` | 서버 및 DB 배포 정보 조회 |

## 파일 구조

```text
final_pj_was/
├── pom.xml
├── mvnw
├── src/main/java/com/kbeauty/myapp/
│   ├── KbeautyApplication.java
│   ├── config/
│   │   ├── CorsConfig.java
│   │   └── LocalDataSeeder.java
│   ├── controller/
│   │   ├── AuthApiController.java
│   │   ├── InquiryApiController.java
│   │   ├── ProductApiController.java
│   │   └── ServerInfoController.java
│   ├── entity/
│   │   ├── DTO.java
│   │   ├── Inquiry.java
│   │   ├── Member.java
│   │   ├── Product.java
│   │   └── ProductDetail.java
│   ├── repository/
│   └── service/
└── src/main/resources/
    ├── application.properties
    ├── application-local.properties
    └── db/
        └── seed-products.sql
```

## 로컬 실행

로컬에서는 H2 인메모리 DB를 사용하는 `local` 프로필로 실행합니다.

```bash
cd final_pj_was
SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run
```

로컬 API 주소는 아래와 같습니다.

```text
http://127.0.0.1:8080
```

H2 콘솔은 local 프로필에서 아래 경로로 접근할 수 있습니다.

```text
http://127.0.0.1:8080/h2-console
```

## 빌드

```bash
cd final_pj_was
./mvnw -DskipTests package
```

빌드 결과물은 아래 파일로 생성됩니다.

```text
target/kbeauty-app.jar
```

실행 예시는 아래와 같습니다.

```bash
java -jar target/kbeauty-app.jar
```

## DB 초기 데이터

클라우드 MySQL DB에 상품 초기값을 넣을 때는 아래 SQL 파일을 사용합니다.

```text
src/main/resources/db/seed-products.sql
```

이 파일에는 16개 상품과 상품 상세 데이터가 포함되어 있습니다.

## 설정 파일

- `application.properties`
  - 클라우드 MySQL 연결 설정
  - 기본 WAS 실행 설정
- `application-local.properties`
  - 로컬 H2 DB 설정
  - H2 콘솔 설정
  - 로컬 개발용 `create-drop` 설정

## 배포 전 확인 사항

- DB 주소, 사용자명, 비밀번호는 운영 환경에서 환경 변수로 분리하는 것을 권장합니다.
- `CorsConfig`의 허용 Origin은 실제 프론트엔드 도메인으로 제한하는 것을 권장합니다.
- 클라우드 DB에는 `seed-products.sql`을 1회 실행해서 상품 초기 데이터를 넣습니다.
- 로그인 기능은 학습/프로젝트용 단순 세션 방식입니다. 운영 서비스에서는 비밀번호 암호화와 보안 설정을 강화해야 합니다.
