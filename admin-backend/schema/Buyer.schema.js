import { gql } from "apollo-server-express";

export const buyerTypeDefs = gql`
  """
  👤 Buyer Type
  Represents a FlyHub marketplace buyer.
  """
  type Buyer {
    id: ID
    buyerId: String
    name: String
    email: String
    phone: String
    token: String
  }

  # ============================================================
  # 📌 QUERIES
  # ============================================================
  type Query {
    """ Fetch all buyers (admin) """
    buyers: [Buyer]

    """ Fetch a single buyer by MongoDB ID """
    buyer(id: ID!): Buyer
  }

  # ============================================================
  # 📌 MUTATIONS
  # ============================================================
  type Mutation {
    """
    🟢 Buyer Signup
    Email + Password + Phone + OTP (Firebase)
    """
    signupBuyer(
      name: String!
      email: String!
      phone: String!
      password: String!
      firebaseUid: String!
    ): Buyer

    """
    🔵 Buyer Login
    Unified login using:
    - Email
    - Phone
    - BuyerID (FLYHUBB0001)
    """
    loginBuyer(
      input: String!
      password: String!
    ): Buyer

    """
    🔵 OTP Login (Firebase UID only)
    Used when buyer verifies OTP in mobile app
    """
    loginBuyerOtp(
      firebaseUid: String!
    ): Buyer

    """
    ✏️ Update Buyer Profile
    Optional fields
    """
    updateBuyer(
      buyerId: ID!
      name: String
      email: String
      phone: String
      password: String
    ): Buyer

    """
    🗑️ Delete Buyer Account
    Admin or self-delete
    """
    deleteBuyer(buyerId: ID!): String
  }
`;
