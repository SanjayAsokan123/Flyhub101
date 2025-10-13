const { gql } = require('apollo-server-express');

const typeDefs = gql`
  type User {
    id: ID!
    name: String!
    email: String!
  }

  type Admin {
    id: ID!
    email: String!
  }

  type AuthPayload {
    token: String!
    admin: Admin!
  }

  type Query {
    hello: String
    users: [User!]!
    me: Admin
  }

  type Mutation {
    createUser(name: String!, email: String!, password: String!): User!
    adminLogin(email: String!, password: String!): AuthPayload!
  }
`;

module.exports = typeDefs;
