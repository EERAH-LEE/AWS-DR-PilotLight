import { useEffect, useMemo, useState } from "react";
import ProductCard from "../components/ProductCard";
import { apiFetch, toNumber } from "../lib/api";

export default function HomePage({ onNavigate }) {
  const [products, setProducts] = useState([]);
  const [status, setStatus] = useState("상품을 불러오는 중입니다...");
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");

  useEffect(() => {
    document.title = "K-Glow Beauty | K-뷰티 쇼핑몰";
    apiFetch("/api/products/all")
      .then((data) => {
        if (!Array.isArray(data)) {
          setError("상품 데이터 형식이 올바르지 않습니다.");
          return;
        }
        setProducts(data);
        setStatus(`${new Date().toLocaleString("ko-KR")} 기준`);
      })
      .catch((loadError) => {
        console.error("상품 API 연결 실패", loadError);
        setError("상품 데이터를 불러오지 못했습니다. Spring Boot WAS와 DB 연결을 확인해주세요.");
        setStatus("상품 API 연결 실패");
      });
  }, []);

  useEffect(() => {
    const onSearch = (event) => setSearch(String(event.detail || "").trim().toLowerCase());
    window.addEventListener("kbeauty:search", onSearch);
    return () => window.removeEventListener("kbeauty:search", onSearch);
  }, []);

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      const matchesSearch = `${product.brandName} ${product.productName}`.toLowerCase().includes(search);
      if (!matchesSearch) return false;
      if (filter === "best") return product.isGlobalBest === true;
      if (filter === "sale") return toNumber(product.discountRate) > 0;
      return true;
    });
  }, [filter, products, search]);

  return (
    <main>
      <section className="hero">
        <div className="hero-inner">
          <div className="hero-copy">
            <span className="eyebrow">Global Best</span>
            <h1>K-Beauty picks for every glow</h1>
            <p>스킨케어 베스트셀러부터 데일리 선케어까지, 지금 가장 많이 찾는 K-뷰티 상품을 빠르게 둘러보세요.</p>
            <a className="button primary" href="#products">
              상품 보기
            </a>
          </div>
          <div className="hero-image" role="img" aria-label="K-뷰티 제품과 메이크업 도구" />
        </div>
      </section>

      <section id="products" className="section">
        <div className="section-head">
          <div>
            <h2>글로벌 실시간 랭킹</h2>
            <p>지금 가장 많이 찾는 K-뷰티 베스트셀러를 만나보세요.</p>
          </div>
          <p>{status}</p>
        </div>

        <div className="filters" aria-label="상품 필터">
          <button className={`chip ${filter === "all" ? "is-active" : ""}`} type="button" onClick={() => setFilter("all")}>
            전체
          </button>
          <button className={`chip ${filter === "best" ? "is-active" : ""}`} type="button" onClick={() => setFilter("best")}>
            글로벌 베스트
          </button>
          <button className={`chip ${filter === "sale" ? "is-active" : ""}`} type="button" onClick={() => setFilter("sale")}>
            할인 상품
          </button>
        </div>

        <div className="product-grid">
          {error && <p className="error">{error}</p>}
          {!error && products.length === 0 && <p className="notice">상품을 불러오는 중입니다...</p>}
          {!error && products.length > 0 && filteredProducts.length === 0 && <p className="empty">조건에 맞는 상품이 없습니다.</p>}
          {!error &&
            filteredProducts.map((product, index) => (
              <ProductCard key={product.productId} product={product} index={index} onNavigate={onNavigate} />
            ))}
        </div>
      </section>

      <section className="benefit-band" aria-label="서비스 장점">
        <div className="benefits">
          <Benefit icon="fa-solid fa-server" title="빠른 상품 탐색" text="인기 상품을 한눈에 확인" />
          <Benefit icon="fa-solid fa-globe" title="글로벌 배송" text="전 세계 어디서든 편하게 주문" />
          <Benefit icon="fa-solid fa-shield-halved" title="간편한 회원 서비스" text="문의와 쇼핑 활동을 손쉽게 관리" />
        </div>
      </section>
    </main>
  );
}

function Benefit({ icon, title, text }) {
  return (
    <div className="benefit">
      <i className={icon} />
      <div>
        <strong>{title}</strong>
        <span>{text}</span>
      </div>
    </div>
  );
}
