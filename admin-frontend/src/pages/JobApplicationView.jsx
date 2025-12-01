import React, { useState } from "react";
import { gql } from "@apollo/client";
import { Query } from "@apollo/client/react/components";
import "../styles/JobApplicationView.css";

const GET_ALL_APPROVED_JOBS = gql`
  query GetAllApprovedJobs {
    getAllApprovedJobs {
      _id
      jobId
      jobName
      companyName
      jobType
      experience
      location
      salary
      description
      requirement
      email
      phoneNumber
      status
      sellerId
    }
  }
`;

const GET_JOB_APPLICATIONS = gql`
  query GetJobApplications($jobId: String!) {
    getJobApplications(jobId: $jobId) {
      _id
      jobId
      name
      email
      phoneNumber
      resumeUrl
      status
      createdAt
    }
  }
`;

export default function JobApplicationView() {
  const [expandedJob, setExpandedJob] = useState(null);

  const getStatusDisplay = (status) => {
    switch (status?.toLowerCase()) {
      case "pending":
        return { text: "Pending", class: "pending" };
      case "approved":
        return { text: "Approved", class: "approved" };
      case "rejected":
        return { text: "Rejected", class: "rejected" };
      case "hired":
        return { text: "Hired", class: "hired" };
      default:
        return { text: status || "Unknown", class: "unknown" };
    }
  };

  const convertToCSV = (data) => {
    if (!data || data.length === 0) return "";
    const headers = Object.keys(data[0]).filter(
      (key) => key !== "description" && key !== "requirement"
    );
    const csvRows = [
      headers.join(","),
      ...data.map((item) =>
        headers
          .map((header) => {
            let value = item[header];
            if (typeof value === "string") {
              value = value.replace(/"/g, '""');
              if (value.includes(",") || value.includes('"')) {
                value = `"${value}"`;
              }
            }
            return value;
          })
          .join(",")
      ),
    ];
    return csvRows.join("\n");
  };

  const downloadCSV = (csvData, filename) => {
    const blob = new Blob([csvData], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const exportAllToCSV = (jobs) => {
    const csv = convertToCSV(jobs);
    downloadCSV(csv, "approved_jobs.csv");
  };

  const exportCompanyToCSV = (companyName, jobs) => {
    const file = `${companyName.replace(/\s+/g, "_")}_jobs.csv`;
    downloadCSV(convertToCSV(jobs), file);
  };

  const exportApplicationsToCSV = (jobName, applications) => {
    const file = `${jobName.replace(/\s+/g, "_")}_applications.csv`;
    downloadCSV(convertToCSV(applications), file);
  };

  const handleJobExpand = (job) => {
    setExpandedJob(expandedJob?._id === job._id ? null : job);
  };

  return (
    <Query query={GET_ALL_APPROVED_JOBS}>
      {({ loading, error, data }) => {
        if (loading)
          return (
            <div className="job-app-container">
              <div className="loading">⏳ Loading approved jobs...</div>
            </div>
          );

        if (error)
          return (
            <div className="job-app-container">
              <div className="error">❌ Error: {error.message}</div>
            </div>
          );

        const jobs = data?.getAllApprovedJobs || [];
        const groupedJobs = jobs.reduce((acc, job) => {
          acc[job.companyName] = acc[job.companyName] || [];
          acc[job.companyName].push(job);
          return acc;
        }, {});

        return (
          <div className="job-app-container">
            <div className="header">
              <h1 className="title">💼 Approved Jobs & Applicants</h1>
              <div className="header-actions">
                <div className="stats">
                  <span className="stat-item">
                    <span className="stat-number">{jobs.length}</span>
                    <span className="stat-label">Total Jobs</span>
                  </span>

                  <span className="stat-item">
                    <span className="stat-number">
                      {Object.keys(groupedJobs).length}
                    </span>
                    <span className="stat-label">Companies</span>
                  </span>
                </div>

                <button
                  className="export-btn"
                  onClick={() => exportAllToCSV(jobs)}
                >
                  📥 Export All Jobs
                </button>
              </div>
            </div>

            {jobs.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">📭</div>
                <p>No approved jobs available.</p>
              </div>
            ) : (
              <div className="company-list">
                {Object.entries(groupedJobs).map(([company, companyJobs]) => (
                  <div className="company-section" key={company}>
                    <div className="company-header">
                      <div>
                        <h2 className="company-name">{company}</h2>
                        <span className="app-count">
                          {companyJobs.length} job
                          {companyJobs.length !== 1 ? "s" : ""}
                        </span>
                      </div>

                      <button
                        className="export-btn company-export"
                        onClick={() =>
                          exportCompanyToCSV(company, companyJobs)
                        }
                      >
                        📥 Export Jobs
                      </button>
                    </div>

                    <div className="table-container">
                      <table className="jobs-table">
                        <thead>
                          <tr>
                            <th>Job ID</th>
                            <th>Position</th>
                            <th>Type</th>
                            <th>Experience</th>
                            <th>Location</th>
                            <th>Salary</th>
                            <th>Status</th>
                            <th>Applicants</th>
                            <th>Contact</th>
                            <th>Action</th>
                          </tr>
                        </thead>

                        <tbody>
                          {companyJobs.map((job) => {
                            const isExpanded = expandedJob?._id === job._id;
                            const statusInfo = getStatusDisplay(job.status);

                            return (
                              <React.Fragment key={job._id}>
                                <tr className={isExpanded ? "expanded-row" : ""}>
                                  <td>{job.jobId}</td>
                                  <td className="job-title">{job.jobName}</td>
                                  <td>{job.jobType}</td>
                                  <td>{job.experience}</td>
                                  <td>{job.location}</td>
                                  <td>{job.salary}</td>

                                  <td>
                                    <span
                                      className={`status-badge ${statusInfo.class}`}
                                    >
                                      {statusInfo.text}
                                    </span>
                                  </td>

                                  <td>
                                    <span className="applicant-count">
                                      0 applicants
                                    </span>
                                  </td>

                                  <td>
                                    <div className="contact-info">
                                      <div className="contact-item">
                                        📧 {job.email}
                                      </div>
                                      <div className="contact-item">
                                        📱 {job.phoneNumber}
                                      </div>
                                    </div>
                                  </td>

                                  <td>
                                    <button
                                      className={`expand-btn ${
                                        isExpanded ? "active" : ""
                                      }`}
                                      onClick={() => handleJobExpand(job)}
                                    >
                                      {isExpanded ? "▼" : "▶"}
                                    </button>
                                  </td>
                                </tr>

                                {isExpanded && (
                                  <tr className="expanded-content-row">
                                    <td colSpan="10">
                                      <div className="job-details">
                                        <div className="detail-section">
                                          <h3>Job Description</h3>
                                          <p>{job.description}</p>
                                        </div>

                                        <div className="detail-section">
                                          <h3>Requirements</h3>
                                          <p>{job.requirement}</p>
                                        </div>

                                        <div className="applicants-section">
                                          <div className="applicants-header">
                                            <h3>Applicants</h3>
                                          </div>

                                          <Query
                                            query={GET_JOB_APPLICATIONS}
                                            variables={{ jobId: job._id }}
                                          >
                                            {({ loading, error, data }) => {
                                              if (loading)
                                                return (
                                                  <p className="loading-text">
                                                    Loading applicants...
                                                  </p>
                                                );

                                              const applications =
                                                data?.getJobApplications || [];

                                              return applications.length > 0 ? (
                                                <>
                                                  <button
                                                    className="export-btn small"
                                                    onClick={() =>
                                                      exportApplicationsToCSV(
                                                        job.jobName,
                                                        applications
                                                      )
                                                    }
                                                  >
                                                    📥 Export
                                                  </button>

                                                  <table className="applicants-table">
                                                    <thead>
                                                      <tr>
                                                        <th>Name</th>
                                                        <th>Email</th>
                                                        <th>Phone</th>
                                                        <th>Resume</th>
                                                        <th>Status</th>
                                                        <th>Applied Date</th>
                                                      </tr>
                                                    </thead>
                                                    <tbody>
                                                      {applications.map((app) => {
                                                        const appStatus =
                                                          getStatusDisplay(
                                                            app.status
                                                          );

                                                        return (
                                                          <tr key={app._id}>
                                                            <td>{app.name}</td>
                                                            <td>{app.email}</td>
                                                            <td>
                                                              {
                                                                app.phoneNumber
                                                              }
                                                            </td>

                                                            <td>
                                                              <a
                                                                href={
                                                                  app.resumeUrl
                                                                }
                                                                target="_blank"
                                                                rel="noopener noreferrer"
                                                                className="resume-link"
                                                              >
                                                                📄 View
                                                              </a>
                                                            </td>

                                                            <td>
                                                              <span
                                                                className={`status-badge ${appStatus.class}`}
                                                              >
                                                                {appStatus.text}
                                                              </span>
                                                            </td>

                                                            <td>
                                                              {new Date(
                                                                app.createdAt
                                                              ).toLocaleDateString()}
                                                            </td>
                                                          </tr>
                                                        );
                                                      })}
                                                    </tbody>
                                                  </table>
                                                </>
                                              ) : (
                                                <p className="no-applicants">
                                                  No applicants yet
                                                </p>
                                              );
                                            }}
                                          </Query>
                                        </div>
                                      </div>
                                    </td>
                                  </tr>
                                )}
                              </React.Fragment>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      }}
    </Query>
  );
}
