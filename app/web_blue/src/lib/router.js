export function navigate(path) {
  window.history.pushState({}, "", path);
  window.dispatchEvent(new PopStateEvent("popstate"));
}

export function routeFromLocation() {
  const path = window.location.pathname.replace(/\/$/, "") || "/";
  if (path.endsWith("/detail.html") || path === "/detail") return "detail";
  if (path.endsWith("/login.html") || path === "/login") return "login";
  if (path.endsWith("/register.html") || path === "/register") return "register";
  if (path.endsWith("/inquiry.html") || path === "/inquiry") return "inquiry";
  if (path.endsWith("/mypage.html") || path === "/mypage") return "mypage";
  return "home";
}

export function hrefFor(page, search = "") {
  const names = {
    home: "/",
    detail: "/detail.html",
    login: "/login.html",
    register: "/register.html",
    inquiry: "/inquiry.html",
    mypage: "/mypage.html",
  };
  return `${names[page] || "/"}${search}`;
}
