import { gql } from "apollo-server-express";

export const buyerTypeDefs = gql`
  scalar JSON

  type Buyer {
    id: ID
    buyerId: String
    firebaseUid: String
    name: String
    email: String
    phoneNumber: String
    token: String
    password: String
    createdAt: String
    updatedAt: String
    fcmTokens: [String!]
  }

  input BuyerInput {
    name: String
    email: String
    phoneNumber: String
    firebaseUid: String
    password: String
  }

  type UpdateTokenResponse {
    success: Boolean!
    message: String!
    buyer: Buyer
  }

  type BuyerNotification {
    notificationId: String!
    buyerId: String!
    title: String!
    message: String!
    type: String
    url: String
    data: JSON
    read: Boolean!
    createdAt: String!
  }

  type NotificationResponse {
    success: Boolean!
    message: String
  }

  type Query {
    buyers: [Buyer]
    buyer(buyerId: ID!): Buyer

    buyerNotifications(buyerId: String!): [BuyerNotification]

    buyerByEmail(
      email: String
      username: String
      phone: String
      buyerId: String
    ): Buyer

    getBuyerByLoginKey(key: String!): Buyer
  }

  type Mutation {
    createBuyer(input: BuyerInput!): Buyer!

     signupBuyer(
          name: String!
          email: String!
          phoneNumber: String!
          password: String!
          firebaseUid: String!
        ): Buyer

    loginBuyer(input: String!, password: String!): Buyer!

    loginBuyerGoogle(firebaseUid: String!, email: String!): Buyer!

    updateBuyer(buyerId: ID!, input: BuyerInput!): Buyer!

    deleteBuyer(buyerId: ID!): String

    markBuyerNotificationRead(notificationId: String!): NotificationResponse

    updateBuyerFcmToken(buyerId: String!, token: String!): UpdateTokenResponse

     testPush: BuyerNotification

  }

extend type Subscription {
  buyerNotificationAdded(buyerId: String!): BuyerNotification
}

`;
