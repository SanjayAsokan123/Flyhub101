import React, { useState } from "react";
import "../styles/PilotBookingStatus.css";

export default function PilotBookingStatus() {
  const [bookings, setBookings] = useState(sampleData());
  const [query, setQuery] = useState("");
  const [showForm, setShowForm] = useState(false);

  const [form, setForm] = useState({
    pilot: "",
    customer: "",
    droneType: "",
    price: "",
    status: "Confirmed",
    date: new Date().toISOString().slice(0, 10),
  });

  const [sortKey, setSortKey] = useState("date-newest");
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 6;

  /* ---------- Sample Data ---------- */
  function sampleData() {
    return [
      {
        id: gid(),
        pilot: "Rahul Verma",
        customer: "Asha R",
        droneType: "Quadcopter",
        price: 3500,
        status: "Confirmed",
        date: "2025-02-14",
      },
      {
        id: gid(),
        pilot: "Kiran M",
        customer: "Vikram P",
        droneType: "Hexacopter",
        price: 5000,
        status: "Completed",
        date: "2025-03-11",
      },
      {
        id: gid(),
        pilot: "Sanjay Rao",
        customer: "Priya K",
        droneType: "Mini Drone",
        price: 1800,
        status: "Cancelled",
        date: "2025-01-25",
      },
      {
        id: gid(),
        pilot: "Vinod S",
        customer: "Rohit G",
        droneType: "FPV Drone",
        price: 4200,
        status: "Upcoming",
        date: "2025-04-03",
      },
    ];
  }

  function gid() {
    return Math.random().toString(36).slice(2, 9);
  }

  /* ---------- Add Booking ---------- */
  function onSubmit(e) {
    e.preventDefault();

    if (!form.pilot.trim() || !form.customer.trim() || !form.price) {
      alert("Please fill pilot, customer and price.");
      return;
    }

    const newItem = {
      id: gid(),
      pilot: form.pilot.trim(),
      customer: form.customer.trim(),
      droneType: form.droneType.trim(),
      price: Number(form.price),
      status: form.status,
      date: form.date,
    };

    setBookings((b) => [newItem, ...b]);
    setShowForm(false);
  }

  /* ---------- CSV Export ---------- */
  function exportCSV() {
    const rows = bookings.map((b) => [
      b.pilot,
      b.customer,
      b.droneType,
      b.price,
      b.status,
      b.date,
    ]);

    const header = ["Pilot", "Customer", "Drone Type", "Price", "Status", "Date"];

    const csv = [header, ...rows].map((r) => r.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = `pilot-booking-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  /* ---------- Search + Sort ---------- */
  function filtered() {
    const q = query.trim().toLowerCase();

    let out = bookings.filter((b) => {
      if (!q) return true;

      return (
        b.pilot.toLowerCase().includes(q) ||
        b.customer.toLowerCase().includes(q) ||
        b.droneType.toLowerCase().includes(q) ||
        b.status.toLowerCase().includes(q) ||
        String(b.price).includes(q) ||
        b.date.includes(q)
      );
    });

    out.sort((a, b) => {
      if (sortKey === "date-newest") return b.date.localeCompare(a.date);
      if (sortKey === "date-oldest") return a.date.localeCompare(b.date);
      if (sortKey === "price") return b.price - a.price;
      if (sortKey === "pilot") return a.pilot.localeCompare(b.pilot);
      return 0;
    });

    return out;
  }

  const list = filtered();
  const totalPages = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
  const visible = list.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  /* ---------- UI ---------- */
  return (
    <div className="sold-root">
      {/* Header */}
      <header className="sold-header">
        <div>
          <h1 className="sold-title">Pilot Booking Status</h1>
          <p className="sold-sub">Manage and track all drone pilot bookings.</p>
        </div>

        <div className="sold-actions">
          <input
            className="sold-search"
            placeholder="Search pilot, customer, status..."
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
            <option value="date-newest">Newest First</option>
            <option value="date-oldest">Oldest First</option>
            <option value="price">Highest Price</option>
            <option value="pilot">Pilot Name</option>
          </select>

          <button className="sold-btn" onClick={() => setShowForm(!showForm)}>
            {showForm ? "Close Form" : "Add Booking"}
          </button>

          <button className="sold-btn ghost" onClick={exportCSV}>
            Export CSV
          </button>
        </div>
      </header>

      {/* Form */}
      {showForm && (
        <form className="sold-form" onSubmit={onSubmit}>
          <div className="sold-field">
            <label>Pilot Name</label>
            <input
              value={form.pilot}
              onChange={(e) => setForm({ ...form, pilot: e.target.value })}
            />
          </div>

          <div className="sold-field">
            <label>Customer Name</label>
            <input
              value={form.customer}
              onChange={(e) => setForm({ ...form, customer: e.target.value })}
            />
          </div>

          <div className="sold-field">
            <label>Drone Type</label>
            <input
              value={form.droneType}
              onChange={(e) => setForm({ ...form, droneType: e.target.value })}
            />
          </div>

          <div className="sold-row">
            <div className="sold-field small">
              <label>Price (₹)</label>
              <input
                type="number"
                value={form.price}
                onChange={(e) => setForm({ ...form, price: e.target.value })}
              />
            </div>

            <div className="sold-field small">
              <label>Status</label>
              <select
                value={form.status}
                onChange={(e) => setForm({ ...form, status: e.target.value })}
              >
                <option>Confirmed</option>
                <option>Upcoming</option>
                <option>Completed</option>
                <option>Cancelled</option>
              </select>
            </div>

            <div className="sold-field small">
              <label>Date</label>
              <input
                type="date"
                value={form.date}
                onChange={(e) => setForm({ ...form, date: e.target.value })}
              />
            </div>
          </div>

          <div className="sold-form-actions">
            <button className="sold-btn">Save</button>
            <button
              type="button"
              className="sold-btn ghost"
              onClick={() => setShowForm(false)}
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* List */}
      <main className="sold-list">
        {visible.length === 0 && (
          <div className="sold-empty">No bookings found.</div>
        )}

        {visible.map((b) => (
          <article key={b.id} className="sold-item">
            <div className="sold-item-left">
              <div className="sold-item-title">
                {b.pilot} — <span>{b.droneType}</span>
              </div>
              <div className="sold-item-meta">
                Customer: <strong>{b.customer}</strong> • ₹{b.price}
              </div>
            </div>

            <div className="sold-item-right">
              <div className="sold-item-date">{b.date}</div>
              <div
                className={`sold-item-status ${
                  b.status.toLowerCase() === "completed"
                    ? "green"
                    : b.status.toLowerCase() === "cancelled"
                    ? "red"
                    : "blue"
                }`}
              >
                {b.status}
              </div>
            </div>
          </article>
        ))}
      </main>

      {/* Pagination */}
      <footer className="sold-footer">
        <div>
          Showing <strong>{list.length}</strong> bookings
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
