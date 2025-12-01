import React, { useState } from "react";
import { gql, useQuery } from "@apollo/client";
import "../styles/DroneBookingStatus.css";

// GraphQL Query
const GET_DRONE_BOOKINGS = gql`
  query {
    getAllDroneRentals {
      drone_rental_id
      name
      phone
      location
      rentalId
      rentalDate
      sellerId
      status
      createdAt
    }
  }
`;

function DroneBookingStatus() {
  const { data, loading, error, refetch } = useQuery(GET_DRONE_BOOKINGS);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const bookings = data?.getAllDroneRentals || [];

  // Parse date safely (supports UNIX seconds, UNIX ms, ISO string)
  const parseDate = (value) => {
    if (!value) return null;

    const num = Number(value);

    // If numeric (timestamp)
    if (!isNaN(num)) {
      // UNIX timestamp in seconds
      if (num.toString().length === 10) {
        return new Date(num * 1000);
      }
      return new Date(num);
    }

    // If ISO string
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  };

  // Format date as "12 January 2025"
  const formatFullDate = (value) => {
    const date = parseDate(value);
    if (!date) return "—";

    return date.toLocaleDateString("en-US", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  };

  // Refresh handler
  const handleRefresh = async () => {
    setIsRefreshing(true);
    await refetch();
    setIsRefreshing(false);
  };

  // Map status to CSS class
  const getStatusClass = (status) =>
    ({
      pending: "dbs-pending",
      confirmed: "dbs-confirmed",
      cancelled: "dbs-cancelled",
    }[status] || "");

  if (loading)
    return <div className="dbs-empty">Loading drone bookings...</div>;

  if (error)
    return <div className="dbs-empty">Error: {error.message}</div>;

  return (
    <div className="dbs-root">
      <div className="dbs-header">
        <h1 className="dbs-title">Drone Booking Status</h1>

        <button
          className="dbs-btn"
          onClick={handleRefresh}
          disabled={isRefreshing}
        >
          {isRefreshing ? "Refreshing..." : "Refresh"}
        </button>
      </div>

      <div className="dbs-table-wrap">
        <table className="dbs-table">
          <thead>
            <tr>
              <th>Booking ID</th>
              <th>Customer Name</th>
              <th>Phone</th>
              <th>Location</th>
              <th>Rental ID</th>
              <th>Rental Date</th>
              <th>Seller ID</th>
              <th>Status</th>
              <th>Booked At</th>
            </tr>
          </thead>

          <tbody>
            {bookings.length === 0 ? (
              <tr>
                <td colSpan="9" className="dbs-empty">
                  No bookings found.
                </td>
              </tr>
            ) : (
              bookings.map((b) => (
                <tr key={b.drone_rental_id}>
                  <td>{b.drone_rental_id}</td>
                  <td>{b.name}</td>
                  <td>{b.phone?.trim() || "—"}</td>
                  <td>{b.location}</td>
                  <td>{b.rentalId || "—"}</td>
                  <td>{formatFullDate(b.rentalDate)}</td>
                  <td>{b.sellerId || "—"}</td>

                  <td>
                    <span
                      className={`dbs-badge ${getStatusClass(b.status)}`}
                    >
                      {b.status || "—"}
                    </span>
                  </td>

                  <td>{formatFullDate(b.createdAt)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default DroneBookingStatus;
