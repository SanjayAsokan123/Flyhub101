import React, { useState, useEffect } from "react";
import "../styles/Accessories.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Accessories() {
  const [accessories, setAccessories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState("pending");

  // ===== Fetch Accessories =====
  useEffect(() => {
    const fetchAccessories = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          accessories {
            accessoryId
            name
            brand
            category
            price
            description
            image
            quantity
            status
            sellerId
            sellerInfo {
              email
              phoneNumber
            }
          }
        }
      `;

      try {
        const response = await fetch(GRAPHQL_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query }),
        });

        const result = await response.json();
        if (result.errors) setError(result.errors[0].message);
        else setAccessories(result.data.accessories);
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchAccessories();
  }, []);

  // ===== Update Status =====
  const handleApproval = async (accessoryId, newStatus) => {
    const mutation = `
      mutation UpdateAccessoryStatus($accessoryId: String!, $status: String!) {
        updateAccessoryStatus(accessoryId: $accessoryId, status: $status) {
          accessoryId
          status
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: mutation,
          variables: { accessoryId, status: newStatus },
        }),
      });

      const result = await res.json();
      if (result.errors) {
        alert(`Error updating accessory: ${result.errors[0].message}`);
        return;
      }

      const updated = result.data.updateAccessoryStatus;
      setAccessories((prev) =>
        prev.map((a) =>
          a.accessoryId === updated.accessoryId
            ? { ...a, status: updated.status }
            : a
        )
      );
      alert(`Accessory ${newStatus} successfully!`);
    } catch (err) {
      alert(`Network error: ${err.message}`);
    }
  };

  if (loading) return <p className="accessories-loading">Loading accessories...</p>;
  if (error) return <p className="accessories-error">Error: {error}</p>;

  const filteredAccessories = accessories.filter(
    (a) => a.status.toLowerCase() === selectedStatus
  );

  return (
    <div className="accessories-container">
      <h2 className="accessories-title">🛒 Accessories Approval Dashboard</h2>

      {/* Status Tabs */}
      <div className="accessories-status-tabs">
        {["pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={`accessories-tab ${
              selectedStatus === status ? "active" : ""
            }`}
            onClick={() => setSelectedStatus(status)}
          >
            {status === "pending" && "⏳ Pending"}
            {status === "approved" && "✅ Approved"}
            {status === "rejected" && "❌ Rejected"}
          </button>
        ))}
      </div>

      {/* Accessories Cards */}
      <div className="accessories-grid">
        {filteredAccessories.length === 0 ? (
          <p className="accessories-empty-text">No {selectedStatus} accessories.</p>
        ) : (
          filteredAccessories.map((acc) => (
            <div key={acc.accessoryId} className="accessories-card">
              <div className={`accessories-badge ${acc.status.toLowerCase()}`}>
                {acc.status}
              </div>

              <div className="accessories-image-wrapper">
                {acc.image ? (
                  <img
                    src={acc.image}
                    alt={acc.name}
                    className="accessories-image"
                  />
                ) : (
                  <div className="accessories-no-image">No Image</div>
                )}
              </div>

              <div className="accessories-details">
                <h3>{acc.name}</h3>
                <p><strong>ID:</strong> {acc.accessoryId}</p>
                <p><strong>Brand:</strong> {acc.brand}</p>
                <p><strong>Price:</strong> ₹{acc.price}</p>
                <p><strong>Description:</strong> {acc.description}</p>

                {acc.sellerInfo ? (
                  <>
                    <p><strong>Seller ID:</strong> {acc.sellerId}</p>
                    <p><strong>Phone:</strong> {acc.sellerInfo.phoneNumber}</p>
                    <p><strong>Email:</strong> {acc.sellerInfo.email}</p>
                  </>
                ) : (
                  <p><strong>Seller:</strong> Not available</p>
                )}

                {acc.status.toLowerCase() === "pending" && (
                  <div className="accessories-actions">
                    <button
                      onClick={() =>
                        handleApproval(acc.accessoryId, "approved")
                      }
                      className="accessories-approve-btn"
                    >
                      ✅ Approve
                    </button>
                    <button
                      onClick={() =>
                        handleApproval(acc.accessoryId, "rejected")
                      }
                      className="accessories-reject-btn"
                    >
                      ❌ Reject
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default Accessories;