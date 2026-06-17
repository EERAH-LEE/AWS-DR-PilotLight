import { useEffect, useMemo, useState } from "react";
import { apiFetch, getStoredInquiries } from "../lib/api";
import { hrefFor } from "../lib/router";
import { InquiryList } from "./InquiryPage";

export default function Mypage({ user, setUser, logout, onNavigate }) {
  const [currentUser, setCurrentUser] = useState(user);
  const [inquiries, setInquiries] = useState([]);

  useEffect(() => {
    document.title = "K-Glow Beauty | 마이페이지";
    apiFetch("/api/auth/me")
      .then((nextUser) => {
        setUser(nextUser);
        setCurrentUser(nextUser);
      })
      .catch(() => {
        setUser(null);
        setCurrentUser(null);
      });
  }, [setUser]);

  useEffect(() => {
    if (!currentUser) {
      setInquiries([]);
      return;
    }

    apiFetch("/api/inquiries")
      .then(setInquiries)
      .catch(() => setInquiries(getStoredInquiries()));
  }, [currentUser]);

  const myInquiries = useMemo(() => {
    if (!currentUser) return [];
    return inquiries.filter((item) => item.writer === currentUser.name || item.writer === currentUser.email);
  }, [currentUser, inquiries]);

  return (
    <main className="form-shell">
      <h1>마이페이지</h1>
      <p className="muted">회원 정보와 문의 내역을 확인하세요.</p>

      <section style={{ marginTop: 28 }}>
        {!currentUser ? (
          <div className="notice">
            로그인이 필요합니다.
            <div style={{ marginTop: 14 }}>
              <a className="button primary" href={hrefFor("login")} onClick={(event) => onNavigate(event, hrefFor("login"))}>
                로그인
              </a>
            </div>
          </div>
        ) : (
          <div className="notice" style={{ textAlign: "left" }}>
            <strong style={{ fontSize: 20 }}>{currentUser.name}</strong>
            <p className="muted" style={{ marginTop: 8 }}>
              {currentUser.email}
            </p>
            <div style={{ marginTop: 18 }}>
              <button className="button secondary" type="button" onClick={logout}>
                로그아웃
              </button>
            </div>
          </div>
        )}
      </section>

      <section aria-label="내 문의">
        <div className="section-head" style={{ marginTop: 42 }}>
          <div>
            <h2>내 문의</h2>
            <p className="muted">최근 작성한 문의를 확인할 수 있습니다.</p>
          </div>
          {currentUser && (
            <a className="button secondary" href={hrefFor("inquiry")} onClick={(event) => onNavigate(event, hrefFor("inquiry"))}>
              문의 작성
            </a>
          )}
        </div>
        <InquiryList inquiries={myInquiries} emptyText="작성한 문의가 없습니다." />
      </section>
    </main>
  );
}
