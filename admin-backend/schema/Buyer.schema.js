import { gql } from "apollo-server-express";

export const buyerTypeDefs = gql`
  """ Buyer entity """
  type Buyer {
    buyerId: String
    name: String
    email: String
    token: String
  }

  extend type Query {
    """ Fetch all buyers """
    buyers: [Buyer]

    """ Fetch single buyer by ID """
    buyer(id: ID!): Buyer
  }

  extend type Mutation {
    """ Register a new buyer """
    signup(name: String!, email: String!, password: String!): Buyer

    """ Buyer login """
    login(email: String!, password: String!): Buyer

    """ Update buyer profile """
    updateBuyer(buyerId: String!, name: String, email: String, password: String): Buyer

    """ Delete buyer account """
    deleteBuyer(buyerId: String!): String
  }
`;
