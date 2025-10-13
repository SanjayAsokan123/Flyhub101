import React, { useState, useEffect } from "react";
import "../styles/Page.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql"; // Your Apollo GraphQL endpoint

function Users() {
  const [drones, setDrones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch drones from backend GraphQL API
  useEffect(() => {
    const fetchDrones = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          drones {
            id
            name
            brand
            uin
            price
            description
            image
            status
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

        if (result.errors) {
          setError(result.errors[0].message);
          console.error("GraphQL errors:", result.errors);
        } else {
          // Filter out rejected drones so they only appear in Rejected page
          const rejectedDrones = JSON.parse(localStorage.getItem("rejectedDrones")) || [];
          const filteredDrones = result.data.drones.filter(
            (drone) => !rejectedDrones.some((d) => d.id === drone.id)
          );

          setDrones(filteredDrones);
        }
      } catch (err) {
        setError("Network error: " + err.message);
        console.error("Fetch error:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchDrones();
  }, []);

  // Approve or reject drone via GraphQL mutation
  const handleApproval = async (id, status) => {
    const mutation = `
      mutation {
        updateDroneStatus(id: "${id}", status: "${status}") {
          id
          name
          brand
          uin
          price
          description
          image
          status
        }
      }
    `;

    try {
      const response = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: mutation }),
      });

      const result = await response.json();

      if (result.errors) {
        console.error("GraphQL errors:", result.errors);
      } else {
        const updatedDrone = result.data.updateDroneStatus;

        // Update drones in state
        setDrones((prev) =>
          prev.map((drone) =>
            drone.id === id ? { ...drone, status: updatedDrone.status } : drone
          ).filter(drone => drone.status !== "rejected") // remove rejected from dashboard
        );

        // If rejected, store in localStorage
        if (status === "rejected") {
          const storedRejected = JSON.parse(localStorage.getItem("rejectedDrones")) || [];
          // Avoid duplicates
          if (!storedRejected.find((d) => d.id === updatedDrone.id)) {
            storedRejected.push(updatedDrone);
            localStorage.setItem("rejectedDrones", JSON.stringify(storedRejected));
          }
        }
      }
    } catch (err) {
      console.error("Error updating drone status:", err);
    }
  };

  if (loading) return <p>Loading drones...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error}</p>;

  return (
    <div className="page">
      <h2>🛸 Drone Approval Dashboard</h2>
      <div className="drone-cards">
        {drones.length === 0 && <p>No drones to approve.</p>}
        {drones.map((drone) => (
          <div key={drone.id} className="drone-card">
            <img src={drone.image} alt={drone.name} className="drone-image" />
            <h3>{drone.name}</h3>
            <p><strong>Brand:</strong> {drone.brand}</p>
            <p><strong>UIN Number:</strong> {drone.uin}</p>
            <p><strong>Price:</strong> ${drone.price}</p>
            <p><strong>Description:</strong> {drone.description}</p>
            <p><strong>Status:</strong> {drone.status}</p>

            {drone.status.toLowerCase() === "pending" && (
              <div className="actions">
                <button onClick={() => handleApproval(drone.id, "approved")}>
                  ✅ Approve
                </button>
                <button onClick={() => handleApproval(drone.id, "rejected")}>
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

export default Users;