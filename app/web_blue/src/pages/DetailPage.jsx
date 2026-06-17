import { useEffect, useState } from "react";
import { apiFetch, formatWon, getCurrentPrice, PRODUCT_IMAGE_FALLBACK, toNumber } from "../lib/api";
import { hrefFor } from "../lib/router";

export default function DetailPage({ user, onNavigate }) {
  const [detail, setDetail] = useState(null);
  const [error, setError] = useState("");
  const productId = new URLSearchParams(window.location.search).get("id");

  useEffect(() => {
    if (!productId) {
      setError("상품 ID가 없습니다. 메인에서 상품을 선택해주세요.");
      return;
    }

    apiFetch(`/api/products/${encodeURIComponent(productId)}`)
      .then((data) => {
        setDetail(data);
        if (data?.product?.productName) {
          document.title = `${data.product.productName} | K-Glow Beauty`;
        }
      })
      .catch((loadError) => {
        console.error("상세 API 연결 실패", loadError);
        setError("상품 상세 데이터를 불러오지 못했습니다. Spring Boot WAS와 DB 연결을 확인해주세요.");
      });
  }, [productId]);

  if (error) {
    return (
      <main className="page-shell">
        <p className="error">{error}</p>
      </main>
    );
  }

  if (!detail) {
    return (
      <main className="page-shell">
        <p className="notice">상품 상세 정보를 불러오는 중입니다...</p>
      </main>
    );
  }

  const product = detail.product;
  const images = detail.imges || detail.images || [];
  const discountRate = toNumber(product.discountRate);

  return (
    <main className="page-shell">
      <section className="detail-layout">
        <div className="detail-image">
          <img
            src={product.mainImageUrl || PRODUCT_IMAGE_FALLBACK}
            alt={product.productName}
            onError={(event) => {
              event.currentTarget.src = PRODUCT_IMAGE_FALLBACK;
            }}
          />
        </div>
        <div>
          <a className="detail-brand" href={hrefFor("home")} onClick={(event) => onNavigate(event, hrefFor("home"))}>
            {product.brandName}
          </a>
          <h1 className="detail-title">{product.productName}</h1>
          <p className="subtitle">{product.subTitle || ""}</p>
          <div className="rating">
            <i className="fa-solid fa-star" />
            <i className="fa-solid fa-star" />
            <i className="fa-solid fa-star" />
            <i className="fa-solid fa-star" />
            <i className="fa-solid fa-star-half-stroke" />
            <span>12,402건 리뷰</span>
          </div>
          <div className="detail-price">
            {discountRate > 0 && <span className="discount">{discountRate}%</span>}
            <span className="price">{formatWon(getCurrentPrice(product))}</span>
            {discountRate > 0 && <span className="original">{formatWon(product.originalPrice)}</span>}
          </div>
          <div className="badges">
            <span className="badge">무료배송</span>
            <span className="badge">증정 이벤트</span>
            <span className="badge">글로벌 베스트</span>
          </div>
          <div className="info-callout">피부 컨디션에 맞춰 매일 부담 없이 사용할 수 있는 데일리 케어 아이템입니다.</div>
          <div className="action-row">
            {user && (
              <a className="button secondary" href={hrefFor("inquiry")} onClick={(event) => onNavigate(event, hrefFor("inquiry"))}>
                상품 문의
              </a>
            )}
            <button className="button primary" type="button">
              구매하기
            </button>
          </div>
        </div>
      </section>

      <nav className="detail-tabs" aria-label="상세 탭">
        <a className="is-active" href="#details">
          상세정보
        </a>
        <a href="#reviews">리뷰</a>
        {user && (
          <a href={hrefFor("inquiry")} onClick={(event) => onNavigate(event, hrefFor("inquiry"))}>
            Q&amp;A
          </a>
        )}
      </nav>

      <section id="details" className="detail-content">
        <h2>{product.subTitle || product.productName}</h2>
        <p className="muted">성분, 사용감, 추천 루틴을 자세히 확인해보세요.</p>
        <div className="detail-images">
          {images.length === 0 && <p className="empty">등록된 상세 이미지가 없습니다.</p>}
          {images.map((url) => (
            <img
              key={url}
              src={url}
              alt={`${product.productName} 상세 이미지`}
              loading="lazy"
              onError={(event) => {
                event.currentTarget.src = PRODUCT_IMAGE_FALLBACK;
              }}
            />
          ))}
        </div>
      </section>
    </main>
  );
}
