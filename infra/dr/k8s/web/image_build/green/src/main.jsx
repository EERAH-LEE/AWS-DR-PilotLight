import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "../assets/app.css";
import { apiFetch, clearStoredUser } from "./lib/api";
import { hrefFor, navigate, routeFromLocation } from "./lib/router";
import Header from "./components/Header";
import ServerInfoBar from "./components/ServerInfoBar";
import Footer from "./components/Footer";
import HomePage from "./pages/HomePage";
import DetailPage from "./pages/DetailPage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import InquiryPage from "./pages/InquiryPage";
import Mypage from "./pages/Mypage";

class AppErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error("WEB 화면 렌더링 실패", error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <main className="page-shell">
          <div className="notice">
            화면을 표시하지 못했습니다. 브라우저 개발자 도구 Console과 Network 탭을 확인해주세요.
          </div>
        </main>
      );
    }

    return this.props.children;
  }
}

function App() {
  const [route, setRoute] = useState(routeFromLocation());
  const [user, setUser] = useState(null);

  useEffect(() => {
    const onPopState = () => setRoute(routeFromLocation());
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

  useEffect(() => {
    apiFetch("/api/auth/me")
      .then(setUser)
      .catch(() => {
        clearStoredUser();
        setUser(null);
      });
  }, []);

  const onNavigate = (event, path) => {
    event.preventDefault();
    navigate(path);
  };

  const logout = async () => {
    try {
      await apiFetch("/api/auth/logout", { method: "POST" });
    } catch (error) {
      console.warn("로그아웃 API 호출 실패, 브라우저 로그인 정보만 삭제합니다.", error);
    }
    clearStoredUser();
    setUser(null);
    navigate(hrefFor("home"));
  };

  const commonProps = { user, setUser, onNavigate, logout };
  const page = {
    home: <HomePage onNavigate={onNavigate} />,
    detail: <DetailPage user={user} onNavigate={onNavigate} />,
    login: <LoginPage setUser={setUser} logout={logout} onNavigate={onNavigate} />,
    register: <RegisterPage setUser={setUser} onNavigate={onNavigate} />,
    inquiry: <InquiryPage user={user} />,
    mypage: <Mypage user={user} setUser={setUser} logout={logout} onNavigate={onNavigate} />,
  }[route];

  return (
    <>
      <ServerInfoBar />
      <Header {...commonProps} searchable={route === "home"} />
      {page}
      <Footer route={route} />
    </>
  );
}

createRoot(document.getElementById("root")).render(
  <AppErrorBoundary>
    <App />
  </AppErrorBoundary>
);
