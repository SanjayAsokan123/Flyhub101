import { gql } from "apollo-server-express";

export const dronerentalBookingTypeDefs = gql`

  # -------------------------
  # Embedded Period
  # -------------------------
  type RentalPeriod {
    startDate: String
    endDate: String
  }

  input RentalPeriodInput {
    startDate: String!
    endDate: String!
  }

  # -------------------------
  # Lightweight Drone Info
  # -------------------------
  type DroneLight {
    rentalId: String
    name: String
    brand: String
    location: String
    pricePerHour: Float
    pricePerDay: Float
    description: String
    image: String
    quantity: Int
    insurance: Boolean
    with_pilot: Boolean
    available_today: Boolean
    sellerId: String
  }

  # -------------------------
  # Drone Rental Booking Type
  # -------------------------
  type DroneRental {
    drone_rental_id: String!
    rentalId: String          # <- nullable to avoid errors
    name: String!
    email: String
    phone: String!
    location: String!
    amount: Float
    rentalDate: String!
    rentalPeriod: RentalPeriod
    status: String!
    paymentStatus: String!
    createdAt: String!
    updatedAt: String!
    drone: DroneLight
    sellerEmail: String
    sellerPhone: String
  }

  # -------------------------
  # Queries
  # -------------------------
  type Query {
    getAllDroneRentals: [DroneRental!]!
    getDroneRentalsByStatus(status: String!): [DroneRental!]!
    getDroneRentalsByPaymentStatus(paymentStatus: String!): [DroneRental!]!
    getDroneRentalById(drone_rental_id: String!): DroneRental

    getPendingDroneRentals: [DroneRental!]!
    getConfirmedDroneRentals: [DroneRental!]!
    getCancelledDroneRentals: [DroneRental!]!
    getCompletedDronePaymentRentals: [DroneRental!]!
  }

  # -------------------------
  # Mutations
  # -------------------------
  type Mutation {

    createDroneRental(
      name: String!
      email: String!
      phone: String!
      location: String!
      amount: Float!
      rentalDate: String!
      rentalPeriod: RentalPeriodInput!
      rentalId: String!
    ): DroneRental!

    updateDroneRentalContact(
      drone_rental_id: String!
      phone: String
      location: String
    ): DroneRental!

    updateDroneRentalStatus(
      drone_rental_id: String!
      status: String!
    ): DroneRental!

    updateDronePaymentStatus(
      drone_rental_id: String!
      paymentStatus: String!
    ): DroneRental!

    deleteDroneRental(drone_rental_id: String!): DroneRental!
  }
`;
