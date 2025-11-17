import { gql } from "apollo-server-express";

export const trainingTypeDefs = gql`
  """ Training program entity """
  type Training {
    id: ID!
    title: String!
    amount: Float!
    gst: Float!
    days: Int!
    totalAmount: Float!
    imagePath: String       # Firebase Storage URL
    shortDescription: String
    fullDescription: String
    createdAt: String
    updatedAt: String
  }

  """ Represents a student's enrollment in a training """
  type TrainingEnroll {
    id: ID!
    courseId: ID!
    courseTitle: String
    courseDays: Int
    totalAmount: Float
    name: String!
    email: String!
    phone: String!
    address: String!
    isTenthPass: Boolean
    isHaveLicence: Boolean
    isAbove18: Boolean
    status: String
    createdAt: String
    updatedAt: String
  }

  """ Input structure for training enrollment """
  input TrainingEnrollInput {
    courseId: ID!
    name: String!
    email: String!
    phone: String!
    address: String!
    isTenthPass: Boolean
    isHaveLicence: Boolean
    isAbove18: Boolean
  }

  # =======================
  # QUERIES
  # =======================
  type Query {
    getTrainings(search: String, sortOrder: String): [Training]
    getTrainingById(id: ID!): Training
    getEnrollments: [TrainingEnroll]
  }

  # =======================
  # MUTATIONS
  # =======================
  type Mutation {
    """ Add a new training program """
    addTraining(
      title: String!
      amount: Float!
      gst: Float!
      days: Int!
      imagePath: String         # Firebase URL
      shortDescription: String
      fullDescription: String
    ): Training

    """ Update existing training details """
    updateTraining(
      id: ID!
      title: String
      amount: Float
      gst: Float
      days: Int
      imagePath: String         # Firebase URL
      shortDescription: String
      fullDescription: String
    ): Training

    """ Delete a training by ID """
    deleteTraining(id: ID!): String

    """ Enroll a student in a training program """
    enrollTraining(input: TrainingEnrollInput!): TrainingEnroll
  }

  # =======================
  # SUBSCRIPTIONS (optional)
  # =======================
  type Subscription {
    trainingUpdated: TrainingNotification
  }

  """ Real-time training update type """
  type TrainingNotification {
    action: String!
    training: Training!
    timestamp: String!
  }
`;
