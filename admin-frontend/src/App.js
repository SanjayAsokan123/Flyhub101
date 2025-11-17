// src/App.js
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import Dashboard from "./components/Dashboard";
import Users from "./pages/Users";
import Reports from "./pages/Reports";
import Parts from "./pages/Parts";
import Accessories from "./pages/Accessories";
import Rejected from "./pages/Rejected";
import Services from "./pages/Service";
import Rentals from "./pages/Rental";
import HirePilot from "./pages/HirePilot";
import HireJob from "./pages/HireJob";
import Settings from "./pages/Settings";
import SellerApprovalPanel from "./pages/SellerApprovalPanel";
import Approved from "./pages/Approved";
import TrainingPage from "./pages/Training"; // ✅ Added Training Management Page
import "./App.css";

export default function App() {
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/users" element={<Users />} />
          <Route path="/reports" element={<Reports />} />
          <Route path="/parts" element={<Parts />} />
          <Route path="/accessories" element={<Accessories />} />
          <Route path="/services" element={<Services />} />
          <Route path="/rentals" element={<Rentals />} />
          <Route path="/rejected" element={<Rejected />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/pilot" element={<HirePilot />} />
          <Route path="/job" element={<HireJob />} />
          <Route path="/seller" element={<SellerApprovalPanel />} />
          <Route path="/approval" element={<Approved />} />
          <Route path="/training" element={<TrainingPage />} /> {/* ✅ New route added */}

          {/* ✅ Optional fallback route */}
          <Route
            path="*"
            element={
              <h2 style={{ padding: "2rem", textAlign: "center", color: "#d32f2f" }}>
                404 - Page Not Found
              </h2>
            }
          />
        </Routes>
      </Layout>
    </Router>
  );
}
