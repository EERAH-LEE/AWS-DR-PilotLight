import { useEffect, useState } from "react";
import { addStoredInquiry, apiFetch, formatDateTime, getStoredInquiries } from "../lib/api";

export default function InquiryPage({ user }) {
  const [inquiries, setInquiries] = useState([]);
  const [message, setMessage] = useState({ type: "", text: "" });

  useEffect(() => {
    document.title = "K-Glow Beauty | 문의 작성";
    apiFetch("/api/inquiries")
      .then(setInquiries)
      .catch((error) => {
        console.warn("문의 목록 API 연결 실패, 브라우저 저장소 목록을 표시합니다.", error);
        setInquiries(getStoredInquiries());
      });
  }, []);

  const submit = async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const formData = new FormData(form);
    const inquiry = {
      category: String(formData.get("category")).trim(),
      title: String(formData.get("title")).trim(),
      writer: String(formData.get("writer")).trim(),
      content: String(formData.get("content")).trim(),
      createdAt: new Date().toLocaleString("ko-KR"),
    };

    if (!inquiry.title || !inquiry.writer || !inquiry.content) {
      setMessage({ type: "error", text: "문의 제목, 작성자, 내용을 모두 입력해주세요." });
      return;
    }

    try {
      const savedInquiry = await apiFetch("/api/inquiries", {
        method: "POST",
        body: JSON.stringify(inquiry),
      });
      setInquiries((current) => [savedInquiry, ...current]);
    } catch (error) {
      console.warn("문의 API 연결 실패, 브라우저 저장소에 저장합니다.", error);
      setInquiries(addStoredInquiry(inquiry));
    }

    form.reset();
    setMessage({ type: "success", text: "문의가 등록되었습니다." });
  };

  return (
    <main className="form-shell">
      <h1>문의 작성</h1>
      <p className="muted">상품, 배송, 회원 서비스에 대해 궁금한 점을 남겨주세요.</p>

      <form className="form" onSubmit={submit}>
        <div className="field">
          <label htmlFor="category">문의 유형</label>
          <select id="category" name="category">
            <option value="상품 문의">상품 문의</option>
            <option value="배송 문의">배송 문의</option>
            <option value="회원 문의">회원 문의</option>
            <option value="기타 문의">기타 문의</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="title">제목</label>
          <input id="title" name="title" type="text" placeholder="문의 제목" />
        </div>
        <div className="field">
          <label htmlFor="writer">작성자</label>
          <input id="writer" name="writer" type="text" placeholder="작성자 이름" defaultValue={user?.name || ""} />
        </div>
        <div className="field">
          <label htmlFor="content">내용</label>
          <textarea id="content" name="content" placeholder="문의 내용을 입력해주세요." />
        </div>
        <button className="button primary" type="submit">
          문의 등록
        </button>
        <p className={`form-message ${message.type}`}>{message.text}</p>
      </form>

      <section aria-label="작성된 문의">
        <div className="section-head" style={{ marginTop: 42 }}>
          <h2>최근 문의</h2>
        </div>
        <InquiryList inquiries={inquiries} emptyText="아직 등록된 문의가 없습니다." />
      </section>
    </main>
  );
}

export function InquiryList({ inquiries, emptyText }) {
  if (!inquiries.length) {
    return (
      <div className="inquiry-list">
        <p className="empty">{emptyText}</p>
      </div>
    );
  }

  return (
    <div className="inquiry-list">
      {inquiries.map((item, index) => (
        <article className="inquiry-item" key={`${item.title}-${item.createdAt}-${index}`}>
          <strong>{item.title}</strong>
          <div className="inquiry-meta">
            {item.category} · {item.writer} · {formatDateTime(item.createdAt)}
          </div>
          <p className="muted">{item.content}</p>
        </article>
      ))}
    </div>
  );
}
