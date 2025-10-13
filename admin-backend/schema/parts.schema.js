import { gql } from "apollo-server-express";

export const partTypeDefs = gql`
  type Part {
    id: ID!
    name: String!
    brand: String!
    price: Float!
    description: String!
    image: String
    status: String!
  }

  input PartInput {
    name: String!
    brand: String!
    price: Float!
    description: String!
    image: String
  }

  type Query {
    parts: [Part]
    part(id: ID!): Part
    rejectedParts: [Part!]!
  }

type BulkApprovalResponse {
  success: Boolean!
  count: Int!
}

 type Mutation {
   createPart(input: PartInput!): Part
   updatePart(id: ID!, input: PartInput!): Part
   updatePartStatus(id: ID!, status: String!): Part
   deletePart(id: ID!): Part
   approveAllPendingParts: BulkApprovalResponse
  }
`;
