import React, { useState, useEffect } from "react";
import "../styles/Service.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Services() {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterStatus, setFilterStatus] = useState("all");

  useEffect(() => {
    const fetchServices = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          services {
            serviceId
            name
            specificDrone
            experience
            location
            description
            price
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
        if (result.errors) setError(result.errors[0].message);
        else setServices(result.data.services);
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchServices();
  }, []);

  const handleApproval = async (serviceId, status) => {
    const mutation = `
      mutation {
        updateServiceStatus(serviceId: "${serviceId}", status: "${status}") {
          serviceId
          status
        }
      }
    `;
    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: mutation }),
      });
      const result = await res.json();
      if (!result.errors) {
        setServices((prev) =>
          prev
            .map((s) => (s.serviceId === serviceId ? { ...s, status } : s))
            .filter((s) => s.status !== "rejected")
        );
      }
    } catch (err) {
      console.error(err);
    }
  };

  const filteredServices = services.filter((service) => {
    if (filterStatus === "all") return true;
    return service.status?.toLowerCase() === filterStatus;
  });

  if (loading) return <p>Loading services...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error}</p>;

  return (
    <div className="service">
      <h2>🛠 Services Approval Dashboard</h2>

      <div className="navbar">
        {["all", "pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={filterStatus === status ? "active" : ""}
            onClick={() => setFilterStatus(status)}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </button>
        ))}
      </div>

      <div className="service-cards">
        {filteredServices.length === 0 && <p>No services found for this status.</p>}
        {filteredServices.map((service) => (
          <div key={service.serviceId} className="service-card">
            <img src={service.image} alt={service.name} className="drone-image" />
            <h3>{service.name}</h3>
            <span className={`status-badge ${service.status?.toLowerCase()}`}>
              {service.status}
            </span>
            <p><strong>ID:</strong> {service.serviceId}</p>
            <p><strong>Drone:</strong> {service.specificDrone}</p>
            <p><strong>Experience:</strong> {service.experience} years</p>
            <p><strong>Location:</strong> {service.location}</p>
            <p><strong>Price:</strong> ${service.price}</p>
            <p><strong>Description:</strong> {service.description}</p>
            {service.sellerInfo && (
              <p><strong>Seller:</strong> {service.sellerInfo.email} | {service.sellerInfo.phoneNumber}</p>
            )}

            {service.status?.toLowerCase() === "pending" && (
              <div className="actions">
                <button className="approve" onClick={() => handleApproval(service.serviceId, "approved")}>✅ Approve</button>
                <button className="reject" onClick={() => handleApproval(service.serviceId, "rejected")}>❌ Reject</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default Services;
