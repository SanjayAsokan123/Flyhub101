import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Layout from "./components/Layout";
import Dashboard from "./components/Dashboard";
import Login from "./pages/Login";
import Users from "./pages/Users";
import Reports from "./pages/Reports";
import Parts from "./pages/Parts";
import Accessories from "./pages/Accessories";
import Rejected from "./pages/Rejected";
import Settings from "./pages/Settings";
import "./App.css";

export default function App() {
  const isLoggedIn = !!localStorage.getItem("accessToken");

  return (
    <Router>
      <Routes>
        {/* ✅ Redirect root to login if not logged in */}
        <Route
          path="/"
          element={isLoggedIn ? <Layout><Dashboard /></Layout> : <Navigate to="/login" />}
        />

        {/* ✅ Protected Routes (only if logged in) */}
        {isLoggedIn && (
          <>
            <Route
              path="/users"
              element={
                <Layout>
                  <Users />
                </Layout>
              }
            />
            <Route
              path="/reports"
              element={
                <Layout>
                  <Reports />
                </Layout>
              }
            />
            <Route
              path="/parts"
              element={
                <Layout>
                  <Parts />
                </Layout>
              }
            />
            <Route
              path="/accessories"
              element={
                <Layout>
                  <Accessories />
                </Layout>
              }
            />
            <Route
              path="/rejected"
              element={
                <Layout>
                  <Rejected />
                </Layout>
              }
            />
            <Route
              path="/settings"
              element={
                <Layout>
                  <Settings />
                </Layout>
              }
            />
          </>
        )}

        {/* ✅ Always allow login route */}
        <Route
          path="/login"
          element={isLoggedIn ? <Navigate to="/" /> : <Login />}
        />

        {/* ✅ Catch-all for invalid routes */}
        <Route
          path="*"
          element={<Navigate to={isLoggedIn ? "/" : "/login"} />}
        />
      </Routes>
    </Router>
  );
}
