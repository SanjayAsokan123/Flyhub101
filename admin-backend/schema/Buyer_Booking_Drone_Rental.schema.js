import { gql } from "apollo-server-express";

const dronerentalBookingTypeDefs = gql`
  type RentalPeriod {
    startDate: String!
    endDate: String!
  }

  type DroneDetails {
    rentalId: String
    name: String
    brand: String
    location: String
    pricePerHour: Float
    pricePerDay: Float
    available: Boolean
  }

  type DroneRental {
    drone_rental_id: String!
    name: String!
    email: String!
    phone: String!
    location: String!
    amount: Float!
    status: String!
    rentalDate: String!
    rentalPeriod: RentalPeriod!
    paymentStatus: String!
    createdAt: String!
    updatedAt: String!
    drone: DroneDetails
  }

  input RentalPeriodInput {
    startDate: String!
    endDate: String!
  }

  extend type Query {
    getAllDroneRentals: [DroneRental!]!
    getDroneRentalById(drone_rental_id: String!): DroneRental
    getDroneRentalsByStatus(status: String!): [DroneRental!]!
    getDroneRentalsByPaymentStatus(paymentStatus: String!): [DroneRental!]!
    getPendingDroneRentals: [DroneRental!]!
    getConfirmedDroneRentals: [DroneRental!]!
    getCancelledDroneRentals: [DroneRental!]!
    getCompletedDronePaymentRentals: [DroneRental!]!
  }

  extend type Mutation {
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

    # ✅ Added contact update
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

export default dronerentalBookingTypeDefs;