import React, { useEffect, useState } from "react";
import { useQuery, gql } from "@apollo/client";
import "../styles/DroneBookingStatus.css";

// Correct GraphQL Query
const GET_DRONE_BOOKINGS = gql`
  query {
    getAllDroneRentals {
      drone_rental_id
      name
      phone
      location
      rentalId
      status
      createdAt
      drone {
        name
        brand
        image
      }
    }
  }
`;

function DroneBookingStatus() {
  const { data, loading, error, refetch } = useQuery(GET_DRONE_BOOKINGS);
  const [bookings, setBookings] = useState([]);

  useEffect(() => {
    if (data && data.getAllDroneRentals) {
      setBookings(data.getAllDroneRentals);
    }
  }, [data]);

  const handleRefresh = () => refetch();

  const formatDate = (dateValue) => {
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) return "—";
    return date.toLocaleString("en-US", {
      day: "numeric",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  if (loading) return <div className="dbs-loading">Loading drone bookings...</div>;
  if (error) return <div className="dbs-error">Error: {error.message}</div>;

  return (
    <div className="dbs-container">
      <div className="dbs-header">
        <h1>Drone Booking Status</h1>
        <button className="dbs-refresh-btn" onClick={handleRefresh}>
          Refresh
        </button>
      </div>

      <div className="dbs-table-wrapper">
        <table className="dbs-table">
          <thead>
            <tr>
              <th>Booking ID</th>
              <th>Customer Name</th>
              <th>Phone</th>
              <th>Location</th>
              <th>Drone Model</th>
              <th>Status</th>
              <th>Booked At</th>
            </tr>
          </thead>

          <tbody>
            {bookings.map((b) => (
              <tr key={b.drone_rental_id}>
                <td>{b.drone_rental_id}</td>
                <td>{b.name}</td>
                <td>{b.phone}</td>
                <td>{b.location}</td>
                <td>{b.drone?.name || "—"}</td>
                <td>
                  <span className={`status-badge status-${b.status}`}>
                    {b.status}
                  </span>
                </td>
                <td>{formatDate(b.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default DroneBookingStatus;
