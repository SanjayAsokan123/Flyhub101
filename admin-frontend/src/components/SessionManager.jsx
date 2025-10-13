import React, { useEffect, useState, useCallback } from "react";
import { jwtDecode } from "jwt-decode";
import { gql, useMutation } from "@apollo/client";

const REFRESH_TOKEN = gql`
  mutation RefreshAdminToken($refreshToken: String!) {
    refreshAdminToken(refreshToken: $refreshToken) {
      success
      token
    }
  }
`;

export default function SessionManager() {
  const [showWarning, setShowWarning] = useState(false);
  const [refreshAdminToken] = useMutation(REFRESH_TOKEN);

  // ✅ Wrap in useCallback so React doesn't re-create it every render
  const handleTokenRefresh = useCallback(async () => {
    const refreshToken = localStorage.getItem("refreshToken");
    if (!refreshToken) {
      handleLogout();
      return;
    }

    try {
      const { data } = await refreshAdminToken({ variables: { refreshToken } });
      if (data.refreshAdminToken.success) {
        localStorage.setItem("accessToken", data.refreshAdminToken.token);
        setShowWarning(false);
        console.log("✅ Token auto-refreshed successfully");
      } else {
        console.warn("❌ Refresh failed — logging out");
        handleLogout();
      }
    } catch (err) {
      console.error("❌ Token refresh error:", err.message);
      handleLogout();
    }
  }, [refreshAdminToken]); // ✅ stable dependency

  const handleLogout = () => {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    window.location.href = "/login";
  };

  useEffect(() => {
    const checkSession = () => {
      const token = localStorage.getItem("accessToken");
      if (!token) return;

      try {
        const decoded = jwtDecode(token);
        const currentTime = Date.now() / 1000;
        const remaining = decoded.exp - currentTime;

        if (remaining <= 60 && remaining > 0) {
          setShowWarning(true);
        } else if (remaining <= 0) {
          handleTokenRefresh();
        }
      } catch (err) {
        console.error("Session check failed:", err.message);
      }
    };

    const interval = setInterval(checkSession, 10000);
    return () => clearInterval(interval);
  }, [handleTokenRefresh]); // ✅ clean dependency

  return (
    showWarning && (
      <div style={styles.overlay}>
        <div style={styles.modal}>
          <h3>Session Expiring Soon</h3>
          <p>Your session will expire in less than a minute.</p>
          <div style={styles.buttons}>
            <button onClick={handleTokenRefresh} style={styles.refresh}>
              🔄 Refresh Now
            </button>
            <button onClick={handleLogout} style={styles.logout}>
              🚪 Logout
            </button>
          </div>
        </div>
      </div>
    )
  );
}

const styles = {
  overlay: {
    position: "fixed",
    top: 0,
    left: 0,
    width: "100vw",
    height: "100vh",
    background: "rgba(0,0,0,0.6)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 9999,
  },
  modal: {
    background: "white",
    padding: "30px",
    borderRadius: "12px",
    width: "350px",
    textAlign: "center",
    boxShadow: "0 4px 15px rgba(0,0,0,0.2)",
  },
  buttons: {
    marginTop: "15px",
    display: "flex",
    justifyContent: "space-around",
  },
  refresh: {
    background: "#10b981",
    color: "white",
    border: "none",
    padding: "8px 14px",
    borderRadius: "6px",
    cursor: "pointer",
  },
  logout: {
    background: "#ef4444",
    color: "white",
    border: "none",
    padding: "8px 14px",
    borderRadius: "6px",
    cursor: "pointer",
  },
};
