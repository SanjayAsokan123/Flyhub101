    import React, { useEffect, useState } from "react";
    import "../styles/PilotBookingStatus.css";

    const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

    export default function PilotRentalBookings() {
      const [rentals, setRentals] = useState([]);
      const [loading, setLoading] = useState(true);
      const [error, setError] = useState(null);

      const [query, setQuery] = useState("");
      const [sortKey, setSortKey] = useState("newest");
      const [page, setPage] = useState(1);
      const PAGE_SIZE = 6;

      // ----------------------------------------------------------
      // 🔥 Fetch Pilot Rentals (NEW SCHEMA)
      // ----------------------------------------------------------
      const fetchRentals = async () => {
        setLoading(true);
        setError(null);

        const gql = `
          query {
            getAllPilotRentals {
              pilot_rental_id
              name
              email
              phone
              location
              amount
              status
              paymentStatus
              rentalDate
              rentalPeriod {
                startDate
                endDate
              }
              createdAt
              updatedAt
              pilot {
                pilotName
                pilotCompany
                phoneNumber
                email
              }
            }
          }
        `;

        try {
          const res = await fetch(GRAPHQL_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ query: gql }),
          });

          const json = await res.json();
          if (json.errors) {
            setError(json.errors[0].message);
            return;
          }

          setRentals(json.data.getAllPilotRentals || []);
        } catch (err) {
          setError("Network Error: " + err.message);
        }

        setLoading(false);
      };

      useEffect(() => {
        fetchRentals();
      }, []);

      // ----------------------------------------------------------
      // 🔍 Filter, Search, Sort
      // ----------------------------------------------------------
      const processed = rentals
        .filter((r) => {
          const q = query.toLowerCase();
          return (
            r.name.toLowerCase().includes(q) ||
            r.phone.toLowerCase().includes(q) ||
            r.location.toLowerCase().includes(q) ||
            r.status.toLowerCase().includes(q) ||
            r.paymentStatus.toLowerCase().includes(q) ||
            (r.pilot?.pilotName || "").toLowerCase().includes(q) ||
            (r.pilot?.pilotCompany || "").toLowerCase().includes(q)
          );
        })
        .sort((a, b) => {
          if (sortKey === "newest") return b.createdAt.localeCompare(a.createdAt);
          if (sortKey === "oldest") return a.createdAt.localeCompare(b.createdAt);
          if (sortKey === "pilot")
            return (a.pilot?.pilotName || "").localeCompare(
              b.pilot?.pilotName || ""
            );
          return 0;
        });

      const totalPages = Math.max(1, Math.ceil(processed.length / PAGE_SIZE));
      const visible = processed.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

      // ----------------------------------------------------------
      // UI Loading / Error
      // ----------------------------------------------------------
      if (loading) return <p className="buyer-loading">Loading rentals...</p>;
      if (error) return <p className="buyer-error">Error: {error}</p>;

      // ----------------------------------------------------------
      // JSX UI
      // ----------------------------------------------------------
      return (
        <div className="sold-root">
          {/* HEADER */}
          <header className="sold-header">
            <div>
              <h1 className="sold-title">Pilot Rentals</h1>
              <p className="sold-sub">Track all pilot rental bookings</p>
            </div>

            <div className="sold-actions">
              <input
                className="sold-search"
                placeholder="Search name, phone, pilot..."
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(1);
                }}
              />

              <select
                className="sold-select"
                value={sortKey}
                onChange={(e) => setSortKey(e.target.value)}
              >
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="pilot">Pilot Name</option>
              </select>

              <button className="sold-btn" onClick={fetchRentals}>
                Refresh
              </button>
            </div>
          </header>

          {/* LIST */}
          <main className="sold-list">
            {visible.length === 0 ? (
              <div className="sold-empty">No rentals found.</div>
            ) : (
              visible.map((r) => (
                <article key={r.pilot_rental_id} className="sold-item">
                  <div className="sold-item-left">
                    <div className="sold-item-title">
                      {r.pilot?.pilotName || "Unknown Pilot"} —{" "}
                      <span>{r.pilot?.pilotCompany || ""}</span>
                    </div>

                    <div className="sold-item-meta">
                      <strong>{r.name}</strong> • {r.location}
                    </div>

                    <div className="sold-item-meta small">📞 {r.phone}</div>

                    <div className="sold-item-meta small">
                      {r.rentalPeriod.startDate} → {r.rentalPeriod.endDate}
                    </div>

                    <div className="sold-item-meta small">
                      ₹ {r.amount} • Payment: {r.paymentStatus}
                    </div>
                  </div>

                  <div className="sold-item-right">
                    <div className="sold-item-date">{r.rentalDate}</div>

                    <div
                      className={`sold-item-status ${
                        r.status === "confirmed"
                          ? "green"
                          : r.status === "cancelled"
                          ? "red"
                          : "blue"
                      }`}
                    >
                      {r.status}
                    </div>
                  </div>
                </article>
              ))
            )}
          </main>

          {/* PAGINATION */}
          <footer className="sold-footer">
            <div>
              Showing <strong>{processed.length}</strong> rentals
            </div>

            <div className="sold-pages">
              <button
                className="sold-page-btn"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
              >
                Prev
              </button>

              <span className="sold-page-ind">
                {page} / {totalPages}
              </span>

              <button
                className="sold-page-btn"
                disabled={page === totalPages}
                onClick={() => setPage(page + 1)}
              >
                Next
              </button>
            </div>
          </footer>
        </div>
      );
    }
