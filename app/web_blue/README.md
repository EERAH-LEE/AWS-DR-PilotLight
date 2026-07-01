# K-Glow Beauty Web

K-Beauty 상품 쇼핑몰 프로젝트의 React 프론트엔드입니다. Vite, React, CSS로 구성되며 Spring Boot WAS API와 분리해서 배포할 수 있습니다.

## 주요 기능

- 상품 목록 조회, 검색, 카테고리 필터
- 상품 상세 화면
- 회원가입 및 로그인
- 로그인 세션 복원 및 로그아웃
- 로그인 사용자 전용 문의 작성/조회
- 마이페이지에서 사용자 정보와 문의 내역 확인
- 화면 상단에 WAS 서버 배포 정보 표시

## 기술 구성

- Vite
- React
- Vanilla CSS
- Font Awesome CDN

## 파일 구조

```text
final_pj_web/
├── index.html
├── package.json
├── vite.config.js
├── .env.example
├── assets/
│   └── app.css
├── public/
│   └── assets/img/product-fallback.svg
└── src/
    ├── main.jsx
    ├── components/
    │   ├── Footer.jsx
    │   ├── Header.jsx
    │   ├── ProductCard.jsx
    │   └── ServerInfoBar.jsx
    ├── lib/
    │   ├── api.js
    │   └── router.js
    └── pages/
        ├── DetailPage.jsx
        ├── HomePage.jsx
        ├── InquiryPage.jsx
        ├── LoginPage.jsx
        ├── Mypage.jsx
        └── RegisterPage.jsx
```

## 로컬 실행

```bash
npm install
npm run dev
```

기본 접속 주소:

```text
http://127.0.0.1:5173/
```

## WAS API 주소 설정

기본 API 주소는 `.env` 또는 브라우저 localStorage로 설정합니다.

```bash
VITE_API_BASE_URL=http://localhost:8080
```

브라우저에서 임시로 바꾸려면 개발자 도구 콘솔에서 실행합니다.

```javascript
localStorage.setItem("kbeautyApiBaseUrl", "http://localhost:8080")
```

## 배포 참고

- React 빌드 결과물은 `dist/`에 생성됩니다.
- 별도 웹 서버에서 배포할 때 `/api` 요청은 WAS로 프록시하거나, `VITE_API_BASE_URL`을 실제 WAS 주소로 설정합니다.
- `/login.html`, `/detail.html` 같은 경로를 직접 열 수 있도록 웹 서버의 SPA fallback을 `index.html`로 설정해야 합니다.
- 로그인 세션을 사용하므로 WAS의 CORS 설정과 쿠키 전달 설정이 프론트 도메인과 맞아야 합니다.
