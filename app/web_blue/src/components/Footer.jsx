export default function Footer({ route }) {
  const labels = {
    home: "Curated K-Beauty Store",
    detail: "Product Detail",
    login: "Login",
    register: "Register",
    inquiry: "Inquiry",
    mypage: "My Page",
  };

  return (
    <footer className="footer">
      <div className="footer-inner">K-GLOW BEAUTY · {labels[route] || labels.home}</div>
    </footer>
  );
}
