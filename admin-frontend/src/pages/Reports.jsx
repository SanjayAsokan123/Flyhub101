import React, { useState, useEffect } from "react";
import "../styles/Reports.css"; // ✅ New CSS file

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Reports() {
  const [reports, setReports] = useState([]);
  const [filteredReports, setFilteredReports] = useState([]);
  const [statusFilter, setStatusFilter] = useState("pending");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchReports = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          drones {
            uin
            name
            brand
            price
            description
            image
            status
            sellerInfo { email phoneNumber }
          }
        }
      `;

      try {
        const res = await fetch(GRAPHQL_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query }),
        });

        const result = await res.json();
        if (result.errors) {
          setError(result.errors[0].message);
        } else {
          const allReports = result.data.drones || [];
          setReports(allReports);
          setFilteredReports(
            allReports.filter((r) => r.status.toLowerCase() === "pending")
          );
        }
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchReports();
  }, []);

  // Filter reports by status
  const handleFilterChange = (status) => {
    setStatusFilter(status);
    setFilteredReports(
      reports.filter((r) => r.status.toLowerCase() === status.toLowerCase())
    );
  };

  // Approve / Reject handler
  const handleStatusUpdate = async (uin, status) => {
    const mutation = `
      mutation {
        updateDroneStatus(uin: "${uin}", status: "${status}") {
          uin
          status
        }
      }
    `;

    try {
      await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: mutation }),
      });

      // Update UI locally
      setReports((prev) =>
        prev.map((r) => (r.uin === uin ? { ...r, status } : r))
      );
      setFilteredReports((prev) => prev.filter((r) => r.uin !== uin));
    } catch (err) {
      console.error("Error updating status:", err);
    }
  };

  if (loading) return <p>Loading reports...</p>;
  if (error) return <p style={{ color: "red" }}>{error}</p>;

  return (
    <div className="reports">
      <h2>📊 Reports Dashboard</h2>

      {/* ===== Filter Buttons ===== */}
      <div className="filter-buttons">
        <button
          className={statusFilter === "approved" ? "active" : ""}
          onClick={() => handleFilterChange("approved")}
        >
          ✅ Approved
        </button>
        <button
          className={statusFilter === "pending" ? "active" : ""}
          onClick={() => handleFilterChange("pending")}
        >
          🕒 Pending
        </button>
        <button
          className={statusFilter === "rejected" ? "active" : ""}
          onClick={() => handleFilterChange("rejected")}
        >
          ❌ Rejected
        </button>
      </div>

      {/* ===== Reports Cards ===== */}
      <div className="reports-cards">
        {filteredReports.length === 0 && <p>No reports in this category.</p>}
        {filteredReports.map((report) => (
          <div key={report.uin} className="report-card">
            <img
              src={report.image}
              alt={report.name}
              className="report-image"
            />
            <h3>{report.name}</h3>
            <p>
              <strong>Brand:</strong> {report.brand}
            </p>
            <p>
              <strong>Price:</strong> ₹{report.price}
            </p>
            <p>
              <strong>Description:</strong> {report.description}
            </p>
            <p>
              <strong>Status:</strong> {report.status}
            </p>

            {report.sellerInfo ? (
              <>
                <p>
                  <strong>Email:</strong> {report.sellerInfo.email}
                </p>
                <p>
                  <strong>Phone:</strong> {report.sellerInfo.phoneNumber}
                </p>
              </>
            ) : (
              <p>
                <strong>Seller:</strong> Not available
              </p>
            )}

            {report.status.toLowerCase() === "pending" && (
              <div className="actions">
                <button
                  onClick={() => handleStatusUpdate(report.uin, "approved")}
                >
                  ✅ Approve
                </button>
                <button
                  onClick={() => handleStatusUpdate(report.uin, "rejected")}
                >
                  ❌ Reject
                </button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default Reports;