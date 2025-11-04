import React, { useState, useEffect } from "react";
import "../styles/HireJob.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function HireJobsDashboard() {
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterStatus, setFilterStatus] = useState("all");

  useEffect(() => {
    const fetchJobs = async () => {
      setLoading(true);
      setError(null);

      const query = `
        query {
          jobs {
            jobId
            jobName
            companyName
            jobType
            experience
            location
            salary
            description
            requirement
            status
            sellerId
            email
            phoneNumber
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
        else setJobs(result.data.jobs);
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchJobs();
  }, []);

  const handleApproval = async (jobId, status) => {
    const mutation = `
      mutation {
        updateStatus(jobId: "${jobId}", status: "${status}") {
          jobId
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
        setJobs((prev) =>
          prev.map((job) =>
            job.jobId === jobId ? { ...job, status } : job
          )
        );
      }
    } catch (err) {
      console.error("Error updating job status:", err);
    }
  };

  const filteredJobs = jobs.filter((job) => {
    if (filterStatus === "all") return true;
    return job.status?.toLowerCase() === filterStatus;
  });

  if (loading) return <p className="loading">Loading jobs...</p>;
  if (error) return <p className="error">Error: {error}</p>;

  return (
    <div className="hire-jobs-container">
      <h2 className="page-title">💼 Hire Jobs Dashboard</h2>

      <div className="status-tabs">
        {["all", "pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={`status-tab ${filterStatus === status ? "active" : ""}`}
            onClick={() => setFilterStatus(status)}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </button>
        ))}
      </div>

      <div className="jobs-grid">
        {filteredJobs.length === 0 && (
          <p className="empty-text">No jobs found for this status.</p>
        )}
        {filteredJobs.map((job) => (
          <div key={job.jobId} className="job-card">
            <div className={`status-badge ${job.status?.toLowerCase()}`}>
              {job.status}
            </div>

            <div className="job-details">
              <h3>{job.jobName}</h3>
              <p><strong>Company:</strong> {job.companyName}</p>
              <p><strong>Type:</strong> {job.jobType}</p>
              <p><strong>Experience:</strong> {job.experience}</p>
              <p><strong>Location:</strong> {job.location}</p>
              <p><strong>Salary:</strong> {job.salary}</p>
              <p><strong>Description:</strong> {job.description}</p>
              <p><strong>Requirement:</strong> {job.requirement}</p>
              <p><strong>Email:</strong> {job.email}</p>
              <p><strong>Phone:</strong> {job.phoneNumber}</p>
            </div>

            {job.status?.toLowerCase() === "pending" && (
              <div className="actions">
                <button
                  className="approve-btn"
                  onClick={() => handleApproval(job.jobId, "approved")}
                >
                  ✅ Approve
                </button>
                <button
                  className="reject-btn"
                  onClick={() => handleApproval(job.jobId, "rejected")}
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

export default HireJobsDashboard;