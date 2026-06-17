import { useState } from "react";
import { useEffect } from "react";
import { apiFetch } from "../lib/api";
import { hrefFor, navigate } from "../lib/router";

export default function LoginPage({ setUser, onNavigate }) {
  const [message, setMessage] = useState({ type: "", text: "" });

  useEffect(() => {
    document.title = "K-Glow Beauty | 로그인";
  }, []);

  const submit = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const email = String(formData.get("email")).trim();
    const password = String(formData.get("password")).trim();

    if (!email || !password) {
      setMessage({ type: "error", text: "이메일과 비밀번호를 입력해주세요." });
      return;
    }

    try {
      const user = await apiFetch("/api/auth/login", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      });
      setUser(user);
      setMessage({ type: "success", text: "로그인되었습니다." });
      setTimeout(() => navigate(hrefFor("home")), 400);
    } catch (error) {
      console.warn("로그인 API 호출 실패", error);
      setUser(null);
      setMessage({ type: "error", text: "로그인에 실패했습니다. 세션 또는 WAS 상태를 확인해주세요." });
    }
  };

  return (
    <main className="form-shell">
      <h1>로그인</h1>
      <p className="muted">회원 전용 혜택과 문의 내역을 편하게 확인하세요.</p>

      <form className="form" onSubmit={submit}>
        <div className="field">
          <label htmlFor="email">이메일</label>
          <input id="email" name="email" type="email" placeholder="member@kbeauty.com" autoComplete="email" />
        </div>
        <div className="field">
          <label htmlFor="password">비밀번호</label>
          <input id="password" name="password" type="password" placeholder="비밀번호" autoComplete="current-password" />
        </div>
        <button className="button primary" type="submit">
          로그인
        </button>
        <a className="button secondary" href={hrefFor("register")} onClick={(event) => onNavigate(event, hrefFor("register"))}>
          회원가입
        </a>
        <p className={`form-message ${message.type}`}>{message.text}</p>
      </form>
    </main>
  );
}
