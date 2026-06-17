import { formatWon, getCurrentPrice, PRODUCT_IMAGE_FALLBACK, toNumber } from "../lib/api";
import { hrefFor } from "../lib/router";

export default function ProductCard({ product, index, onNavigate }) {
  const discountRate = toNumber(product.discountRate);
  const originalPrice = toNumber(product.originalPrice);
  const currentPrice = getCurrentPrice(product);

  return (
    <a
      className="product-card"
      href={hrefFor("detail", `?id=${encodeURIComponent(product.productId)}`)}
      onClick={(event) => onNavigate(event, hrefFor("detail", `?id=${encodeURIComponent(product.productId)}`))}
    >
      <div className="product-media">
        <img
          src={product.mainImageUrl || PRODUCT_IMAGE_FALLBACK}
          alt={product.productName}
          loading="lazy"
          onError={(event) => {
            event.currentTarget.src = PRODUCT_IMAGE_FALLBACK;
          }}
        />
        <span className={`rank ${index < 3 ? "top" : ""}`}>{index + 1}위</span>
      </div>
      <p className="product-brand">{product.brandName}</p>
      <h3 className="product-name">{product.productName}</h3>
      <div className="price-row">
        {discountRate > 0 && <span className="discount">{discountRate}%</span>}
        <span className="price">{formatWon(currentPrice)}</span>
        {discountRate > 0 && <span className="original">{formatWon(originalPrice)}</span>}
      </div>
    </a>
  );
}
