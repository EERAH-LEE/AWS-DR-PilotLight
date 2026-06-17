import { hrefFor } from "../lib/router";

export default function Header({ user, searchable, onNavigate, logout }) {
  return (
    <header className="site-header">
      <nav className="nav" aria-label="주요 메뉴">
        <a className="brand" href={hrefFor("home")} onClick={(event) => onNavigate(event, hrefFor("home"))}>
          K-GLOW <span>BEAUTY</span>
        </a>
        {searchable ? (
          <form
            className="search"
            onSubmit={(event) => {
              event.preventDefault();
              window.dispatchEvent(new CustomEvent("kbeauty:search", { detail: event.currentTarget.search.value }));
            }}
          >
            <input name="search" type="search" placeholder="브랜드 또는 상품명 검색" />
            <button type="submit" aria-label="검색">
              <i className="fa-solid fa-magnifying-glass" />
            </button>
          </form>
        ) : (
          <div className="search">
            <input type="search" placeholder="상품명 또는 브랜드 검색" disabled />
            <button type="button" aria-label="검색">
              <i className="fa-solid fa-magnifying-glass" />
            </button>
          </div>
        )}
        <div className="nav-actions">
          <a
            className="icon-link"
            href={user ? hrefFor("mypage") : hrefFor("login")}
            title={user ? "마이페이지" : "로그인"}
            onClick={(event) => onNavigate(event, user ? hrefFor("mypage") : hrefFor("login"))}
          >
            <i className="fa-regular fa-user" />
            <span>{user ? user.name : "로그인"}</span>
          </a>
          {user && (
            <>
              <a
                className="icon-link"
                href={hrefFor("inquiry")}
                title="문의"
                onClick={(event) => onNavigate(event, hrefFor("inquiry"))}
              >
                <i className="fa-regular fa-pen-to-square" />
                <span>문의</span>
              </a>
              <button className="icon-link" type="button" title="로그아웃" onClick={logout}>
                <i className="fa-solid fa-arrow-right-from-bracket" />
                <span>로그아웃</span>
              </button>
            </>
          )}
        </div>
      </nav>
    </header>
  );
}
