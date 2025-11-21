import React, { useState, useEffect } from "react";
import "../styles/Parts.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Parts() {
  const [parts, setParts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState("pending");

  // Fetch parts
  const fetchParts = async () => {
    setLoading(true);
    setError(null);

    const query = `
      query GetParts {
        parts {
          partId
          name
          brand
          price
          description
          image
          quantity
          status
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });

      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);

      const result = await res.json();

      if (result.errors) {
        setError(result.errors[0].message);
        setParts([]);
        return;
      }

      setParts(result.data.parts);
    } catch (err) {
      setError("Network error: " + err.message);
      setParts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchParts();
  }, []);

  // Approve or reject part
  const handleApproval = async (partId, newStatus) => {
    const mutation = `
      mutation UpdatePartStatus($partId: String!, $status: String!) {
        updatePartStatus(partId: $partId, status: $status) {
          partId
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
          variables: { partId, status: newStatus },
        }),
      });

      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);

      const result = await res.json();

      if (result.errors) {
        alert(`Error updating part: ${result.errors[0].message}`);
        return;
      }

      const updatedPart = result.data.updatePartStatus;

      setParts((prev) =>
        prev.map((p) =>
          p.partId === updatedPart.partId
            ? { ...p, status: updatedPart.status }
            : p
        )
      );

      alert(`Part ${newStatus} successfully!`);
    } catch (err) {
      alert(`Network error: ${err.message}`);
    }
  };

  if (loading) return <p className="loading">Loading parts...</p>;
  if (error) return <p className="error">Error: {error}</p>;

  const filteredParts = parts.filter(
    (p) => p.status.toLowerCase() === selectedStatus
  );

  return (
    <div className="parts-container">
      <h2 className="page-title">🛠 Parts Management Dashboard</h2>

      {/* Tabs */}
      <div className="status-tabs">
        {["pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={`status-tab ${
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

      {/* Parts Grid */}
      <div className="parts-grid">
        {filteredParts.length === 0 ? (
          <p className="empty-text">No {selectedStatus} parts.</p>
        ) : (
          filteredParts.map((part) => (
            <div key={part.partId} className="part-card">
              {/* Status Badge */}
              <div
                className={`status-badge-top ${part.status.toLowerCase()}`}
              >
                {part.status}
              </div>

              {/* Image */}
              <div className="part-image-wrapper">
                {part.image ? (
                  <img
                    src={part.image}
                    alt={part.name}
                    className="part-image"
                  />
                ) : (
                  <div className="part-image placeholder">No Image</div>
                )}
              </div>

              {/* Details */}
              <div className="part-details">
                <h3>{part.name}</h3>
                <p>
                  <strong>ID:</strong> {part.partId}
                </p>
                <p>
                  <strong>Brand:</strong> {part.brand}
                </p>
                <p>
                  <strong>Price:</strong> ₹{part.price}
                </p>
                <p>
                  <strong>Quantity:</strong> {part.quantity}
                </p>
                <p>
                  <strong>Description:</strong> {part.description}
                </p>

                {/* Actions */}
                <div className="actions">
                  {part.status !== "approved" && (
                    <button
                      onClick={() =>
                        handleApproval(part.partId, "approved")
                      }
                      className="approve-btn"
                    >
                      ✅ Approve
                    </button>
                  )}

                  {part.status !== "rejected" && (
                    <button
                      onClick={() =>
                        handleApproval(part.partId, "rejected")
                      }
                      className="reject-btn"
                    >
                      ❌ Reject
                    </button>
                  )}

                  {part.status !== "pending" && (
                    <button
                      onClick={() =>
                        handleApproval(part.partId, "pending")
                      }
                      className="reset-btn"
                    >
                      🔄 Move to Pending
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default Parts;
