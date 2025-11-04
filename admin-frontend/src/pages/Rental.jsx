
import React, { useState, useEffect } from "react";
import "../styles/Rental.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Rentals() {
  const [rentals, setRentals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState("pending");

  // ===== Fetch Rentals =====
  useEffect(() => {
    const fetchRentals = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          rentals {
            rentalId
            name
            brand
            location
            pricePerHour
            pricePerDay
            description
            quantity
            image
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
        const res = await fetch(GRAPHQL_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query }),
        });

        const result = await res.json();
        if (result.errors) setError(result.errors[0].message);
        else setRentals(result.data.rentals);
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchRentals();
  }, []);

  // ===== Update Status =====
  const handleApproval = async (rentalId, newStatus) => {
    const mutation = `
      mutation UpdateRentalStatus($rentalId: String!, $status: String!) {
        updateRentalStatus(rentalId: $rentalId, status: $status) {
          rentalId
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
          variables: { rentalId, status: newStatus },
        }),
      });

      const result = await res.json();
      if (result.errors) {
        alert(`Error updating rental: ${result.errors[0].message}`);
        return;
      }

      const updated = result.data.updateRentalStatus;
      setRentals((prev) =>
        prev.map((r) =>
          r.rentalId === updated.rentalId ? { ...r, status: updated.status } : r
        )
      );

      alert(`Rental ${newStatus} successfully!`);
    } catch (err) {
      alert(`Network error: ${err.message}`);
    }
  };

  if (loading) return <p className="rentals-loading">Loading rentals...</p>;
  if (error) return <p className="rentals-error">Error: {error}</p>;

  const filteredRentals = rentals.filter(
    (r) => r.status.toLowerCase() === selectedStatus
  );

  return (
    <div className="rentals-container">
      <h2 className="rentals-title">🚁 Rentals Approval Dashboard</h2>

      {/* ===== Tabs ===== */}
      <div className="rentals-status-tabs">
        {["pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={`rentals-tab ${
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

      {/* ===== Cards ===== */}
      <div className="rentals-grid">
        {filteredRentals.length === 0 ? (
          <p className="rentals-empty-text">
            No {selectedStatus} rentals available.
          </p>
        ) : (
          filteredRentals.map((rental) => (
            <div key={rental.rentalId} className="rental-card">
              <div className={`rental-badge ${rental.status.toLowerCase()}`}>
                {rental.status}
              </div>

              <div className="rental-image-wrapper">
                {rental.image ? (
                  <img
                    src={rental.image}
                    alt={rental.name}
                    className="rental-image"
                  />
                ) : (
                  <div className="rental-no-image">No Image</div>
                )}
              </div>

              <div className="rental-details">
                <h3>{rental.name}</h3>
                <p><strong>ID:</strong> {rental.rentalId}</p>
                <p><strong>Brand:</strong> {rental.brand}</p>
                <p><strong>Location:</strong> {rental.location}</p>
                <p><strong>Quantity:</strong> {rental.quantity}</p>
                <p><strong>Price/Hour:</strong> ₹{rental.pricePerHour}</p>
                <p><strong>Price/Day:</strong> ₹{rental.pricePerDay}</p>
                <p><strong>Description:</strong> {rental.description}</p>

                {rental.sellerInfo ? (
                  <>
                    <p><strong>Seller ID:</strong> {rental.sellerId}</p>
                    <p><strong>Phone:</strong> {rental.sellerInfo.phoneNumber}</p>
                    <p><strong>Email:</strong> {rental.sellerInfo.email}</p>
                  </>
                ) : (
                  <p><strong>Seller:</strong> Not available</p>
                )}

                {rental.status.toLowerCase() === "pending" && (
                  <div className="rental-actions">
                    <button
                      onClick={() =>
                        handleApproval(rental.rentalId, "approved")
                      }
                      className="rental-approve-btn"
                    >
                      ✅ Approve
                    </button>
                    <button
                      onClick={() =>
                        handleApproval(rental.rentalId, "rejected")
                      }
                      className="rental-reject-btn"
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

export default Rentals;
