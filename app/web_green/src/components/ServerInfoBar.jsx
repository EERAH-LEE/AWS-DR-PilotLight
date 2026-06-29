import { useEffect, useState } from "react";
import { apiFetch, getApiBaseUrl } from "../lib/api";

export default function ServerInfoBar() {
  const [info, setInfo] = useState(null);
  const [sessionCheck, setSessionCheck] = useState({
    running: false,
    total: 0,
    success: 0,
    failure: 0,
    message: "로그인 후 확인 가능",
  });

  useEffect(() => {
    const fallback = {
      cloudProvider: "Unknown",
      cloudZone: "N/A",
      hostName: window.location.hostname || "local-file",
      serverIp: "확인 중",
      dbHost: "확인 중",
    };

    apiFetch("/api/server-info")
      .then((nextInfo) => setInfo({ ...fallback, ...nextInfo }))
      .catch((error) => {
        console.warn("서버 배포 정보 API 연결 실패, 기본 정보를 표시합니다.", error);
        setInfo(fallback);
      });
  }, []);

  const runSessionCheck = async () => {
    setSessionCheck({
      running: true,
      total: 0,
      success: 0,
      failure: 0,
      message: "확인 중",
    });

    let success = 0;
    let failure = 0;

    for (let index = 0; index < 12; index += 1) {
      try {
        const response = await fetch(`${getApiBaseUrl()}/api/auth/me`, {
          credentials: "include",
        });

        if (response.ok) {
          success += 1;
        } else {
          failure += 1;
        }
      } catch {
        failure += 1;
      }

      setSessionCheck({
        running: true,
        total: index + 1,
        success,
        failure,
        message: "확인 중",
      });
    }

    const kept = failure === 0 && success > 0;
    setSessionCheck({
      running: false,
      total: 12,
      success,
      failure,
      message: kept ? "세션 유지됨" : "세션 끊김 감지",
    });
  };

  if (!info) return null;

  return (
    <div className="server-info">
      <div className="server-info-inner">
        <InfoItem label="Cloud" value={info.cloudProvider} />
        <InfoItem label="Host Name" value={info.hostName} />
        <InfoItem label="Server IP" value={info.serverIp} />
        <InfoItem label="Region / Zone" value={info.cloudZone || info.azureZone} />
        <InfoItem label="DB Host" value={info.dbHost} />
        <div className="server-info-item session-check">
          <strong>Session</strong>
          <div>
            <span className="session-summary">
              {sessionCheck.message} ({sessionCheck.success}/{sessionCheck.total || 12} 성공
              {sessionCheck.failure ? `, 실패 ${sessionCheck.failure}` : ""})
            </span>
            <button type="button" onClick={runSessionCheck} disabled={sessionCheck.running}>
              {sessionCheck.running ? "확인 중" : "세션 확인"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function InfoItem({ label, value }) {
  return (
    <div className="server-info-item">
      <strong>{label}</strong>
      <span title={value}>{value}</span>
    </div>
  );
}
