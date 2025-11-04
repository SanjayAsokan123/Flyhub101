import { gql } from "apollo-server-express";

export const hirePilotTypeDefs = gql`
  """ Represents price structure of a pilot """
  type Price {
    perHour: Float
    perDay: Float
  }

  """ Certification document URL """
  type Certification {
    url: String!
  }

  """ File resource (e.g. resume) """
  type File {
    url: String!
  }

  """ Hire Pilot entity with linked seller info """
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
    email: String
    phoneNumber: String
    status: String
    seller: Seller
  }

  """ Input structure for pilot pricing """
  input PriceInput {
    perHour: Float
    perDay: Float
  }

  """ Input for uploading pilot certifications """
  input CertificationInput {
    url: String!
  }

  """ Input for resume or document """
  input FileInput {
    url: String!
  }

  """ Input for adding or updating pilot hire listing """
  input HirePilotInput {
    pilotName: String!
    pilotCompany: String!
    location: String
    email: String!
    phoneNumber: String!
    sellerId: ID!
    availability: Boolean
    specification: String
    price: PriceInput!
    certifications: [CertificationInput]
    resume: FileInput
    description: String
  }

  extend type Query {
    """ Fetch all hire pilot listings """
    hirePilots: [HirePilot]

    """ Fetch a specific pilot by ID """
    hirePilot(pilotId: String!): HirePilot

    """ Fetch pilots created by a specific seller """
    hirePilotsBySeller(sellerId: ID!): [HirePilot]

    """ Fetch all pilots with a given status (approved/pending/rejected) """
    hirePilotsByStatus(status: String!): [HirePilot]

    """ Seller-based filters """
    sellerapprovedHirePilots(sellerId: String!): [HirePilot!]
    sellerpendingHirePilots(sellerId: String!): [HirePilot!]
    sellerrejectedHirePilots(sellerId: String!): [HirePilot!]

    """ Buyer-based filters (optional, for future buyer logic) """
    buyerapprovedHirePilots(pilotId: String!): [HirePilot!]
    buyerpendingHirePilots(pilotId: String!): [HirePilot!]
    buyerrejectedHirePilots(pilotId: String!): [HirePilot!]
  }

  extend type Mutation {
    """ Add a new hire pilot listing """
    addHirePilot(input: HirePilotInput!): HirePilot

    """ Update hire pilot information """
    updateHirePilot(pilotId: String!, input: HirePilotInput!): HirePilot

    """ Approve / Reject pilot listing """
    updateHirePilotStatus(pilotId: String!, status: String!): HirePilot

    """ Delete a pilot listing """
    deleteHirePilot(pilotId: String!): HirePilot
  }
`;
