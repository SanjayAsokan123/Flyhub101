import { gql } from "apollo-server-express";

export const accessoryTypeDefs = gql`
  """ Represents a user who added an accessory to wishlist """
  type WishlistUser {
    userId: ID!
    addedAt: String
  }

  """ Basic contact info of the accessory seller """
  type SellerInfo {
    email: String
    phoneNumber: String
  }

  """ Accessory entity with seller details """
  type Accessory {
    accessoryId: String
    name: String!
    brand: String!
    category: String
    price: Float!
    description: String!
    image: String
    quantity: Int
    status: String!
    wishlist: [WishlistUser]
    sellerId: String
    sellerInfo: SellerInfo
  }

  """ Input fields for creating/updating an accessory """
  input AccessoryInput {
    name: String!
    brand: String!
    category: String
    price: Float!
    description: String!
    image: String
    quantity: Int
    sellerId: String!
  }

  extend type Query {
    """ Fetch all accessories """
    accessories: [Accessory!]!

    """ Fetch one accessory by ID """
    accessory(accessoryId: String!): Accessory

    """ Fetch all rejected accessories (admin filter) """
    rejectedAccessories: [Accessory!]

    """ Fetch all approved accessories of a seller """
    approvedAccessories(sellerId: String!): [Accessory!]

    """ Fetch all pending accessories of a seller """
    pendingAccessories(sellerId: String!): [Accessory!]
  }

  extend type Mutation {
    """ Add a new accessory for approval """
    createAccessory(input: AccessoryInput!): Accessory

    """ Update an accessory details """
    updateAccessory(accessoryId: String!, input: AccessoryInput!): Accessory

    """ Approve / Reject accessory by admin """
    updateAccessoryStatus(accessoryId: String!, status: String!): Accessory

    """ Delete an accessory """
    deleteAccessory(accessoryId: String!): Accessory
  }
`;
