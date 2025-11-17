import { gql } from "apollo-server-express";

export const hirePilotTypeDefs = gql`
  # ============================================================
  # 🧩 CORE TYPES
  # ============================================================

  """ Represents pilot price structure (hourly/daily) """
  type Price {
    perHour: Float
    perDay: Float
  }

  """ Certification document URL """
  type Certification {
    url: String!
  }

  """ File resource (e.g., resume or license) """
  type File {
    url: String!
  }

  """ Hire Pilot entity with seller info and statuses """
  type HirePilot {
    pilotId: String
    pilotName: String
    pilotCompany: String
    location: String
    sellerId: ID
    availability: Boolean
    specification: String
    price: Price
    certifications: [Certification]
    resume: File
    description: String
    newemail: String
    newphoneNumber: String
    adminStatus: String
    buyerStatus: String
    seller: Seller
  }

  # ============================================================
  # 🧾 INPUTS
  # ============================================================

  """ Input structure for pilot pricing """
  input PriceInput {
    perHour: Float
    perDay: Float
  }

  """ Input for pilot certifications """
  input CertificationInput {
    url: String!
  }

  """ Input for pilot documents """
  input FileInput {
    url: String!
  }

  """ Input for creating or updating pilot listing """
  input HirePilotInput {
    pilotName: String!
    pilotCompany: String
    location: String
    newemail: String!
    newphoneNumber: String!
    sellerId: ID!
    availability: Boolean
    specification: String
    price: PriceInput!
    certifications: [CertificationInput]
    resume: FileInput
    description: String
  }

  # ============================================================
  # 📘 BOOKING TYPES
  # ============================================================

  """ Represents a buyer's pilot booking record """
  type PilotBooking {
    id: ID!
    pilotId: ID!
    buyerName: String!
    buyerEmail: String
    contact: String!
    location: String!
    date: String!
    startTime: String!
    endTime: String!
    status: String
    createdAt: String
    updatedAt: String
  }

  """ Input structure for booking a pilot """
  input BookPilotInput {
    pilotId: ID!
    buyerName: String!
    buyerEmail: String
    contact: String!
    location: String!
    date: String!
    startTime: String!
    endTime: String!
  }

  """ Response after booking a pilot """
  type BookPilotResponse {
    success: Boolean!
    message: String!
    booking: PilotBooking
  }

  # ============================================================
  # 📡 REAL-TIME SUBSCRIPTIONS
  # ============================================================

  """ Real-time event payload for new pilot bookings """
  type NewPilotBooking {
    bookingId: ID!
    pilotId: String!
    buyerName: String!
    date: String!
    startTime: String!
    endTime: String!
  }

  """ Event payload for pilot status change (approval/reject) """
  type HirePilotStatusChange {
    pilotId: String!
    pilotName: String!
    adminStatus: String!
    sellerId: ID!
  }

  # ✅ Note: Descriptions not allowed above 'extend type', use comments instead
  extend type Subscription {
    # Triggered whenever a pilot is booked
    newPilotBooking: NewPilotBooking

    # Triggered whenever a pilot’s admin approval status changes
    hirePilotStatusChanged: HirePilotStatusChange
  }

  # ============================================================
  # 📊 QUERIES
  # ============================================================

  extend type Query {
    """ Fetch all hire pilot listings (with seller info) """
    hirePilots: [HirePilot]

    """ Fetch a specific pilot by pilotId """
    hirePilot(pilotId: String!): HirePilot

    """ Fetch pilots created by a specific seller """
    hirePilotsBySeller(sellerId: String!): [HirePilot]

    """ Fetch pilots filtered by admin approval status """
    hirePilotsByStatus(adminStatus: String!): [HirePilot]

    """ Fetch all approved pilots (for public pilot page) """
    approvedHirePilotsByStatus: [HirePilot]

    """ Admin-based filters by approval status """
    adminRejectedHirePilots: [HirePilot!]
    adminApprovedHirePilots: [HirePilot!]
    adminPendingHirePilots: [HirePilot!]

    """ Buyer-based filters (for booking flow) """
    buyerRejectedHirePilots(pilotId: String!): [HirePilot!]
    buyerApprovedHirePilots(pilotId: String!): [HirePilot!]
    buyerPendingHirePilots(pilotId: String!): [HirePilot!]
    buyerCompletedHirePilots(pilotId: String!): [HirePilot!]

    """ Get all bookings made by a specific buyer """
    myPilotBookings(buyerEmail: String!): [PilotBooking!]

    """ Get all bookings received for a specific pilot """
    pilotBookings(pilotId: ID!): [PilotBooking!]
  }

  # ============================================================
  # ⚙️ MUTATIONS
  # ============================================================

  extend type Mutation {
    """ Add a new hire pilot listing """
    addHirePilot(input: HirePilotInput!): HirePilot

    """ Update pilot information """
    updateHirePilot(pilotId: String!, input: HirePilotInput!): HirePilot

    """ Book a pilot for a specific date and time """
    bookPilot(input: BookPilotInput!): BookPilotResponse!

    """ Admin updates pilot approval status (approve/reject) """
    adminUpdateHirePilotStatus(pilotId: String!, adminStatus: String!): HirePilot

    """ Buyer updates pilot booking status (confirm/cancel/complete) """
    buyerUpdateHirePilotStatus(pilotId: String!, buyerStatus: String!): HirePilot

    """ Delete a pilot listing """
    deleteHirePilot(pilotId: String!): HirePilot
  }
`;
