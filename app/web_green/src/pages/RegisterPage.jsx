import { useState } from "react";
import { useEffect } from "react";
import { apiFetch } from "../lib/api";
import { hrefFor, navigate } from "../lib/router";

export default function RegisterPage({ setUser, onNavigate }) {
  const [message, setMessage] = useState({ type: "", text: "" });

  useEffect(() => {
    document.title = "K-Glow Beauty | 회원가입";
  }, []);

  const submit = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const name = String(formData.get("name")).trim();
    const email = String(formData.get("email")).trim();
    const password = String(formData.get("password")).trim();
    const passwordConfirm = String(formData.get("passwordConfirm")).trim();

    if (!name || !email || !password) {
      setMessage({ type: "error", text: "이름, 이메일, 비밀번호를 모두 입력해주세요." });
      return;
    }

    if (password !== passwordConfirm) {
      setMessage({ type: "error", text: "비밀번호 확인이 일치하지 않습니다." });
      return;
    }

    try {
      const user = await apiFetch("/api/auth/register", {
        method: "POST",
        body: JSON.stringify({ name, email, password }),
      });
      setUser(user);
      setMessage({ type: "success", text: "회원가입이 완료되었습니다." });
      setTimeout(() => navigate(hrefFor("home")), 400);
    } catch (error) {
      console.warn("회원가입 API 호출 실패", error);
      setUser(null);
      setMessage({ type: "error", text: "회원가입에 실패했습니다. 세션 또는 WAS 상태를 확인해주세요." });
    }
  };

  return (
    <main className="form-shell">
      <h1>회원가입</h1>
      <p className="muted">K-GLOW BEAUTY 회원이 되어 맞춤 쇼핑을 시작하세요.</p>

      <form className="form" onSubmit={submit}>
        <div className="field">
          <label htmlFor="name">이름</label>
          <input id="name" name="name" type="text" placeholder="홍길동" autoComplete="name" />
        </div>
        <div className="field">
          <label htmlFor="email">이메일</label>
          <input id="email" name="email" type="email" placeholder="member@kbeauty.com" autoComplete="email" />
        </div>
        <div className="field">
          <label htmlFor="password">비밀번호</label>
          <input id="password" name="password" type="password" placeholder="비밀번호" autoComplete="new-password" />
        </div>
        <div className="field">
          <label htmlFor="passwordConfirm">비밀번호 확인</label>
          <input id="passwordConfirm" name="passwordConfirm" type="password" placeholder="비밀번호 확인" autoComplete="new-password" />
        </div>
        <button className="button primary" type="submit">
          가입하기
        </button>
        <a className="button secondary" href={hrefFor("login")} onClick={(event) => onNavigate(event, hrefFor("login"))}>
          로그인으로 돌아가기
        </a>
        <p className={`form-message ${message.type}`}>{message.text}</p>
      </form>
    </main>
  );
}
